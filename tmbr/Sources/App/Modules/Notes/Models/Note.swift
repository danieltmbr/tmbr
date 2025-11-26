import Fluent
import Vapor
import Foundation
import AuthKit

final class Note: Model, Content, @unchecked Sendable {
    
    enum State: String, Codable, Sendable {
        case `private`
        case published
        case draft
    }
    
    enum Kind: String, Codable, Sendable {
        case inspiration
        case progress
        case general
    }
    
    static let schema = "notes"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "author_id")
    var author: User

    @Field(key: "body")
    var body: String

    @Enum(key: "state")
    var state: State

    @Field(key: "attachment_type")
    var attachmentType: String

    @Field(key: "attachment_id")
    var attachmentID: Int

    @OptionalField(key: "kind")
    var kind: Kind?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Children(for: \.$note)
    var quotes: [Quote]

    init() {}

    init(
        authorID: Int,
        body: String,
        state: State = .draft,
        attachmentType: String,
        attachmentID: Int,
        kind: Kind? = nil
    ) {
        self.$author.id = authorID
        self.body = body
        self.state = state
        self.attachmentType = attachmentType
        self.attachmentID = attachmentID
        self.kind = kind
    }
}
