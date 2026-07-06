import SwiftUI

public extension View {
    /// Injects the Quotes model + its source-selection and search actions for the tab subtree.
    ///
    /// Call this once at the composition root alongside `.blog(_:)` and `.catalogue(_:)`:
    ///
    ///     ContentView()
    ///         .blog(blog)
    ///         .catalogue(catalogue)
    ///         .quotes(quotes)
    func quotes(_ model: QuotesModel) -> some View {
        environment(model)
            .environment(\.selectQuoteSources, SelectQuoteSourcesAction(model: model))
            .environment(\.searchQuotes, QuotesSearchAction(model: model))
    }
}
