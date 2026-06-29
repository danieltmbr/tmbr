import Foundation
import TmbrCore
import WebAuth

extension PostResponse {

    init(post: Post, baseURL: String) {
        self.init(
            id: post.id!,
            attachment: post.attachment.map { PreviewResponse(preview: $0, baseURL: baseURL) },
            author: UserResponse(user: post.author),
            content: post.content,
            createdAt: post.createdAt,
            language: post.language,
            publishedAt: post.publishedAt,
            state: post.state,
            title: post.title
        )
    }
}
