import Foundation
import SwiftData

/// One ordered membership of a track in an album or playlist — mirroring the backend
/// `ContainerEntry`. Enables offline track-list management.
///
/// Links by UUID/Int (not `@Relationship`): `memberPreviewID` is the track member's PreviewID,
/// `containerSourceID` is the album/playlist's backing Int id.
///
/// **Track removal honors promotion:** when a container is deleted, only `.promotable`
/// (unpromoted) members are removed; promoted members survive — matching the backend
/// `deleteContainerEntries` command.
@Model
public final class ContainerEntryRecord {

    public var clientKey: UUID = UUID()

    public var containerType: String = ""        // "album" | "playlist"
    public var containerSourceID: Int = 0        // backing album/playlist Int id
    public var memberPreviewID: UUID = UUID()    // the track member's PreviewID
    public var position: Int = 0
    public var syncStateRaw: String = SyncState.synced.rawValue

    public init(
        clientKey: UUID = UUID(),
        containerType: String = "",
        containerSourceID: Int = 0,
        memberPreviewID: UUID = UUID(),
        position: Int = 0,
        syncState: SyncState = .synced
    ) {
        self.clientKey = clientKey
        self.containerType = containerType
        self.containerSourceID = containerSourceID
        self.memberPreviewID = memberPreviewID
        self.position = position
        self.syncStateRaw = syncState.rawValue
    }
}

public extension ContainerEntryRecord {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
