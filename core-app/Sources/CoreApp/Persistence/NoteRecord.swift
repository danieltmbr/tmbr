import Foundation
import SwiftData
import CoreTmbr

/// Local representation of a user note attached to a catalogue item.
///
/// `clientKey` is always client-generated and is the stable local identity. `serverID` is nil until
/// the backend confirms creation (the server generates note UUIDs). After a successful push,
/// `NoteResponse.id` is written back into `serverID`.
///
/// The note anchors to its catalogue item by `attachmentPreviewID` (the server PreviewID) — a plain
/// UUID link, not a `@Relationship`, so a note can exist before its `PreviewRecord` is synced and so
/// CloudKit mirroring stays trivial. Push uses it to call `POST /api/catalogue/item/:previewID/notes`.
///
@Model
public final class NoteRecord {

    public var clientKey: UUID = UUID()

    public var serverID: UUID?

    public var body: String = ""

    var accessRaw: String = ""

    var languageRaw: String = ""

    public var createdAt: Date = Date.now

    var syncStateRaw: String = SyncState.synced.rawValue

    // Denormalised attachment — lets a NoteRecord display/sync without its PreviewRecord present.
    public var attachmentPreviewID: UUID?

    public var attachmentTitle: String = ""

    public var attachmentSubtitle: String?

    /// "song" | "book" | …
    public var attachmentCategoryType: String?

    /// nil for orphan attachments
    public var attachmentSourceID: Int?

    public init(
        clientKey: UUID = UUID(),
        serverID: UUID? = nil,
        body: String = "",
        access: Access = .private,
        language: Language? = nil,
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
        self.accessRaw = access.rawValue
        self.languageRaw = language?.rawValue ?? ""
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
    var markdown: AttributedString? {
        try? AttributedString(markdown: body)
    }

    var access: Access {
        get { Access(rawValue: accessRaw) ?? .private }
        set { accessRaw = newValue.rawValue }
    }

    var language: Language? {
        get { Language(rawValue: languageRaw) }
        set { languageRaw = newValue?.rawValue ?? "" }
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
