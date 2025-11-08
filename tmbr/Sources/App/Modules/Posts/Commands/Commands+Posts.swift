import Foundation
import Core

extension Commands {
    var posts: Commands.Posts.Type { Commands.Posts.self }
}

extension Commands {
    struct Posts: CommandCollection, Sendable {
                
        let create: CommandFactory<Post, Post>
        
        let delete: CommandFactory<Post.IDValue, Void>
                
        let edit: CommandFactory<Post, Post>
        
        let list: CommandFactory<Void, [Post]>
        
        let post: CommandFactory<Post.IDValue, Post>
        
        init(
            create: CommandFactory<Post, Post> = .createPost,
            delete: CommandFactory<Post.IDValue, Void> = .deletePost,
            edit: CommandFactory<Post, Post> = .editPost,
            list: CommandFactory<Void, [Post]> = .listPosts,
            post: CommandFactory<Post.IDValue, Post> = .fetchPost
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.list = list
            self.post = post
        }
    }
}


