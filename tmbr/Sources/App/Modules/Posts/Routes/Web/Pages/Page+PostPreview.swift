import Core
import Foundation
import Vapor
import AuthKit

private struct PostPreviewPayload: Content {
    let title: String
    
    let body: String
}

extension Page {
    static var postPreview: Self {
        Page(template: .post) { req in
            let user = try req.auth.require(User.self)
            let payload = try req.content.decode(PostPreviewPayload.self)
            let markdownFormatter = MarkdownFormatter.html
            let nameFormatter: NameFormatter = .author
            return PostViewModel(
                author: nameFormatter.format(
                    givenName: user.firstName,
                    familyName: user.lastName
                ),
                content: markdownFormatter.format(payload.body),
                id: nil,
                publishDate: Date.now.formatted(.publishDate),
                title: payload.title
            )
        }
    }
}
