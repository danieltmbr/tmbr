import Foundation
import TmbrCore
import AuthKit

extension PostResponse {

    init(post: Post, baseURL: String) {
        self.init(
            id: post.id!,
            attachment: post.attachment.map { PreviewResponse(preview: $0, baseURL: baseURL) },
            author: UserResponse(user: post.author),
            content: post.content,
            createdAt: post.createdAt,
            state: post.state,
            title: post.title
        )
    }
}
