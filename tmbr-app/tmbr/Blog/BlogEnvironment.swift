import SwiftUI

extension EnvironmentValues {
    @Entry var syncBlog: SyncBlogAction = SyncBlogAction()
    @Entry var createPost: CreatePostAction = CreatePostAction()
    @Entry var updatePost: UpdatePostAction = UpdatePostAction()
    @Entry var deletePost: DeletePostAction = DeletePostAction()
    @Entry var loadMorePosts: LoadMorePostsAction = LoadMorePostsAction()
}
