import Fluent
import Vapor

final class Post: Model, Content, @unchecked Sendable {
    static let schema = "posts" // Database table name

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "content")
    var content: String

    @Field(key: "created_at")
    var createdAt: Date?

    init() {}

    init(id: UUID? = nil, title: String, content: String, createdAt: Date? = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
    }
}
