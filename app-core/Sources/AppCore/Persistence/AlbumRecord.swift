import Foundation
import SwiftData

/// Rich, typed data for an album. Tracks are modelled separately via `ContainerEntryRecord`
/// (mirroring the backend `ContainerEntry`). Linked to its `PreviewRecord` by `previewID`.
///
@Model
public final class AlbumRecord {

    public var previewID: UUID = UUID()

    public var sourceID: Int?

    public var title: String = ""

    public var artist: String = ""

    public var genre: String?

    public var releaseDate: Date?

    public var artworkURL: String?

    public var resourceURLs: [String] = []

    var accessRaw: String = ""

    var syncStateRaw: String = SyncState.synced.rawValue

    public init(
        previewID: UUID = UUID(),
        sourceID: Int? = nil,
        title: String = "",
        artist: String = "",
        genre: String? = nil,
        releaseDate: Date? = nil,
        artworkURL: String? = nil,
        resourceURLs: [String] = [],
        access: Access = .private,
        syncState: SyncState = .synced
    ) {
        self.previewID = previewID
        self.sourceID = sourceID
        self.title = title
        self.artist = artist
        self.genre = genre
        self.releaseDate = releaseDate
        self.artworkURL = artworkURL
        self.resourceURLs = resourceURLs
        self.accessRaw = access.rawValue
        self.syncStateRaw = syncState.rawValue
    }
}

public extension AlbumRecord {
    var access: Access {
        get { Access(rawValue: accessRaw) ?? .private }
        set { accessRaw = newValue.rawValue }
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
