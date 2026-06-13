import Foundation
import SwiftData

/// Local representation of a user note attached to a catalogue item.
///
/// `clientKey` is always client-generated and serves as the stable local identity.
/// `serverID` is nil until the backend confirms creation, because the server generates
/// note UUIDs — the client cannot pre-supply them through the create endpoint.
/// After a successful push, `NoteResponse.id` is written back into `serverID`.
///
/// Attachment fields are denormalised here so a NoteRecord can exist
/// independently of its CatalogueItemRecord (which may not yet be synced).
@Model
final class NoteRecord {

    @Attribute(.unique)
    var clientKey: UUID

    var serverID: UUID?
    var body: String
    var accessRaw: String        // Access.rawValue
    var languageRaw: String      // Language.rawValue
    var createdAt: Date
    var syncStateRaw: String     // SyncState.rawValue

    // Denormalised attachment — mirrors NoteResponse.attachment (PreviewResponse)
    var attachmentID: UUID
    var attachmentTitle: String
    var attachmentSubtitle: String?
    var attachmentCategoryType: String?   // "song" | "book" | "recipe" | etc.
    var attachmentSourceID: Int?          // nil for orphan attachments

    init(
        clientKey: UUID = UUID(),
        serverID: UUID? = nil,
        body: String,
        accessRaw: String,
        languageRaw: String,
        createdAt: Date = .now,
        syncState: SyncState = .pendingCreate,
        attachmentID: UUID,
        attachmentTitle: String,
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
        self.attachmentID = attachmentID
        self.attachmentTitle = attachmentTitle
        self.attachmentSubtitle = attachmentSubtitle
        self.attachmentCategoryType = attachmentCategoryType
        self.attachmentSourceID = attachmentSourceID
    }
}

extension NoteRecord {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
