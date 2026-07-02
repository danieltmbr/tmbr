import Foundation

public struct PostResponse: Codable, Sendable {

    public let id: PostID

    public let attachment: PreviewResponse?

    public let author: UserResponse

    public let content: String

    public let createdAt: Date

    public let language: Language

    public let publishedAt: Date?

    public let quotes: [QuoteResponse]

    public let state: PostState

    public let title: String

    public init(
        id: PostID,
        attachment: PreviewResponse?,
        author: UserResponse,
        content: String,
        createdAt: Date,
        language: Language,
        publishedAt: Date?,
        quotes: [QuoteResponse],
        state: PostState,
        title: String
    ) {
        self.id = id
        self.attachment = attachment
        self.author = author
        self.content = content
        self.createdAt = createdAt
        self.language = language
        self.publishedAt = publishedAt
        self.quotes = quotes
        self.state = state
        self.title = title
    }
}
