import Foundation

public struct PostResponse: Codable, Sendable {

    public let id: PostID

    public let attachment: PreviewResponse?

    public let author: UserResponse

    public let content: String

    public let createdAt: Date

    public let state: PostState

    public let title: String

    public init(
        id: PostID,
        attachment: PreviewResponse?,
        author: UserResponse,
        content: String,
        createdAt: Date,
        state: PostState,
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
}
