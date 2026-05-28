# Incident: Note textarea access checkbox renders out-of-bounds

**Date**: 2026-05-27
**Severity**: Medium
**Status**: Partially mitigated (workaround in place, no permanent fix)

## What happened

When a note textarea section is included on a new page, the access checkbox (public/private toggle) renders outside the form bounds or in the wrong position, making it non-functional or visually broken.

## Root cause

Leaf's template system lacks true component inheritance or scoped slot injection. The note textarea template must be injected in a very specific way to produce the correct DOM structure — specifically, the access checkbox depends on sibling relationship with the textarea that Leaf's `#import`/`#export` mechanism does not reliably maintain across different parent templates.

When the template is reused on a new page by a different parent template, the parent's `#export` block silently overwrites the child's, producing malformed HTML where the checkbox floats outside its container.

## How it was fixed

Not properly fixed. A reminder was added to CLAUDE.md noting the exact inclusion pattern required. Every new page that adds a note section must follow this pattern manually.

## Prevention

- [ ] **Long-term fix**: Replace Leaf with a Swift templating library that supports proper component scoping (e.g., `swift-html` or a structured macro system). See `leaf-limitations.md` for known Leaf issues.
- [x] **E2E test**: `catalogue-editor.spec.ts` — "note access checkbox: visible, inside notes section, and interactive". Verifies (a) visible, (b) inside `#notes-section` bounds, (c) toggleable. Run for `/albums/new`; extend to other note-bearing pages as they're added.
- [ ] **Process**: Any PR that adds a note section to a new page must include a screenshot or Playwright test verifying correct layout.

## Tests added

`tmbr-web/Tests/E2E/catalogue-editor.spec.ts` — "note access checkbox: visible, inside notes section, and interactive"
