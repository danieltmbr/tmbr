import Foundation
import SwiftData
import CoreTmbr

/// Rich, typed data for a podcast episode. Linked to its `PreviewRecord` by `previewID`.
/// Mirrors the backend `Podcast` / `PodcastResponse`.
///
@Model
public final class PodcastRecord {

    public var previewID: UUID = UUID()

    public var sourceID: Int?

    public var title: String = ""

    public var episodeTitle: String = ""

    public var episodeNumber: Int?

    public var seasonNumber: Int?

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
        episodeTitle: String = "",
        episodeNumber: Int? = nil,
        seasonNumber: Int? = nil,
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
        self.episodeTitle = episodeTitle
        self.episodeNumber = episodeNumber
        self.seasonNumber = seasonNumber
        self.genre = genre
        self.releaseDate = releaseDate
        self.artworkURL = artworkURL
        self.resourceURLs = resourceURLs
        self.accessRaw = access.rawValue
        self.syncStateRaw = syncState.rawValue
    }
}

public extension PodcastRecord {
    var access: Access {
        get { Access(rawValue: accessRaw) ?? .private }
        set { accessRaw = newValue.rawValue }
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
