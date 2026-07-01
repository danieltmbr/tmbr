import Foundation
@preconcurrency import Markdown
import TmbrCore

public struct MarkdownFormatter: Sendable {
    typealias Formatter = @Sendable (String) -> String

    private let formatter: Formatter

    init(formatter: @escaping Formatter) {
        self.formatter = formatter
    }

    public func format(_ markdown: String) -> String {
        formatter(markdown)
    }

    /// Renders markdown to HTML with citations relocated to a numbered references section.
    public static let html: MarkdownFormatter = {
        Self.html(citationPlacement: .endOfDocument)
    }()

    /// Renders markdown to HTML with the given citation placement.
    public static func html(citationPlacement: CitationPlacement) -> MarkdownFormatter {
        let formatter = CitationMarkdownFormatter(placement: citationPlacement)
        return MarkdownFormatter { markdown in formatter.format(markdown) }
    }
}
