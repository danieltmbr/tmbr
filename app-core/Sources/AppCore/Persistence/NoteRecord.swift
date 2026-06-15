import Foundation
import SwiftData

/// Local representation of a user note attached to a catalogue item.
///
/// `clientKey` is always client-generated and is the stable local identity. `serverID` is nil until
/// the backend confirms creation (the server generates note UUIDs). After a successful push,
/// `NoteResponse.id` is written back into `serverID`.
///
/// The note anchors to its catalogue item by `attachmentPreviewID` (the server PreviewID) — a plain
/// UUID link, not a `@Relationship`, so a note can exist before its `PreviewRecord` is synced and so
/// CloudKit mirroring stays trivial. Push uses it to call `POST /api/catalogue/item/:previewID/notes`.
@Model
public final class NoteRecord {

    public var clientKey: UUID = UUID()

    public var serverID: UUID?
    public var body: String = ""
    public var accessRaw: String = ""               // Access.rawValue
    public var languageRaw: String = ""             // Language.rawValue
    public var createdAt: Date = Date.now
    public var syncStateRaw: String = SyncState.synced.rawValue

    // Denormalised attachment — lets a NoteRecord display/sync without its PreviewRecord present.
    public var attachmentPreviewID: UUID?
    public var attachmentTitle: String = ""
    public var attachmentSubtitle: String?
    public var attachmentCategoryType: String?      // "song" | "book" | …
    public var attachmentSourceID: Int?             // nil for orphan attachments

    public init(
        clientKey: UUID = UUID(),
        serverID: UUID? = nil,
        body: String = "",
        accessRaw: String = "",
        languageRaw: String = "",
        createdAt: Date = .now,
        syncState: SyncState = .pendingCreate,
        attachmentPreviewID: UUID? = nil,
        attachmentTitle: String = "",
        attachmentSubtitle: String? = nil,
        attachmentCategoryType: String? = nil,
        attachmentSourceID: Int? = nil
    ) {
        self.clientKey = clientKey
        self.serverID = serverID
        self.body = body
        self.accessRaw = accessRaw
        self.languageRaw = languageRaw
        self.createdAt = createdAt
        self.syncStateRaw = syncState.rawValue
        self.attachmentPreviewID = attachmentPreviewID
        self.attachmentTitle = attachmentTitle
        self.attachmentSubtitle = attachmentSubtitle
        self.attachmentCategoryType = attachmentCategoryType
        self.attachmentSourceID = attachmentSourceID
    }
}

public extension NoteRecord {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
