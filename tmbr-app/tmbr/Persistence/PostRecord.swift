import Foundation
import SwiftData

/// Local representation of a user blog post.
///
/// `clientKey` is the stable local identity, always set before the post reaches
/// the server. `serverID` is nil until the backend assigns an integer PostID.
@Model
final class PostRecord {

    @Attribute(.unique)
    var clientKey: UUID

    var serverID: Int?
    var title: String
    var content: String
    var stateRaw: String         // PostState.rawValue  ("draft" | "published")
    var languageRaw: String      // Language.rawValue
    var createdAt: Date
    var publishedAt: Date?
    var syncStateRaw: String     // SyncState.rawValue

    // Optional catalogue item this post is about
    var attachmentID: UUID?
    var attachmentTitle: String?

    init(
        clientKey: UUID = UUID(),
        serverID: Int? = nil,
        title: String,
        content: String,
        stateRaw: String,
        languageRaw: String,
        createdAt: Date = .now,
        publishedAt: Date? = nil,
        syncState: SyncState = .pendingCreate,
        attachmentID: UUID? = nil,
        attachmentTitle: String? = nil
    ) {
        self.clientKey = clientKey
        self.serverID = serverID
        self.title = title
        self.content = content
        self.stateRaw = stateRaw
        self.languageRaw = languageRaw
        self.createdAt = createdAt
        self.publishedAt = publishedAt
        self.syncStateRaw = syncState.rawValue
        self.attachmentID = attachmentID
        self.attachmentTitle = attachmentTitle
    }
}

extension PostRecord {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
