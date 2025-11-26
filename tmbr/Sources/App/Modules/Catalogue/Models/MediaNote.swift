import Fluent
import Vapor
import Foundation
import AuthKit

final class MediaNote: Model, @unchecked Sendable {
    static let schema = "media_notes"
    
    enum NoteType: String, Codable, Sendable {
        case quote
        case note
    }
    
    enum State: String, Codable, Sendable {
        case published
        case draft
    }
    
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Parent(key: "media_id")
    var media: Media
    
    @Parent(key: "author_id")
    var author: User
    
    @Field(key: "type")
    var type: NoteType
    
    @Field(key: "text")
    var text: String
    
    @OptionalField(key: "commentary")
    var commentary: String?
    
    @OptionalField(key: "position_start")
    var positionStart: String?
    
    @OptionalField(key: "position_end")
    var positionEnd: String?
    
    @Field(key: "state")
    var state: State
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(
        mediaID: Int,
        authorID: Int,
        type: NoteType,
        text: String,
        commentary: String? = nil,
        state: State = .draft,
        positionStart: String? = nil,
        positionEnd: String? = nil
    ) {
        self.$media.id = mediaID
        self.$author.id = authorID
        self.type = type
        self.text = text
        self.commentary = commentary
        self.state = state
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }
}
