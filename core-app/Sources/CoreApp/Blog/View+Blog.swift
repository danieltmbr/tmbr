import SwiftUI

public extension View {
    /// Injects the Blog model + its refresh action (the seam) for the tab subtree.
    func blog(_ model: BlogModel) -> some View {
        environment(model)
            .environment(\.refreshBlog, RefreshBlogAction(model: model))
    }
}
