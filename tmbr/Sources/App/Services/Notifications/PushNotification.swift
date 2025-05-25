import Foundation
import Vapor

struct PushNotification: Encodable, Sendable {

    let body: String
    
    let title: String
    
    let url: URL
    
    init(title: String, body: String, url: URL) {
        self.title = title
        self.body = body
        self.url = url
    }
    
    init(post: Post) throws {
        guard let id = post.id,
              let url = URL(string: "\(Environment.webApp.startURL)/post/\(id)") else {
            throw Abort(.internalServerError, reason: "Unidentified post")
        }
        self.init(
            title: "New post",
            body: "\(post.title)",
            url: url
        )
    }
}
