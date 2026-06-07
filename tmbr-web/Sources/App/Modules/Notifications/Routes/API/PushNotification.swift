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
              let url = URL(string: "\(Environment.webApp.startURL)/posts/\(id)") else {
            throw Abort(.internalServerError, reason: "Unidentified post")
        }
        self.init(
            title: "New post",
            body: "\(post.title)",
            url: url
        )
    }

    init(note: Note, preview: Preview) throws {
        guard note.id != nil else {
            throw Abort(.internalServerError, reason: "Unidentified note")
        }
        let categoryName = preview.catalogueCategory?.name ?? "catalogue item"
        let urlString: String
        if let route = preview.catalogueCategory?.route, let parentID = preview.parentID {
            urlString = "\(Environment.webApp.startURL)/\(route)/\(parentID)"
        } else {
            urlString = Environment.webApp.startURL
        }
        guard let url = URL(string: urlString) else {
            throw Abort(.internalServerError, reason: "Invalid note URL")
        }
        self.init(
            title: "New \(categoryName) note",
            body: preview.primaryInfo,
            url: url
        )
    }
}
