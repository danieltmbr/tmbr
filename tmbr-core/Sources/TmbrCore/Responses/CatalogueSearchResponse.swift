import Foundation

/// Combined result of a catalogue search — item-metadata matches and note-body matches.
///
/// `items` are catalogue items whose title/subtitle matched the search term.
/// `notes` are notes whose body matched; each carries its full `attachment` preview so the app
/// can upsert both the note and its item into the local DB.
public struct CatalogueSearchResponse: Codable, Sendable {

    public let items: [PreviewResponse]

    public let notes: [NoteResponse]

    public init(items: [PreviewResponse], notes: [NoteResponse]) {
        self.items = items
        self.notes = notes
    }
}
