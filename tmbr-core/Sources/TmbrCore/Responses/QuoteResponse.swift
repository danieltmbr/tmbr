import Foundation

public struct QuoteResponse: Codable, Sendable {

    public let id: QuoteID

    public let body: String

    public let createdAt: Date

    public let source: QuoteSource

    public init(
        id: QuoteID,
        body: String,
        createdAt: Date,
        source: QuoteSource
    ) {
        self.id = id
        self.body = body
        self.createdAt = createdAt
        self.source = source
    }
}

public struct QuoteSource: Codable, Sendable {

    public enum Kind: String, Codable, Sendable {
        case note
        case post
    }

    public let kind: Kind

    /// Display title of the source item (note attachment's primaryInfo or post title).
    public let title: String

    /// Display subtitle of the source item (note attachment's secondaryInfo; nil for posts).
    public let subtitle: String?

    /// Category slug of the source item ("song", "book", …). nil for post-sourced quotes.
    public let type: String?

    /// Catalogue preview (note-sourced) or post's optional artwork (post-sourced).
    public let preview: PreviewResponse?

    /// Set when kind == .note.
    public let noteID: NoteID?

    /// Set when kind == .post.
    public let postID: PostID?

    public init(
        kind: Kind,
        title: String,
        subtitle: String?,
        type: String?,
        preview: PreviewResponse?,
        noteID: NoteID?,
        postID: PostID?
    ) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.type = type
        self.preview = preview
        self.noteID = noteID
        self.postID = postID
    }
}
