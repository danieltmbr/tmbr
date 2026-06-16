import Foundation
import SwiftData

/// Rich, typed data for a book. Linked to its `PreviewRecord` by `previewID`.
/// Mirrors the backend `Book` / `BookResponse`.
///
@Model
public final class BookRecord {

    public var previewID: UUID = UUID()

    public var sourceID: Int?

    public var title: String = ""

    public var author: String = ""

    public var genre: String?

    public var releaseDate: Date?

    public var coverURL: String?

    public var resourceURLs: [String] = []

    var accessRaw: String = ""

    var syncStateRaw: String = SyncState.synced.rawValue

    public init(
        previewID: UUID = UUID(),
        sourceID: Int? = nil,
        title: String = "",
        author: String = "",
        genre: String? = nil,
        releaseDate: Date? = nil,
        coverURL: String? = nil,
        resourceURLs: [String] = [],
        access: Access = .private,
        syncState: SyncState = .synced
    ) {
        self.previewID = previewID
        self.sourceID = sourceID
        self.title = title
        self.author = author
        self.genre = genre
        self.releaseDate = releaseDate
        self.coverURL = coverURL
        self.resourceURLs = resourceURLs
        self.accessRaw = access.rawValue
        self.syncStateRaw = syncState.rawValue
    }
}

public extension BookRecord {
    var access: Access {
        get { Access(rawValue: accessRaw) ?? .private }
        set { accessRaw = newValue.rawValue }
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
