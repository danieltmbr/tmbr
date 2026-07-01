import Foundation
@preconcurrency import Markdown
import TmbrCore

/// Two-pass Markdown→HTML formatter that handles `^[content](cite: kind)` citation spans.
///
/// **Authoring syntax** — wrap only the citation text, not the surrounding quote:
/// ```markdown
/// > The mind wanders constantly.
/// > ^[Andy Puddicombe, [Headspace](https://headspace.com)](cite: podcast)
/// ```
///
/// **`CitationPlacement.endOfDocument`** (default):
/// - The cite span is replaced with `<sup class="reference-id"><a href="#reference-N">N</a></sup>`
///   (same CSS as the legacy hand-authored format, so the existing stylesheet applies).
/// - A `<section class="references">` is appended with `<li id="reference-N">` items.
///
/// **`CitationPlacement.inline`**: cite spans become `<span class="citation">content</span>`;
/// no relocation or references section.
///
/// Uses `CitationCollector` from `CoreTmbr` for sequential numbering so anchor IDs are
/// identical to those produced by the native `MarkdownFootnotes` pass.
public struct CitationMarkdownFormatter: Sendable {

    public let placement: CitationPlacement

    public init(placement: CitationPlacement = .endOfDocument) {
        self.placement = placement
    }

    public func format(_ markdown: String) -> String {
        let document = Document(parsing: markdown)

        // Phase 1: collect cite spans via AST walk (with source string for content extraction).
        let spans = CiteSpanCollector.collect(in: document, source: markdown)

        guard !spans.isEmpty else {
            var walker = HTMLFormatter()
            walker.visit(document)
            return walker.result
        }

        // Phase 2: assign sequential numbers via CitationCollector.
        var citationCollector = CitationCollector()
        let citations = spans.map { span in
            citationCollector.append(content: span.content, kind: span.kind)
        }

        // Phase 3: rewrite source and render.
        switch placement {
        case .endOfDocument:
            let rewritten = rewriteForEndOfDocument(markdown, spans: spans, citations: citations)
            var walker = HTMLFormatter()
            walker.visit(Document(parsing: rewritten))
            var html = walker.result
            html += referencesHTML(citations: citationCollector.references)
            return html

        case .inline:
            let rewritten = rewriteForInline(markdown, spans: spans)
            var walker = HTMLFormatter()
            walker.visit(Document(parsing: rewritten))
            return walker.result
        }
    }
}

// MARK: - Source rewriting

private extension CitationMarkdownFormatter {

    /// Replaces each cite span with a sup-marker InlineAttributes node (same format as the
    /// legacy hand-authored markup so existing CSS classes apply unchanged). Processes in
    /// reverse document order so earlier source positions stay valid after each replacement.
    func rewriteForEndOfDocument(
        _ source: String,
        spans: [CiteSpanCollector.Span],
        citations: [Citation]
    ) -> String {
        var result = source
        for (span, citation) in zip(spans, citations).reversed() {
            guard let range = sourceRange(of: span.sourceRange, in: result) else { continue }
            let marker = "^[[\(citation.number)](#\(citation.anchorID))](class: reference-id, htmltag: sup)"
            result.replaceSubrange(range, with: marker)
        }
        return result
    }

    /// Replaces each cite span with a `class: citation`-attributed version so the content
    /// is preserved inline and CSS can style it as an attribution.
    func rewriteForInline(_ source: String, spans: [CiteSpanCollector.Span]) -> String {
        var result = source
        for span in spans.reversed() {
            guard let range = sourceRange(of: span.sourceRange, in: result) else { continue }
            result.replaceSubrange(range, with: "^[\(span.content)](class: citation)")
        }
        return result
    }

    func referencesHTML(citations: [Citation]) -> String {
        guard !citations.isEmpty else { return "" }
        var html = "\n<section class=\"references\"><ol>"
        for citation in citations {
            html += "<li id=\"\(citation.anchorID)\">\(inlineHTML(citation.content))</li>"
        }
        html += "</ol></section>"
        return html
    }

    /// Renders raw markdown as HTML inline — strips the outer `<p>…</p>` so it embeds
    /// cleanly inside block elements like `<li>`.
    func inlineHTML(_ markdown: String) -> String {
        var walker = HTMLFormatter()
        walker.visit(Document(parsing: markdown))
        return walker.result
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>", with: "")
    }
}

// MARK: - SourceRange → String.Index

/// Converts a swift-markdown `SourceRange` (1-based line/column) to `Range<String.Index>`.
/// Returns `nil` if either bound can't be found in the given source string.
private func sourceRange(of range: SourceRange, in source: String) -> Range<String.Index>? {
    var line = 1, col = 1
    var lower: String.Index?
    var upper: String.Index?
    var idx = source.startIndex

    while idx < source.endIndex {
        if lower == nil,
           line == range.lowerBound.line,
           col == range.lowerBound.column {
            lower = idx
        }
        if lower != nil,
           line == range.upperBound.line,
           col == range.upperBound.column {
            upper = idx
            break
        }
        if source[idx].isNewline { line += 1; col = 1 } else { col += 1 }
        source.formIndex(after: &idx)
    }
    // The upper bound may land exactly at endIndex, which the loop exits before checking.
    if upper == nil, lower != nil,
       line == range.upperBound.line,
       col == range.upperBound.column {
        upper = idx
    }

    guard let lo = lower, let hi = upper else { return nil }
    return lo..<hi
}

// MARK: - Cite span collector

/// AST walker that collects all `InlineAttributes` nodes whose attributes contain a `cite:` key.
/// Takes the original source string so it can extract the raw markdown content of each span.
private struct CiteSpanCollector: MarkupWalker {

    struct Span {
        let sourceRange: SourceRange
        let content: String   // raw markdown text of the cite span (e.g. "Andy, [Headspace](url)")
        let kind: String?     // the `cite:` attribute value (the category/kind, e.g. "podcast")
    }

    private let source: String
    private(set) var spans: [Span] = []

    private init(source: String) {
        self.source = source
    }

    static func collect(in document: Document, source: String) -> [Span] {
        var collector = CiteSpanCollector(source: source)
        collector.visit(document)
        return collector.spans
    }

    // MARK: MarkupWalker

    mutating func visitInlineAttributes(_ node: InlineAttributes) {
        guard let kind = citeKind(from: node.attributes),
              let range = node.range else {
            descendInto(node)
            return
        }

        let content = extractContent(from: range)
        spans.append(Span(
            sourceRange: range,
            content: content,
            kind: kind.isEmpty ? nil : kind
        ))
        // Do NOT descend — the whole span is consumed.
    }

    // MARK: Attribute parsing

    /// Returns the value of the `cite:` key from an InlineAttributes attribute string,
    /// or `nil` if the key is absent.
    ///
    /// Handles unquoted word values (`cite: podcast`) using the same regex approach
    /// as the fork's `InlineAttributeParser.toJSON5`. Quoted values with spaces
    /// (`cite: "my source"`) are handled by a second pass.
    private func citeKind(from attributes: String) -> String? {
        // First try unquoted: cite: word
        if let m = attributes.range(of: #"\bcite\s*:\s*([A-Za-z0-9_-]+)"#, options: .regularExpression) {
            let after = attributes[m].drop(while: { !":".contains($0) }).dropFirst()
                .drop(while: { $0.isWhitespace })
            return String(after)
        }
        // Then try quoted: cite: "value"
        if let m = attributes.range(of: #"\bcite\s*:\s*"([^"]+)""#, options: .regularExpression) {
            // Extract just the quoted content
            let segment = String(attributes[m])
            if let open = segment.firstIndex(of: "\""),
               let close = segment.lastIndex(of: "\""),
               open != close {
                return String(segment[segment.index(after: open)..<close])
            }
        }
        return nil
    }

    // MARK: Content extraction

    /// Extracts the raw markdown source text of the citation content (the text inside `^[…]`)
    /// by scanning the source string with balanced-bracket counting.
    private func extractContent(from nodeRange: SourceRange) -> String {
        guard let fullRange = sourceRange(of: nodeRange, in: source) else { return "" }
        let spanText = source[fullRange]

        // Expect "^[" at start
        guard spanText.hasPrefix("^[") else { return "" }

        var idx = spanText.index(spanText.startIndex, offsetBy: 2)  // after "^["
        let contentStart = idx
        var depth = 1

        while idx < spanText.endIndex, depth > 0 {
            switch spanText[idx] {
            case "[": depth += 1
            case "]": depth -= 1
            default: break
            }
            if depth > 0 { spanText.formIndex(after: &idx) }
        }

        guard depth == 0 else { return "" }
        return String(spanText[contentStart..<idx])
    }
}
