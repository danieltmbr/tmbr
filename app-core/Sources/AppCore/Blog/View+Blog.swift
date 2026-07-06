import SwiftUI

public extension View {
    /// Injects the Blog model + its refresh and search actions for the tab subtree.
    func blog(_ model: BlogModel) -> some View {
        environment(model)
            .environment(\.refreshBlog, BlogRefreshAction(model: model))
            .environment(\.loadBlog, BlogPageLoadAction(model: model))
            .environment(\.searchBlog, BlogSearchAction(model: model))
    }
}
