import Foundation
import Vapor
import AuthKit
import Core

struct PostViewModel: Encodable {
    
    private let attachment: Preview?

    private let author: String
    
    private let content: String

    private let id: Int?
    
    private let publishDate: String
    
    private let title: String
    
    init(
        attachment: Preview?,
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
        attachment: Preview? = nil
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
            // TODO: Perhaps make a combined command
            let post = try await req.commands.posts.fetch(postID, for: .read)
            if let attachment = post.attachment {
                let params = FetchPreviewParameters(
                    id: attachment.attachmentID,
                    type: attachment.attachmentType
                )
                let preview = try await req.commands.previews.fetch(params)
                return PostViewModel(post: post, attachment: preview)
            } else {
                return PostViewModel(post: post)
            }
        }
    }
}
