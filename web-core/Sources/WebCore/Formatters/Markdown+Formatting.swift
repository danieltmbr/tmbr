import Foundation
@preconcurrency import Markdown
import TmbrCore

public struct MarkdownFormatter: Sendable {

    private let citationFormatter: CitationMarkdownFormatter

    public init(placement: CitationPlacement = .endOfDocument) {
        citationFormatter = CitationMarkdownFormatter(placement: placement)
    }

    public func format(_ markdown: String) -> String {
        citationFormatter.format(markdown)
    }

    /// Standard note/post renderer — citations become numbered footnotes at end of document.
    public static let html = MarkdownFormatter(placement: .endOfDocument)

    /// Quote body renderer — citations stay inline as `<span class="citation">`.
    public static let quoteBody = MarkdownFormatter(placement: .inline)
}
