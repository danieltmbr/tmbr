import Foundation
import WebCore
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
        
        let list: CommandFactory<ListPostsInput, [Post]>

        init(
            create: CommandFactory<PostPayload, Post> = .createPost,
            delete: CommandFactory<PostID, Void> = .deletePost,
            edit: CommandFactory<EditPostPayload, Post> = .editPost,
            fetch: CommandFactory<FetchParameters<PostID>, Post> = .fetchPost,
            list: CommandFactory<ListPostsInput, [Post]> = .listPosts
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.list = list
        }
    }
}
