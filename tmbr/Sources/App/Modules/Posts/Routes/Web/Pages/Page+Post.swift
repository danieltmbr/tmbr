import Foundation
import Vapor
import AuthKit
import Core

struct PostViewModel: Encodable {
    
    private let attachment: PreviewResponse?

    private let author: String
    
    private let content: String

    private let id: Int?
    
    private let publishDate: String
    
    private let title: String
    
    init(
        attachment: PreviewResponse?,
        author: String,
        content: String,
        id: Int?,
        publishDate: String,
        title: String
    ) {
        self.attachment = attachment
        self.author = author
        self.content = content
        self.id = id
        self.publishDate = publishDate
        self.title = title
    }
    
    init(
        post: Post,
        markdownFormatter formatter: MarkdownFormatter = .html,
        nameFormatter: NameFormatter = .author,
        attachment: PreviewResponse? = nil
    ) {
        
        self.init(
            attachment: attachment,
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
            let attachment = post.attachment.map {
                PreviewResponse(preview: $0, baseURL: req.baseURL)
            }
            return PostViewModel(post: post, attachment: attachment)
        }
    }
}
