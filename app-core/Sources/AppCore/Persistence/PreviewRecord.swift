import Foundation
import SwiftData

/// The unified projection of every catalogue item — song, album, book, movie, podcast, playlist,
/// or orphan — mirroring the backend `Preview`.
///
/// This is what drives the **heterogeneous catalogue list** (one `@Query<PreviewRecord>`, sorted +
/// paginated) and the **note anchor**: notes attach to a catalogue item by this record's `id`
/// (the server PreviewID). Rich, type-specific data for detail + offline authoring lives in the
/// per-type records (`SongRecord`, `AlbumRecord`, …), linked back here by `previewID`.
///
/// - An **orphan** is a `PreviewRecord` with no backing per-type record (`sourceID == nil`).
/// - `id` is the **server PreviewID** (a UUID). No `@Attribute(.unique)` — CloudKit forbids it;
///   uniqueness is enforced by upsert (fetch-by-identity before insert).
///
@Model
public final class PreviewRecord {

    /// Server PreviewID. Stable cross-type identity; what tombstones and note attachments key on.
    public var id: UUID = UUID()

    /// Category slug — `"song" | "album" | "book" | "movie" | "podcast" | "playlist"` or an
    /// orphan/user-defined category. Mirrors `PreviewResponse.source.type`.
    public var categoryType: String = ""

    /// Int id of the backing catalogue model (Song, Book, …). `nil` for orphans and unpromoted
    /// (promotable) items. Mirrors `Preview.parentID`.
    public var sourceID: Int?

    /// Display title. Mirrors `PreviewResponse.primaryInfo`.
    public var primaryInfo: String = ""

    /// Display subtitle. Mirrors `PreviewResponse.secondaryInfo`.
    public var secondaryInfo: String?

    public var imageURL: String?

    /// External resource URLs. Mirrors `PreviewResponse.resources` / `Preview.externalLinks`.
    public var externalLinks: [String] = []

    var accessRaw: String = ""

    public var createdAt: Date = Date.now

    public var updatedAt: Date?

    var syncStateRaw: String = SyncState.synced.rawValue

    public init(
        id: UUID = UUID(),
        categoryType: String = "",
        sourceID: Int? = nil,
        primaryInfo: String = "",
        secondaryInfo: String? = nil,
        imageURL: String? = nil,
        externalLinks: [String] = [],
        access: Access = .private,
        createdAt: Date = .now,
        updatedAt: Date? = nil,
        syncState: SyncState = .synced
    ) {
        self.id = id
        self.categoryType = categoryType
        self.sourceID = sourceID
        self.primaryInfo = primaryInfo
        self.secondaryInfo = secondaryInfo
        self.imageURL = imageURL
        self.externalLinks = externalLinks
        self.accessRaw = access.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStateRaw = syncState.rawValue
    }
}

public extension PreviewRecord {
    var access: Access {
        get { Access(rawValue: accessRaw) ?? .private }
        set { accessRaw = newValue.rawValue }
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }

    /// An orphan has no backing per-type record.
    var isOrphan: Bool { sourceID == nil }
}
