import SwiftUI

extension View {
    func blog(_ model: BlogModel) -> some View {
        environment(model)
            .environment(\.syncBlog, SyncBlogAction(model: model))
    }
}
