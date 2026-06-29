import WebCore
import Fluent
import Vapor
import WebAuth
import TmbrCore

final class Post: Model, Content, @unchecked Sendable {

    typealias State = PostState
    
    static let schema = "posts"
    
    @OptionalParent(key: "attachment_id")
    var attachment: Preview?
    
    @Parent(key: "author_id")
    var author: User

    @Field(key: "content")
    var content: String

    @Field(key: "created_at")
    var createdAt: Date

    @Field(key: "language")
    var language: Language

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @OptionalField(key: "published_at")
    var publishedAt: Date?

    @Field(key: "state")
    var state: State

    @Field(key: "title")
    var title: String

    init() {}

    init(
        attachmentID: UUID? = nil,
        authorID: UserID,
        content: String,
        createdAt: Date = .now,
        id: Int? = nil,
        language: Language = .en,
        state: State = .draft,
        title: String
    ) {
        self.$attachment.id = attachmentID
        self.$author.id = authorID
        self.content = content
        self.createdAt = createdAt
        self.id = id
        self.language = language
        self.state = state
        self.title = title
    }
}

extension Post: TimestampedModel {
    static var createdAtPath: KeyPath<Post, FieldProperty<Post, Date>> { \.$createdAt }
}

extension Post: LanguageFilterable {
    static var languageKeyPath: KeyPath<Post, FieldProperty<Post, Language>> { \.$language }
}
