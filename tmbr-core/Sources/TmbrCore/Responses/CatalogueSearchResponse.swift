import Foundation

/// Combined result of a catalogue search — item-metadata matches and note-body matches.
///
/// `items` are catalogue items whose title/subtitle matched the search term.
/// `notes` are notes whose body matched; each carries its full `attachment` preview so the app
/// can upsert both the note and its item into the local DB.
///
/// `nextCursor` is an opaque ISO 8601 date string. Pass it as `cursor` in the next request to
/// load the following page. `nil` means this is the last page.
public struct CatalogueSearchResponse: Codable, Sendable {

    public let items: [PreviewResponse]

    public let notes: [NoteResponse]

    public let nextCursor: String?

    public init(items: [PreviewResponse], notes: [NoteResponse], nextCursor: String? = nil) {
        self.items = items
        self.notes = notes
        self.nextCursor = nextCursor
    }
}
