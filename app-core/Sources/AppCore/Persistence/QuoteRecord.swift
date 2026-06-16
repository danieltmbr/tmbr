import Foundation
import SwiftData

/// Local representation of a text quote attached to a note.
///
/// `QuoteResponse` has no server-side ID — quotes are identified on the server by `(noteID, body)`.
/// The local `clientKey` is the stable identity; `noteServerID + body` is the dedup key when merging
/// pull responses. Source fields are denormalised so quotes render without loading other records.
/// 
@Model
public final class QuoteRecord {

    public var clientKey: UUID = UUID()

    public var body: String = ""
    
    /// links to NoteRecord.clientKey/
    public var noteClientKey: UUID = UUID()
    
    /// set once the parent NoteRecord has a serverID
    public var noteServerID: UUID?
    
    /// PreviewID of the quoted item
    public var sourcePreviewID: UUID = UUID()
    
    /// denormalised title of the quoted item
    public var sourceTitle: String = ""
    
    /// "song" | "book" | …
    public var sourceType: String?
    
    var syncStateRaw: String = SyncState.synced.rawValue

    public init(
        clientKey: UUID = UUID(),
        body: String = "",
        noteClientKey: UUID = UUID(),
        noteServerID: UUID? = nil,
        sourcePreviewID: UUID = UUID(),
        sourceTitle: String = "",
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

public extension QuoteRecord {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
