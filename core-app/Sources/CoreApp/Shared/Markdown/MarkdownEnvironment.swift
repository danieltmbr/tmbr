import SwiftUI

public extension EnvironmentValues {
    /// The decorator applied to each run of `AttributedString` in `MarkdownView`.
    /// Override per surface (e.g. posts vs notes) with `.markdownDecorator(_:)`.
    @Entry var markdownDecorator: MarkdownDecorator = .standard
}

public extension View {
    /// Injects a custom `MarkdownDecorator` for all `MarkdownView` instances in this subtree.
    func markdownDecorator(_ decorator: MarkdownDecorator) -> some View {
        environment(\.markdownDecorator, decorator)
    }
}
