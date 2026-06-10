import Foundation
import Core
import TmbrCore

extension Commands {
    var posts: Commands.Posts.Type { Commands.Posts.self }
}

extension Commands {
    struct Posts: CommandCollection, Sendable {
                
        let create: CommandFactory<PostPayload, Post>
        
        let delete: CommandFactory<PostID, Void>
                
        let edit: CommandFactory<EditPostPayload, Post>
        
        let fetch: CommandFactory<FetchParameters<PostID>, Post>
        
        let list: CommandFactory<PostQueryPayload, [Post]>

        let listPaged: CommandFactory<ListPostsPagedInput, [Post]>

        init(
            create: CommandFactory<PostPayload, Post> = .createPost,
            delete: CommandFactory<PostID, Void> = .deletePost,
            edit: CommandFactory<EditPostPayload, Post> = .editPost,
            fetch: CommandFactory<FetchParameters<PostID>, Post> = .fetchPost,
            list: CommandFactory<PostQueryPayload, [Post]> = .listPosts,
            listPaged: CommandFactory<ListPostsPagedInput, [Post]> = .listPostsPaged
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.list = list
            self.listPaged = listPaged
        }
    }
}
