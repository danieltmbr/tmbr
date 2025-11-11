import Foundation
import Core

extension Commands {
    var posts: Commands.Posts.Type { Commands.Posts.self }
}

extension Commands {
    struct Posts: CommandCollection, Sendable {
                
        let create: CommandFactory<PostPayload, Post>
        
        let delete: CommandFactory<PostID, Void>
                
        let edit: CommandFactory<EditPostPayload, Post>
        
        let fetch: CommandFactory<FetchPostParameters, Post>
        
        let list: CommandFactory<Void, [Post]>
        
        init(
            create: CommandFactory<PostPayload, Post> = .createPost,
            delete: CommandFactory<PostID, Void> = .deletePost,
            edit: CommandFactory<EditPostPayload, Post> = .editPost,
            fetch: CommandFactory<FetchPostParameters, Post> = .fetchPost,
            list: CommandFactory<Void, [Post]> = .listPosts
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.list = list
        }
    }
}


