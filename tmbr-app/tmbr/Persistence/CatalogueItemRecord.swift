import Foundation
import SwiftData

// MARK: - Base

/// Base SwiftData model for all catalogue items.
///
/// List-level fields are always populated during sync from `GET /api/catalogue/orphans`
/// or the per-type list endpoints. Detail-level fields start nil and are filled lazily
/// the first time a user opens the item's detail view.
///
/// The `subtitle` field serves list-display for all types. For typed items it mirrors
/// the semantic subclass field (e.g. `SongRecord.artist`) — both are populated at sync
/// time so the list view never needs to downcast.
///
/// SwiftData inheritance is available on iOS/macOS 26+. A single
/// `@Query var items: [CatalogueItemRecord]` returns all types; detail views
/// downcast to the concrete subclass for type-specific rendering.
@Model
class CatalogueItemRecord {

    @Attribute(.unique)
    var id: UUID               // PreviewID — the stable cross-type identifier

    var title: String          // PreviewResponse.primaryInfo
    var subtitle: String?      // PreviewResponse.secondaryInfo — used in list display
    var categoryType: String   // source.type slug: "song"|"album"|"book"|"movie"|"podcast"|"playlist"|user-defined
    var sourceID: Int?         // type-specific Int ID (SongID, AlbumID, …); nil for orphans
    var imageURL: String?
    var thumbnailURL: String?
    var lastFetchedAt: Date
    var syncStateRaw: String   // SyncState.rawValue

    // Detail-level — nil for orphans (preview IS their full data);
    // nil for typed items until the first detail fetch.
    var genre: String?
    var releaseDate: Date?
    var accessRaw: String?     // "private" | "public"
    var detailFetchedAt: Date?

    init(
        id: UUID,
        title: String,
        subtitle: String? = nil,
        categoryType: String,
        sourceID: Int? = nil,
        imageURL: String? = nil,
        thumbnailURL: String? = nil,
        lastFetchedAt: Date = .now,
        syncState: SyncState = .synced
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.categoryType = categoryType
        self.sourceID = sourceID
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.lastFetchedAt = lastFetchedAt
        self.syncStateRaw = syncState.rawValue
    }
}

extension CatalogueItemRecord {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}

// MARK: - Typed subclasses

/// Song — `subtitle` mirrors `artist`; `albumTitle` is detail-only.
@Model
final class SongRecord: CatalogueItemRecord {
    var artist: String?        // PreviewResponse.secondaryInfo → also in base.subtitle
    var albumTitle: String?    // SongResponse.album — detail only
}

/// Album — `subtitle` mirrors `artist`; `tracksJSON` is detail-only.
@Model
final class AlbumRecord: CatalogueItemRecord {
    var artist: String?
    var tracksJSON: Data?      // JSON-encoded [TrackItem] — detail only
}

/// Book — author is in `subtitle` and mirrored here for semantic clarity.
@Model
final class BookRecord: CatalogueItemRecord {
    var author: String?        // also in base.subtitle
}

/// Movie — director is in `subtitle` and mirrored here.
@Model
final class MovieRecord: CatalogueItemRecord {
    var director: String?      // also in base.subtitle
}

/// Podcast — host is in `subtitle`; episode/season are detail-only.
@Model
final class PodcastRecord: CatalogueItemRecord {
    var host: String?          // also in base.subtitle
    var episodeNumber: Int?    // detail only
    var seasonNumber: Int?     // detail only
}

/// Playlist — creator is in `subtitle`; description and tracks are detail-only.
@Model
final class PlaylistRecord: CatalogueItemRecord {
    var creator: String?       // also in base.subtitle
    var playlistDescription: String?   // detail only
    var tracksJSON: Data?              // JSON-encoded [TrackItem] — detail only
}

/// Orphan — user-defined items (recipe, guide, link, …) with no backing typed model.
/// `PreviewResponse` is their complete data; no additional fields are needed.
/// Identified by `sourceID == nil` and a user-defined `categoryType` slug.
@Model
final class OrphanRecord: CatalogueItemRecord {}
