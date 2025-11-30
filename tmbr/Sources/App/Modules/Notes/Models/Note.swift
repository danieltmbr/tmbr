import Fluent
import Vapor
import Foundation
import AuthKit

final class Note: Model, Content, @unchecked Sendable {
    
    enum State: String, Codable, Sendable {
        case `private`
        case `public`
    }
    
    static let schema = "notes"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Parent(key: "attachment_id")
    var attachment: Preview

    @Parent(key: "author_id")
    var author: User

    @Field(key: "body")
    var body: String

    @Enum(key: "state")
    var state: State

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Children(for: \.$note)
    var quotes: [Quote]

    init() {}

    init(
        attachmentID: Int,
        authorID: Int,
        body: String,
        state: State = .draft
    ) {
        self.$attachment.id = attachmentID
        self.$author.id = authorID
        self.body = body
        self.state = state
    }
}
