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

    /// Renders markdown to HTML with citation processing (`.endOfDocument` by default).
    /// `^[content](cite: kind)` spans are collected, numbered, and relocated to a references
    /// section; no-op when the content contains no citations.
    public static let html: MarkdownFormatter = {
        let formatter = CitationMarkdownFormatter(placement: .endOfDocument)
        return MarkdownFormatter { markdown in formatter.format(markdown) }
    }()
}
