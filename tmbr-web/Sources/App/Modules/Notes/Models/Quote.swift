import Fluent
import Vapor
import Foundation

final class Quote: Model, Content, @unchecked Sendable {
    static let schema = "quotes"
    
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Parent(key: "note_id")
    private(set) var note: Note
    
    @Field(key: "body")
    private(set) var body: String
    
    @Timestamp(key: "created_at", on: .create)
    private(set) var createdAt: Date?
        
    init() {}
    
    init(
        noteID: UUID,
        body: String
    ) {
        self.$note.id = noteID
        self.body = body
    }
}
