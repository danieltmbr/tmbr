import Foundation
import SwiftData
import CoreTmbr

/// One ordered membership of a track in an album or playlist — mirroring the backend
/// `ContainerEntry`. Enables offline track-list management.
///
/// Links by UUID/Int (not `@Relationship`): `memberPreviewID` is the track member's PreviewID,
/// `containerSourceID` is the album/playlist's backing Int id.
///
/// **Track removal honors promotion:** when a container is deleted, only `.promotable`
/// (unpromoted) members are removed; promoted members survive — matching the backend
/// `deleteContainerEntries` command.
/// 
@Model
public final class ContainerEntryRecord {

    public var clientKey: UUID = UUID()
    
    /// "album" | "playlist"
    public var containerType: String = ""
    
    /// backing album/playlist Int id
    public var containerSourceID: Int = 0
    
    /// the track member's PreviewID
    public var memberPreviewID: UUID = UUID()
    
    public var position: Int = 0

    /// Denormalised track title — lets the list render standalone without the member's
    /// `PreviewRecord` being cached.
    public var title: String = ""

    /// Optional direct track URL (e.g. a streaming link).
    public var trackURL: String?

    /// Route to the promoted song page (e.g. `/songs/123`); non-nil only when promoted.
    public var href: String?

    var syncStateRaw: String = SyncState.synced.rawValue

    public init(
        clientKey: UUID = UUID(),
        containerType: String = "",
        containerSourceID: Int = 0,
        memberPreviewID: UUID = UUID(),
        position: Int = 0,
        title: String = "",
        trackURL: String? = nil,
        href: String? = nil,
        syncState: SyncState = .synced
    ) {
        self.clientKey = clientKey
        self.containerType = containerType
        self.containerSourceID = containerSourceID
        self.memberPreviewID = memberPreviewID
        self.position = position
        self.title = title
        self.trackURL = trackURL
        self.href = href
        self.syncStateRaw = syncState.rawValue
    }
}

public extension ContainerEntryRecord {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
