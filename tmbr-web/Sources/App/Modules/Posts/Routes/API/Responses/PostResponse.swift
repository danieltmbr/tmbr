import Foundation
import TmbrCore
import WebAuth

extension PostResponse {

    init(post: Post, baseURL: String) throws {
        let id = try post.requireID()
        self.init(
            id: id,
            attachment: post.attachment.map { PreviewResponse(preview: $0, baseURL: baseURL) },
            author: UserResponse(user: post.author),
            content: post.content,
            createdAt: post.createdAt,
            language: post.language,
            publishedAt: post.publishedAt,
            quotes: try post.quotes.map { try QuoteResponse(quote: $0, post: post, baseURL: baseURL) },
            state: post.state,
            title: post.title
        )
    }
}
