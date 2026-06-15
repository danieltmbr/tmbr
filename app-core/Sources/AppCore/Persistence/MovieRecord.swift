import Foundation
import SwiftData

/// Rich, typed data for a movie. Linked to its `PreviewRecord` by `previewID`.
/// Mirrors the backend `Movie` / `MovieResponse`.
@Model
public final class MovieRecord {

    public var previewID: UUID = UUID()
    public var sourceID: Int?

    public var title: String = ""
    public var director: String?
    public var genre: String?
    public var releaseDate: Date?
    public var coverURL: String?
    public var resourceURLs: [String] = []
    public var accessRaw: String = ""
    public var syncStateRaw: String = SyncState.synced.rawValue

    public init(
        previewID: UUID = UUID(),
        sourceID: Int? = nil,
        title: String = "",
        director: String? = nil,
        genre: String? = nil,
        releaseDate: Date? = nil,
        coverURL: String? = nil,
        resourceURLs: [String] = [],
        accessRaw: String = "",
        syncState: SyncState = .synced
    ) {
        self.previewID = previewID
        self.sourceID = sourceID
        self.title = title
        self.director = director
        self.genre = genre
        self.releaseDate = releaseDate
        self.coverURL = coverURL
        self.resourceURLs = resourceURLs
        self.accessRaw = accessRaw
        self.syncStateRaw = syncState.rawValue
    }
}

public extension MovieRecord {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
