import Foundation
import Vapor
import Markdown

struct PostViewModel: Content {

    private let author: String
    
    private let content: String

    private let id: Int?
    
    private let publishDate: String
    
    private let title: String
    
    init(
        post: Post,
        markdownFormatter formatter: MarkdownFormatter = .html
    ) {
        self.author = NameFormatter.author.format(
            givenName: post.$author.value?.firstName,
            familyName: post.$author.value?.lastName
        )
        self.content = formatter.format(post.content)
        self.id = post.id
        self.publishDate = post.createdAt.formatted(.publishDate)
        self.title = post.title
    }
}

extension Template where Model == PostViewModel {
    static let post = Template(name: "post")
}

extension Page where Model == PostViewModel {
    static var post: Self {
        Page(template: .post) { req in
            guard let postID = req.parameters.get("postID", as: Int.self) else {
                throw Abort(.badRequest)
            }
            guard let post = try await Post.find(postID, on: req.db) else {
                throw Abort(.notFound)
            }
            guard post.state == .published || post.$author.id == req.auth.get(User.self)?.id else {
                req.logger.trace("Unauthorized. Draft posts are only available for the author.")
                throw Abort(.notFound, reason: "Post not found")
            }
            return PostViewModel(post: post)
        }
    }
}
