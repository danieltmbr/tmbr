import Foundation
import SwiftData

/// Rich, typed data for a playlist. Tracks are modelled separately via `ContainerEntryRecord`.
/// Linked to its `PreviewRecord` by `previewID`. Mirrors the backend `Playlist` / `PlaylistResponse`.
@Model
public final class PlaylistRecord {

    public var previewID: UUID = UUID()
    public var sourceID: Int?

    public var title: String = ""
    public var playlistDescription: String?
    public var artworkURL: String?
    public var resourceURLs: [String] = []
    public var accessRaw: String = ""
    public var syncStateRaw: String = SyncState.synced.rawValue

    public init(
        previewID: UUID = UUID(),
        sourceID: Int? = nil,
        title: String = "",
        playlistDescription: String? = nil,
        artworkURL: String? = nil,
        resourceURLs: [String] = [],
        accessRaw: String = "",
        syncState: SyncState = .synced
    ) {
        self.previewID = previewID
        self.sourceID = sourceID
        self.title = title
        self.playlistDescription = playlistDescription
        self.artworkURL = artworkURL
        self.resourceURLs = resourceURLs
        self.accessRaw = accessRaw
        self.syncStateRaw = syncState.rawValue
    }
}

public extension PlaylistRecord {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
