import Foundation
import TmbrCore

/// Rewrites raw Markdown source to process `^[content](cite: kind)` citation spans
/// before the string is handed to Foundation's `AttributedString` parser.
///
/// Foundation does not apply custom inline attributes to runs inside blockquotes, so
/// scanning `AttributedString` runs for `CiteAttribute` is unreliable. This pass operates
/// on the raw source string instead — identical in approach to `CitationMarkdownFormatter`
/// on the web side.
///
/// For `.endOfDocument`, each cite span is replaced with a standard markdown link:
/// `[N](#tmbr-footnote-N)`. After `AttributedString` parsing, `ParseResult` converts
/// those placeholder links into `FootnoteMarkerAttribute` runs (see `MarkdownView`).
///
/// For `.inline`, each cite span is replaced with its raw content text so it renders
/// inline alongside the surrounding prose.
struct MarkdownFootnotes {

    // MARK: - Result

    struct Result {
        /// Raw markdown with cite spans rewritten for the chosen placement.
        let processed: String
        /// Citations in document order. Empty when placement is `.inline`.
        let references: [Citation]
    }

    // MARK: - Processing

    static func process(_ raw: String, placement: CitationPlacement) -> Result {
        let spans = collectSpans(in: raw)
        guard !spans.isEmpty else { return Result(processed: raw, references: []) }

        var collector = CitationCollector()
        var result = raw

        // Reverse order so earlier source positions stay valid after each replacement.
        for span in spans.reversed() {
            let citation = collector.append(content: span.content, kind: span.kind)
            let replacement: String
            switch placement {
            case .endOfDocument:
                // Standard markdown link with a private URL scheme — no web attributes.
                // ParseResult converts this to FootnoteMarkerAttribute after parsing.
                replacement = "[\(citation.number)](#tmbr-footnote-\(citation.number))"
            case .inline:
                replacement = span.content
            }
            result.replaceSubrange(span.sourceRange, with: replacement)
        }

        return Result(
            processed: result,
            references: placement == .endOfDocument ? collector.references : []
        )
    }

    // MARK: - Span collection

    private struct Span {
        let sourceRange: Range<String.Index>
        let content: String
        let kind: String?
    }

    /// Scans the raw markdown string for `^[content](cite: kind)` patterns in document order.
    /// Bracket-counting handles nested `[…]` inside the content (e.g. inline links).
    private static func collectSpans(in source: String) -> [Span] {
        var spans: [Span] = []
        var idx = source.startIndex

        while idx < source.endIndex {
            guard source[idx] == "^" else { source.formIndex(after: &idx); continue }
            let spanStart = idx
            source.formIndex(after: &idx)
            guard idx < source.endIndex, source[idx] == "[" else { continue }
            source.formIndex(after: &idx)

            // Scan content with balanced bracket counting.
            let contentStart = idx
            var depth = 1
            while idx < source.endIndex, depth > 0 {
                switch source[idx] {
                case "[": depth += 1
                case "]": depth -= 1
                default: break
                }
                if depth > 0 { source.formIndex(after: &idx) }
            }
            guard depth == 0 else { break }
            let content = String(source[contentStart..<idx])
            source.formIndex(after: &idx)  // past ']'

            guard idx < source.endIndex, source[idx] == "(" else { continue }
            source.formIndex(after: &idx)  // past '('

            let attrStart = idx
            while idx < source.endIndex, source[idx] != ")" { source.formIndex(after: &idx) }
            guard idx < source.endIndex else { break }
            let attributes = String(source[attrStart..<idx])
            source.formIndex(after: &idx)  // past ')'

            guard let kind = citeKind(from: attributes) else { continue }
            spans.append(Span(sourceRange: spanStart..<idx, content: content, kind: kind))
        }

        return spans
    }

    private static func citeKind(from attributes: String) -> String? {
        // Unquoted: cite: word
        if let m = attributes.range(of: #"\bcite\s*:\s*([A-Za-z0-9_-]+)"#, options: .regularExpression) {
            let value = String(
                attributes[m]
                    .drop(while: { $0 != ":" }).dropFirst()
                    .drop(while: { $0.isWhitespace })
            )
            return value.isEmpty ? nil : value
        }
        // Quoted: cite: "value with spaces"
        if let m = attributes.range(of: #"\bcite\s*:\s*"([^"]+)""#, options: .regularExpression) {
            let segment = String(attributes[m])
            if let open = segment.firstIndex(of: "\""),
               let close = segment.lastIndex(of: "\""),
               open != close {
                return String(segment[segment.index(after: open)..<close])
            }
        }
        return nil
    }
}
