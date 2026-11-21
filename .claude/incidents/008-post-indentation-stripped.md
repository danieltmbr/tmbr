# Incident: Leading whitespace in poems stripped despite `white-space: pre-wrap`

**Date**: 2026-11-20
**Severity**: Low
**Status**: Resolved

## What happened

v2.6.0 shipped a one-line CSS change (`main article p { white-space: pre-wrap }`) so that
posts written as poems or lyrics would keep their spacing and line breaks. After deploy,
interior runs of spaces and line breaks rendered correctly, but every line still started
flush left. Lines the author had indented by 2–14 spaces (e.g. `              a Dragons
Trail-en.`) lost that indentation. The database content was correct.

The native app had a related, pre-existing gap: Foundation's `AttributedString(markdown:)`
with `.full` syntax collapses a soft line break to a single space, so the same poems ran
together into one line there.

## Root cause

CSS cannot show whitespace that is not in the HTML. CommonMark strips the leading and
trailing whitespace of every line in a paragraph when it builds `Text` nodes, and
swift-markdown reports those stripped nodes as starting at column 1, so by the time
`HTMLFormatter.visitText` runs, the indentation is gone and unrecoverable from the AST.
The CSS change was verified against interior spacing only, which does survive parsing.

## How it was fixed

A source-level rewriter, `MarkdownWhitespace` in `tmbr-core`, runs before either parser:

- `.indentation` swaps leading spaces/tabs on paragraph lines for no-break spaces (U+00A0),
  which CommonMark does not strip. Code blocks, lists, headings, thematic breaks, HTML
  blocks and setext underlines are detected line by line and left alone; block quote
  markers are skipped and preserved.
- `.lineBreaks` appends a backslash to a paragraph line when the next line continues the
  same paragraph, promoting the soft break to a hard one.

The web (`CitationMarkdownFormatter`) applies `.indentation` only, since `pre-wrap` already
shows the newline emitted for a soft break. The native app (`MarkdownView.ParseResult`)
applies both, so posts take the same shape on every platform.

An AST-rewriter approach (recovering indentation from source lines inside a
`MarkupRewriter`) was built first and discarded: it could never run in the app, which has no
AST hook, so the app would have needed a source-level pass anyway.

## Prevention

- [x] New test: `tmbr-core` now has a test target; `MarkdownWhitespaceTests` covers
      indentation, line breaks, and every block type that must be left alone.
- [x] New test: `MarkdownFormatterWhitespaceTests` in `web-core` asserts the rendered HTML
      for the exact stanza from the report, including the citation pass.
- [ ] Process/doc change: when a change is meant to affect rendering of authored text,
      verify against the real content shape (here: a poem with leading indentation), not a
      synthetic sample.
- [ ] Long-term: `CitationMarkdownFormatter.sourceRange(of:in:)` counts `Character`s while
      swift-markdown reports columns in UTF-8 bytes. Any non-ASCII character (Hungarian
      accents, em dashes, and now no-break spaces) earlier on the same line as a cite span
      shifts the lookup. Cite spans are conventionally on their own line, so this has not
      bitten yet, but it should count bytes.

## Tests added

- `tmbr-core/Tests/TmbrCoreTests/MarkdownWhitespaceTests.swift`
- `web-core/Tests/CoreWebTests/Markdown/MarkdownFormatterWhitespaceTests.swift`
