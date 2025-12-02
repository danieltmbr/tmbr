import Foundation
import AuthKit
import Fluent

struct PostResponse: Encodable, Sendable {
    
    private let id: PostID
    
    private let attachment: PreviewResponse?
    
    private let author: UserResponse
    
    private let content: String
    
    private let createdAt: Date
    
    private let state: Post.State
    
    private let title: String
    
    init(
        id: PostID,
        attachment: PreviewResponse?,
        author: UserResponse,
        content: String,
        createdAt: Date,
        state: Post.State,
        title: String
    ) {
        self.id = id
        self.attachment = attachment
        self.author = author
        self.content = content
        self.createdAt = createdAt
        self.state = state
        self.title = title
    }
    
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
