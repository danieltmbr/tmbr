import Foundation
import SwiftData

/// Rich, typed data for a podcast episode. Linked to its `PreviewRecord` by `previewID`.
/// Mirrors the backend `Podcast` / `PodcastResponse`.
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
    public var accessRaw: String = ""
    public var syncStateRaw: String = SyncState.synced.rawValue

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
        accessRaw: String = "",
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
        self.accessRaw = accessRaw
        self.syncStateRaw = syncState.rawValue
    }
}

public extension PodcastRecord {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
