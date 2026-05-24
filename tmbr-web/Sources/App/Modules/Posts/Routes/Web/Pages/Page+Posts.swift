import Core
import Foundation
import Vapor
import Fluent
import AuthKit

struct PostItemViewModel: Content {
    private let id: Int
    
    private let title: String
    
    private let publishDate: String
    
    init(id: Int, title: String, publishDate: String) {
        self.id = id
        self.title = title
        self.publishDate = publishDate
    }
    
    init(post: Post) throws {
        self.init(
            id: try post.requireID(),
            title: post.title,
            publishDate: post.createdAt.formatted(.publishDate)
        )
    }
}

struct PostsViewModel: Encodable, Sendable {

    private let posts: [PostItemViewModel]

    private let compose: ComposePopupViewModel?

    init(posts: [Post], compose: ComposePopupViewModel?) {
        self.posts = posts.compactMap { post in
            guard let id = post.id else { return nil }
            return PostItemViewModel(
                id: id,
                title: post.title,
                publishDate: post.createdAt.formatted(.publishDate)
            )
        }
        self.compose = compose
    }
}

extension Template where Model == PostsViewModel {
    static let posts = Template(name: "Posts/posts")
}

extension Page {
    static var posts: Self {
        Page(template: .posts) { req in
            let posts = try await req.commands.posts.list()
            let compose = ComposePopupViewModel(req.permissions.compose(.standard))
            return PostsViewModel(posts: posts, compose: compose)
        }
    }

    static var drafts: Self {
        Page(template: .posts) { req in
            let user = try await req.permissions.posts.drafts()
            let posts = try await Post.query(on: req.db)
                .filter(\.$state == .draft)
                .filter(\.$author.$id == user.userID)
                .sort(\.$createdAt, .descending)
                .all()
            let compose = ComposePopupViewModel(req.permissions.compose(.standard))
            return PostsViewModel(posts: posts, compose: compose)
        }
    }
}
