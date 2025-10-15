import Fluent
import Vapor

final class Post: Model, Content, @unchecked Sendable {
    
    enum State: String, Codable, Sendable {
        case published
        case draft
    }
    
    static let schema = "posts"
    
    @Parent(key: "author_id")
    var author: User

    @Field(key: "content")
    var content: String

    @Field(key: "created_at")
    var createdAt: Date

    @OptionalParent(key: "media_id")
    var media: Media?

    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "state")
    var state: State
    
    @Field(key: "title")
    var title: String

    init() {}
    
    init(
        author: User,
        content: String,
        createdAt: Date = Date(),
        id: Int? = nil,
        state: State = .draft,
        title: String
    ) {
        self.author = author
        self.content = content
        self.createdAt = createdAt
        self.id = id
        self.state = state
        self.title = title
    }
}
