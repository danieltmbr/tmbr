# Incident: Multi-line quotes rendered as a single line

**Date**: 2026-07-01
**Severity**: Medium
**Status**: Resolved

## What happened

After deploying the quotes feature, multi-line blockquotes were displayed as a single
unbroken line on the web. Two distinct failure modes were visible:

1. **Paragraphs joined without any separator** — blockquotes authored with a blank `>`
   line between stanzas (e.g. Hungarian lyrics written as separate paragraphs) had
   all text concatenated with *no space or newline*, producing garbled output like
   `"...hangerőMelletted..."`.

2. **Lines joined with a space** — blockquotes with consecutive `>` lines
   (no blank line) appeared as one line in the browser, with a space between what
   should have been separate lines.

## Root cause

Both bugs were in `QuoteExtractor` (`web-core/Sources/WebCore/Markdown/QuoteExtractor.swift`),
the single walker that materialises `Quote.body` for both the seed migration and the
note/post model middlewares. The extracted body is stored in the DB and later
*re-parsed* to produce the HTML displayed on the quote page.

**Bug 1 — missing `visitParagraph` handler.**  
In swift-markdown's AST, a blank `>` line inside a blockquote splits the content into
multiple `Paragraph` nodes. The walker had no `visitParagraph` override, so
`defaultVisit` silently descended into each paragraph without inserting any separator
between them — adjacent paragraphs were concatenated directly.

**Bug 2 — SoftBreak stored as plain `\n`, collapsed by the browser.**  
The walker emitted `\n` for both `SoftBreak` and `LineBreak` inline nodes. When the
stored body was re-parsed with `Document(parsing:)` for HTML rendering, a lone `\n`
within a paragraph became a `SoftBreak` node again. swift-markdown's `HTMLFormatter`
renders `SoftBreak` as a literal `\n` (per CommonMark semantics), which HTML
browsers collapse to a space — so the quote appeared on one line.

`HTMLFormatterOptions` has no option to promote soft breaks to `<br />`, so the fix
had to change what was *stored*, not the renderer.

## How it was fixed

**`QuoteExtractor` changes:**

- Added `visitParagraph`: when inside a blockquote, inserts `"\n\n"` before
  descending if `currentQuote` is non-empty. This restores paragraph boundaries and,
  on re-parse, produces distinct `<p>` blocks — faithfully reproducing the
  author's blank-line paragraph gaps.
- Changed `visitSoftBreak` and `visitLineBreak` to append `"\\\n"` (CommonMark hard
  break syntax: backslash + newline) instead of `"\n"`. On re-parse this becomes a
  `LineBreak` node, which `HTMLFormatter` emits as `<br />`.

**Backfill migration (`RepairQuoteLineBreaks`):**

Added to `tmbr-web/Sources/App/Modules/Notes/Models/Migrations/` and registered
after `SeedQuotesWithMarkdown()` in `Notes.swift`. It re-extracts every note/post
quote with the fixed extractor and applies `QuoteReconciler.plan` to update only
the changed rows, preserving quote UUIDs so existing `/quotes/<id>` permalinks
remain valid.

## Prevention

- [x] New test: **`multiParagraphQuote`** in `QuoteExtractorTests` — asserts that a
      blockquote with blank `>` lines produces paragraph-separated body text
      (`"\n\n"` between stanzas). This was the entirely untested path.
- [x] New test: **`QuoteHTMLRenderingTests`** (round-trip suite) — feeds a stored
      `Quote.body` through `MarkdownFormatter.html(citationPlacement: .inline)` and
      asserts the HTML contains `<br />` for tight lines and multiple `<p>` for
      multi-paragraph quotes. These tests would have caught both bugs before ship.
- [x] Updated existing tests to reflect the new hard-break format (`\\\n`).
- [ ] Consider whether the `web-core` tests can be run from the CLI (`swift test`)
      in addition to Xcode; the test plan gap meant CI could not catch this.

## Tests added

- `web-core/Tests/CoreWebTests/Markdown/QuoteExtractorTests.swift`
  — `multiParagraphQuote()` (new)
  — `QuoteHTMLRenderingTests` suite: `consecutiveLinesRenderWithBreak`,
    `multiparagraphRendersAsMultipleParagraphs`, `extractionRoundTrip`,
    `multiParagraphExtractionRoundTrip` (all new)
  — updated `singleQuoteBlock` and `multipleQuoteBlocks` expectations for `\\\n`
