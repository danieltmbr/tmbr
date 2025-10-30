import Core
import Foundation
import Vapor
import Fluent
import AuthKit

struct PostsViewModel: Content {
    struct PostItem: Content {
        private let id: Int
        
        private let title: String
        
        private let publishDate: String
        
        init(id: Int, title: String, publishDate: String) {
            self.id = id
            self.title = title
            self.publishDate = publishDate
        }
    }

    private let posts: [PostItem]
    
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

extension Template where Model == PostsViewModel {
    static let posts = Template(name: "posts")
}

extension Core.Page {
    static var posts: Self {
        Page(template: .posts) { req in
            let posts = try await Post.query(on: req.db)
                .filter(\.$state == .published)
                .sort(\.$createdAt, .descending)
                .all()
            return PostsViewModel(posts: posts)
        }
    }
    
    static var drafts: Self {
        Page(template: .posts) { req in
            let user = try req.auth.require(User.self)
            let userID = try user.requireID()
            let posts = try await Post.query(on: req.db)
                .filter(\.$state == .draft)
                .filter(\.$author.$id == userID)
                .sort(\.$createdAt, .descending)
                .all()
            return PostsViewModel(posts: posts)
        }
    }
}
