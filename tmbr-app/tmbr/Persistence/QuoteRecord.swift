import Foundation
import SwiftData

/// Local representation of a text quote attached to a note.
///
/// `QuoteResponse` has no server-side ID — quotes are identified on the
/// server by the pair `(noteID, body)`. The local `clientKey` is the
/// stable identity; `noteServerID + body` is the deduplication key
/// used when merging pull responses.
///
/// The source item fields are denormalised so quotes can be displayed
/// without loading a CatalogueItemRecord or NoteRecord.
@Model
final class QuoteRecord {

    @Attribute(.unique)
    var clientKey: UUID

    var body: String
    var noteClientKey: UUID      // links to NoteRecord.clientKey
    var noteServerID: UUID?      // set once the parent NoteRecord has a serverID
    var sourcePreviewID: UUID    // PreviewID of the quoted item
    var sourceTitle: String      // denormalised title of the quoted item
    var sourceType: String?      // "song" | "book" | etc.
    var syncStateRaw: String     // SyncState.rawValue

    init(
        clientKey: UUID = UUID(),
        body: String,
        noteClientKey: UUID,
        noteServerID: UUID? = nil,
        sourcePreviewID: UUID,
        sourceTitle: String,
        sourceType: String? = nil,
        syncState: SyncState = .synced
    ) {
        self.clientKey = clientKey
        self.body = body
        self.noteClientKey = noteClientKey
        self.noteServerID = noteServerID
        self.sourcePreviewID = sourcePreviewID
        self.sourceTitle = sourceTitle
        self.sourceType = sourceType
        self.syncStateRaw = syncState.rawValue
    }
}

extension QuoteRecord {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
