import Fluent
import Vapor
import Foundation

final class Quote: Model, Content, @unchecked Sendable {
    static let schema = "quotes"

    /// Stable user-generated UUID — assigned once on first extraction and
    /// preserved across source edits by the reconcile algorithm.
    @ID(custom: "id", generatedBy: .user)
    var id: UUID?

    /// Set when the quote originates from a note. Exactly one of note/post is non-nil.
    @OptionalParent(key: "note_id")
    var note: Note?

    /// Set when the quote originates from a blog post. Exactly one of note/post is non-nil.
    @OptionalParent(key: "post_id")
    var post: Post?

    @Field(key: "body")
    var body: String

    @Timestamp(key: "created_at", on: .create)
    private(set) var createdAt: Date?

    init() {}

    init(noteID: UUID, body: String) {
        self.id = UUID()
        self.$note.id = noteID
        self.body = body
    }

    init(postID: Int, body: String) {
        self.id = UUID()
        self.$post.id = postID
        self.body = body
    }
}
