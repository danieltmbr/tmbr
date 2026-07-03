# Incident: Quotes category filter drops blog-post-sourced quotes when any category is selected

**Date**: 2026-07-03
**Severity**: Medium
**Status**: Resolved

## What happened

On the Quotes tab, tapping "Select All" in the category filter produced a shorter list than
"Deselect All". Post-sourced quotes (originating from blog posts, not catalogue notes) disappeared
as soon as any category bucket was selected, and reappeared when the filter was cleared entirely.

## Root cause

`QuoteRecord.sourceType` is `nil` for blog-post-sourced quotes — only note-sourced quotes carry a
catalogue category slug. The predicate in `QuotesTab.swift` was:

```swift
result = result.filter { $0.sourceType.map(selectedCategorySlugs.contains) ?? false }
```

`Optional.map` on a `nil` sourceType returns `nil`; `?? false` then excludes the quote. So with any
non-empty selection the post quotes vanished, but an empty selection skipped the block entirely and
showed them — producing the observable asymmetry.

The deeper structural issue was that the Quotes tab was reusing the Catalogue tab's
`selectedCategorySlugs` set (from `CatalogueModel`) and `CatalogueFilterView`, whose category
universe covers only catalogue items. Post-sourced quotes are outside that universe entirely, so
they had no representable bucket in the filter.

## How it was fixed

Introduced a dedicated `QuotesModel` (own model/wrapper/action/env/injection quintet, decoupled
from `CatalogueModel`) with a unified `selectedSources: Set<String>` that covers **source buckets**:
catalogue category slugs **plus** a `blogPosts` sentinel (`"__blog_posts__"`) for post-sourced
quotes. A quote's bucket is `quote.sourceType ?? QuotesModel.blogPosts` — never `nil`, no
special-casing needed.

The predicate became:

```swift
if !selectedSources.isEmpty {
    result = result.filter { selectedSources.contains($0.sourceType ?? QuotesModel.blogPosts) }
}
```

`QuotesFilterView` replaces `CatalogueFilterView` on the Quotes tab. It shows a "Sources" section
(`QuoteSourcesSection`) listing all catalogue categories plus a "Blog posts" row, giving users
explicit control over post-sourced quotes. The Catalogue tab's filter is now fully independent.

## Prevention

- [ ] New test: whenever a nullable dimension is used as a filter key, verify that `nil`-valued
  records are **not** excluded by a "select all" action — i.e. selecting every known value should
  produce the same set as no selection.
- [ ] Pattern to follow: a nullable filter key needs a sentinel / safe-default bucket rather than
  `?? false`. Use `guard let x = record.x else { return true }` (unknown = always visible) for
  single-valued optional fields, or `??  Sentinel.value` (unknown maps to a named bucket) when
  the UI needs to let users explicitly toggle the unknown group.

## Tests added

No automated test added yet (the Quotes tab is a SwiftUI `@Query` view; integration tests require
a running SwiftData container). The fix should be exercised manually per the Verification checklist
in the plan:
- Select All → Deselect All → list is identical.
- Select only one category → post quotes still show; correct category-notes show; others hidden.
