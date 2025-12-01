import Fluent
import Vapor
import Foundation
import AuthKit

typealias NoteID = Note.IDValue

final class Note: Model, Content, @unchecked Sendable {
    
    static let schema = "notes"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Parent(key: "attachment_id")
    private(set) var attachment: Preview

    @Parent(key: "author_id")
    private(set) var author: User

    @Field(key: "body")
    var body: String

    @Enum(key: "access")
    var access: Access

    @Timestamp(key: "created_at", on: .create)
    private(set) var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    private(set) var updatedAt: Date?

    @Children(for: \.$note)
    private(set) var quotes: [Quote]

    init() {}

    init(
        attachmentID: UUID,
        authorID: Int,
        access: Access,
        body: String
    ) {
        self.$attachment.id = attachmentID
        self.$author.id = authorID
        self.access = access
        self.body = body
    }
}
