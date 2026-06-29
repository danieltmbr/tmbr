import Foundation
import SwiftData
import TmbrCore

/// Rich, typed data for a song — for the detail screen and offline authoring.
/// Linked to its `PreviewRecord` by `previewID` (a plain UUID link, not a `@Relationship`, so
/// CloudKit mirroring stays trivial). Mirrors the backend `Song` / `SongResponse`.
///
@Model
public final class SongRecord {

    /// Links to `PreviewRecord.id` (the server PreviewID).
    public var previewID: UUID = UUID()

    /// Backing `SongID`. `nil` until the backend assigns one (offline-created songs).
    public var sourceID: Int?

    public var title: String = ""

    public var artist: String = ""

    public var album: String?

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
        album: String? = nil,
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
        self.album = album
        self.genre = genre
        self.releaseDate = releaseDate
        self.artworkURL = artworkURL
        self.resourceURLs = resourceURLs
        self.accessRaw = access.rawValue
        self.syncStateRaw = syncState.rawValue
    }
}

public extension SongRecord {
    var access: Access {
        get { Access(rawValue: accessRaw) ?? .private }
        set { accessRaw = newValue.rawValue }
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
