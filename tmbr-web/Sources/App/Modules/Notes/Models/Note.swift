import CoreWeb
import Fluent
import Vapor
import Foundation
import CoreAuth
import CoreTmbr

final class Note: Model, Content, @unchecked Sendable {
    
    static let schema = "notes"

    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "attachment_id")
    private(set) var attachment: Preview

    @Parent(key: "author_id")
    private(set) var author: User

    @Field(key: "body")
    var body: String

    @Enum(key: "access")
    var access: Access

    @Field(key: "language")
    var language: Language

    @Field(key: "created_at")
    private(set) var createdAt: Date

    @Timestamp(key: "updated_at", on: .update)
    private(set) var updatedAt: Date?

    @Children(for: \.$note)
    private(set) var quotes: [Quote]

    init() {}

    init(
        id: UUID = UUID(),
        attachmentID: UUID,
        authorID: Int,
        access: Access,
        body: String,
        language: Language = .en
    ) {
        self.id = id
        self.$attachment.id = attachmentID
        self.$author.id = authorID
        self.access = access
        self.body = body
        self.language = language
        self.createdAt = .now
    }
}

extension Note: TimestampedModel {
    static var createdAtPath: KeyPath<Note, FieldProperty<Note, Date>> { \.$createdAt }
}

extension Note: LanguageFilterable {
    static var languageKeyPath: KeyPath<Note, FieldProperty<Note, Language>> { \.$language }
}
