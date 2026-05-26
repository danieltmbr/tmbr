import Foundation

public struct NoteResponse: Codable, Sendable {

    public let id: NoteID

    public let access: Access

    public let attachment: PreviewResponse

    public let author: UserResponse

    public let body: String

    public let created: Date

    public let quotes: [QuoteResponse]

    public init(
        id: NoteID,
        access: Access,
        attachment: PreviewResponse,
        author: UserResponse,
        body: String,
        created: Date,
        quotes: [QuoteResponse]
    ) {
        self.id = id
        self.access = access
        self.attachment = attachment
        self.author = author
        self.body = body
        self.created = created
        self.quotes = quotes
    }
}
