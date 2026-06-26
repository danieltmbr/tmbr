import Foundation
import SwiftData
import CoreTmbr

/// Local representation of a user blog post.
///
/// `clientKey` is the stable local identity, always set before the post reaches the server.
/// `serverID` is nil until the backend assigns an integer PostID.
///
@Model
public final class PostRecord {

    public var clientKey: UUID = UUID()

    public var serverID: Int?

    public var title: String = ""

    public var content: String = ""

    var stateRaw: String = ""

    var languageRaw: String = ""

    public var createdAt: Date = Date.now

    public var publishedAt: Date?

    var syncStateRaw: String = SyncState.synced.rawValue

    // Optional catalogue item this post is about (anchored by PreviewID).
    public var attachmentID: UUID?
    
    public var attachmentTitle: String?

    public init(
        clientKey: UUID = UUID(),
        serverID: Int? = nil,
        title: String = "",
        content: String = "",
        state: PostState = .draft,
        language: Language? = nil,
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
        self.stateRaw = state.rawValue
        self.languageRaw = language?.rawValue ?? ""
        self.createdAt = createdAt
        self.publishedAt = publishedAt
        self.syncStateRaw = syncState.rawValue
        self.attachmentID = attachmentID
        self.attachmentTitle = attachmentTitle
    }
}

public extension PostRecord {
    var state: PostState {
        get { PostState(rawValue: stateRaw) ?? .draft }
        set { stateRaw = newValue.rawValue }
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
