import Foundation
import SwiftData
import CoreTmbr

/// Rich, typed data for a playlist. Tracks are modelled separately via `ContainerEntryRecord`.
/// Linked to its `PreviewRecord` by `previewID`. Mirrors the backend `Playlist` / `PlaylistResponse`.
///
@Model
public final class PlaylistRecord {

    public var previewID: UUID = UUID()

    public var sourceID: Int?

    public var title: String = ""

    public var playlistDescription: String?

    public var artworkURL: String?

    public var resourceURLs: [String] = []

    var accessRaw: String = ""

    var syncStateRaw: String = SyncState.synced.rawValue

    public init(
        previewID: UUID = UUID(),
        sourceID: Int? = nil,
        title: String = "",
        playlistDescription: String? = nil,
        artworkURL: String? = nil,
        resourceURLs: [String] = [],
        access: Access = .private,
        syncState: SyncState = .synced
    ) {
        self.previewID = previewID
        self.sourceID = sourceID
        self.title = title
        self.playlistDescription = playlistDescription
        self.artworkURL = artworkURL
        self.resourceURLs = resourceURLs
        self.accessRaw = access.rawValue
        self.syncStateRaw = syncState.rawValue
    }
}

public extension PlaylistRecord {
    var access: Access {
        get { Access(rawValue: accessRaw) ?? .private }
        set { accessRaw = newValue.rawValue }
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
