import Foundation
import Vapor
import Leaf

struct PostsViewModel: Content {
    struct PostItem: Content {
        let id: Int
        
        let title: String
        
        let publishDate: String
    }

    let posts: [PostItem]
    
    init(posts: [Post]) {
        self.posts = posts.compactMap { post in
            guard let id = post.id else { return nil }
            return PostItem(
                id: id,
                title: post.title,
                publishDate: post.createdAt.formatted(.publishDate)
            )
        }
    }
}
