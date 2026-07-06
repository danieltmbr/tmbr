import Foundation
import SwiftData

/// A single result row for the catalogue search surface.
///
/// `preview` is the matching catalogue item. `noteSnippet` is present when the match came
/// from a note body (not the item's own title/subtitle) — it holds the full note body so
/// the row can render a snippet.
public struct CatalogueSearchResult: Identifiable {

    public var id: UUID { preview.id }

    public let preview: PreviewRecord

    /// The full note body that matched, when this result came from a note-body search.
    /// `nil` when the match was on the item's own `primaryInfo` or `secondaryInfo`.
    public let noteSnippet: String?

    public init(preview: PreviewRecord, noteSnippet: String? = nil) {
        self.preview = preview
        self.noteSnippet = noteSnippet
    }
}
