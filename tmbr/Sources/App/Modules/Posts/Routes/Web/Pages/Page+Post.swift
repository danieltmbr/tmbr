import Foundation
import Vapor
import AuthKit
import Core

struct PostViewModel: Content {

    private let author: String
    
    private let content: String

    private let id: Int?
    
    private let publishDate: String
    
    private let title: String
    
    init(
        author: String,
        content: String,
        id: Int?,
        publishDate: String,
        title: String
    ) {
        self.author = author
        self.content = content
        self.id = id
        self.publishDate = publishDate
        self.title = title
    }
    
    init(
        post: Post,
        markdownFormatter formatter: MarkdownFormatter = .html,
        nameFormatter: NameFormatter = .author
    ) {
        
        self.init(
            author: nameFormatter.format(
                givenName: post.$author.value?.firstName,
                familyName: post.$author.value?.lastName
            ),
            content: formatter.format(post.content),
            id: post.id,
            publishDate: post.state == .published ? post.createdAt.formatted(.publishDate) : "Draft",
            title: post.title
        )
    }
}

extension Template where Model == PostViewModel {
    static let post = Template(name: "Posts/post")
}

extension Page {
    static var post: Self {
        Page(template: .post) { req in
            guard let postID = req.parameters.get("postID", as: Int.self) else {
                throw Abort(.badRequest)
            }
            let post = try await req.commands.posts.fetch(postID, for: .read)
            return PostViewModel(post: post)
        }
    }
}
