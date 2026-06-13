import SwiftUI

extension View {
    func blog(_ model: BlogModel) -> some View {
        environment(model)
            .environment(\.syncBlog, SyncBlogAction(model: model))
            .environment(\.createPost, CreatePostAction(syncEngine: model.syncEngine))
            .environment(\.updatePost, UpdatePostAction(syncEngine: model.syncEngine))
            .environment(\.deletePost, DeletePostAction(syncEngine: model.syncEngine))
            .environment(\.loadMorePosts, LoadMorePostsAction(model: model))
    }
}
