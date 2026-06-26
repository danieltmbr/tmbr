import Foundation
@preconcurrency import Markdown
import CoreTmbr

public struct MarkdownFormatter: Sendable {
    typealias Formatter = @Sendable (String) -> String

    private let formatter: Formatter

    init(formatter: @escaping Formatter) {
        self.formatter = formatter
    }

    public func format(_ markdown: String) -> String {
        formatter(markdown)
    }

    /// Renders markdown to HTML with no citation processing.
    /// Use `html(citationPlacement:)` when the content may contain `^[…](cite:…)` spans.
    public static let html = MarkdownFormatter { markdown in
        var walker = HTMLFormatter()
        walker.visit(Document(parsing: markdown))
        return walker.result
    }

    /// Renders markdown to HTML with citation processing:
    /// `^[content](cite: kind)` spans are collected, numbered, and rendered according to
    /// `CitationPlacement`. Use this for post bodies and notes that may contain citations.
    public static func html(citationPlacement: CitationPlacement = .endOfDocument) -> MarkdownFormatter {
        let formatter = CitationMarkdownFormatter(placement: citationPlacement)
        return MarkdownFormatter { markdown in formatter.format(markdown) }
    }
}
