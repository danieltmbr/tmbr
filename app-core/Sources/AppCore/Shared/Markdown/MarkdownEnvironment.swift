import SwiftUI
import TmbrCore

public extension EnvironmentValues {
    /// The decorator applied to each run of `AttributedString` in `MarkdownView`.
    /// Override per surface (e.g. posts vs notes) with `.markdownDecorator(_:)`.
    @Entry var markdownDecorator: MarkdownDecorator = .standard

    /// Where citations are rendered relative to the prose that cites them.
    /// `.endOfDocument` (default) extracts citations into a numbered references section at
    /// the bottom with a superscript marker in place. `.inline` keeps them as an attribution
    /// styled near their quote, with no relocation.
    @Entry var citationPlacement: CitationPlacement = .endOfDocument
}

public extension View {
    /// Injects a custom `MarkdownDecorator` for all `MarkdownView` instances in this subtree.
    func markdownDecorator(_ decorator: MarkdownDecorator) -> some View {
        environment(\.markdownDecorator, decorator)
    }

    /// Injects a `CitationPlacement` policy for all `MarkdownView` instances in this subtree.
    func citationPlacement(_ placement: CitationPlacement) -> some View {
        environment(\.citationPlacement, placement)
    }
}
