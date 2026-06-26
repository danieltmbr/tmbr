import Foundation
import CoreTmbr

/// Walks a parsed `AttributedString` and processes citation spans marked with `CiteAttribute`.
///
/// Each contiguous run carrying `CiteAttribute` is a standalone citation:
/// ```markdown
/// ^[Andy Puddicombe, [Headspace](https://headspace.com)](cite: podcast)
/// ```
/// The span text is the citation content (already parsed as rich attributed runs by Foundation).
/// The `cite` value is the optional kind/category.
///
/// After collection the function transforms the string according to `CitationPlacement`:
///
/// - `.endOfDocument`: replaces every cite span with a `FootnoteMarkerAttribute` run linked to
///   `Citation.anchorID(...)`, and returns the collected `[Citation]` for the caller to append
///   as a trailing references section.
/// - `.inline`: leaves cite spans in place (the `MarkdownDecorator.citation` factory styles
///   them as an attribution); returns an empty `references` array.
///
/// No HTML tags, CSS classes, or anchor pairs are ever emitted natively.
struct MarkdownFootnotes {

    // MARK: - Result

    struct Result {
        /// The body string with cite spans replaced (`.endOfDocument`) or left in place (`.inline`).
        var body: AttributedString
        /// Citations in document order. Empty when placement is `.inline`.
        var references: [Citation]
    }

    // MARK: - Processing

    static func process(
        _ attributed: AttributedString,
        placement: CitationPlacement
    ) -> Result {
        var collector = CitationCollector()
        var body = attributed

        // Collect cite spans and record their ranges (in reverse so index arithmetic is stable
        // when we mutate the string — removing/replacing from the end does not shift earlier indices).
        let citeRanges = collectCiteRanges(in: body)

        for (range, kind) in citeRanges.reversed() {
            let content = rawMarkdown(from: body[range])
            let citation = collector.append(content: content, kind: kind)

            switch placement {
            case .endOfDocument:
                // Replace the cite span with a single marker character attributed with
                // FootnoteMarkerAttribute + a link to the citation's anchor.
                var marker = AttributedString("\(citation.number)")
                marker[marker.startIndex..<marker.endIndex][FootnoteMarkerAttribute.self] = citation.number
                marker[marker.startIndex..<marker.endIndex].link = URL(string: "#\(citation.anchorID)")
                body.replaceSubrange(range, with: marker)

            case .inline:
                // Leave the cite span in place; the decorator styles it.
                // We still collect so the caller can number consistently (if mixed placements arise).
                break
            }
        }

        return Result(
            body: body,
            references: collector.references
        )
    }

    // MARK: - Helpers

    /// Returns all contiguous cite-attributed ranges in **forward document order**, paired with
    /// the `cite` attribute value (the kind). Adjacent runs with the same `cite` value that form
    /// one logical span are merged.
    private static func collectCiteRanges(
        in attributed: AttributedString
    ) -> [(range: Range<AttributedString.Index>, kind: String)] {
        var result: [(range: Range<AttributedString.Index>, kind: String)] = []

        var spanStart: AttributedString.Index?
        var spanEnd: AttributedString.Index?
        var spanKind: String?

        for run in attributed.runs {
            guard let kind = run[CiteAttribute.self] else {
                // Flush any open span
                if let start = spanStart, let end = spanEnd, let k = spanKind {
                    result.append((start..<end, k))
                    spanStart = nil; spanEnd = nil; spanKind = nil
                }
                continue
            }

            if spanStart == nil {
                spanStart = run.range.lowerBound
            }
            spanEnd = run.range.upperBound
            spanKind = kind
        }

        // Flush final span
        if let start = spanStart, let end = spanEnd, let k = spanKind {
            result.append((start..<end, k))
        }

        return result
    }

    /// Extracts a minimal raw markdown string from an `AttributedSubstring` by converting
    /// the attributed content back to its plaintext + inline-formatting approximation.
    /// Used to store citation content in `Citation.content` so it can be re-parsed per-surface.
    ///
    /// Handles: plain text, bold, italic, links. Block presentation is not expected inside a
    /// cite span, so `presentationIntent` is ignored.
    private static func rawMarkdown(from slice: AttributedSubstring) -> String {
        var result = ""
        for run in slice.runs {
            var text = String(slice[run.range].characters)

            // Reconstruct link markdown: [text](url)
            if let url = run.link {
                text = "[\(text)](\(url.absoluteString))"
            }

            // Reconstruct bold/italic from inlinePresentationIntent
            if let intent = run.inlinePresentationIntent {
                if intent.contains(.stronglyEmphasized) { text = "**\(text)**" }
                else if intent.contains(.emphasized) { text = "*\(text)*" }
            }

            result += text
        }
        return result
    }
}
