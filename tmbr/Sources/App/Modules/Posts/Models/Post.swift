import Fluent
import Vapor
import AuthKit

typealias PostID = Post.IDValue

final class Post: Model, Content, @unchecked Sendable {
    
    struct Attachment {
        let attachmentID: Int
        
        let attachmentType: String
    }
    
    enum State: String, Codable, Sendable {
        case published
        case draft
    }
    
    static let schema = "posts"
    
    var attachment: Attachment? {
        guard let attachmentID, let attachmentType else { return nil }
        return Attachment(
            attachmentID: attachmentID,
            attachmentType: attachmentType
        )
    }
    
    @OptionalField(key: "attachment_id")
    private var attachmentID: Int?
    
    @OptionalField(key: "attachment_type")
    private var attachmentType: String?
    
    @Parent(key: "author_id")
    var author: User

    @Field(key: "content")
    var content: String

    @Field(key: "created_at")
    var createdAt: Date
    
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "state")
    var state: State
    
    @Field(key: "title")
    var title: String

    init() {}
    
    init(
        authorID: UserID,
        content: String,
        createdAt: Date = .now,
        id: Int? = nil,
        state: State = .draft,
        title: String,
        attachmentID: Int? = nil,
        attachmentType: String? = nil
    ) {
        self.$author.id = authorID
        self.content = content
        self.createdAt = createdAt
        self.id = id
        self.state = state
        self.title = title
        self.attachmentID = attachmentID
        self.attachmentType = attachmentType
    }
}
