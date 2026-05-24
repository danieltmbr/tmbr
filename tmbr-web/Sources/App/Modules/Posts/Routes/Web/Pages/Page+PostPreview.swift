import Core
import Foundation
import Vapor
import AuthKit
import TmbrCore

private struct PostPreviewPayload: Content {
    let title: String
    
    let body: String
}

extension Page {
    static var postPreview: Self {
        Page(template: .post) { req in
            let user = try await req.permissions.posts.create.grant()
            let payload = try req.content.decode(PostPreviewPayload.self)
            let markdownFormatter = MarkdownFormatter.html
            let nameFormatter: NameFormatter = .author
            return PostViewModel(
                attachment: nil,
                author: nameFormatter.format(
                    givenName: user.firstName,
                    familyName: user.lastName
                ),
                content: markdownFormatter.format(payload.body),
                id: nil,
                publishDate: Date.now.formatted(.publishDate),
                title: "Preview: \(payload.title)"
            )
        }
    }
}
