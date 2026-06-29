import Foundation

public struct QuoteResponse: Codable, Sendable {

    public let body: String

    public let noteID: NoteID

    public let preview: PreviewResponse

    public init(
        body: String,
        noteID: NoteID,
        preview: PreviewResponse
    ) {
        self.body = body
        self.noteID = noteID
        self.preview = preview
    }
}
