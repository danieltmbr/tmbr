import Foundation
import SwiftData
import TmbrCore

/// Local representation of a catalogue category synced from the backend.
///
/// Categories are a global reference table: a fixed seed (song, album, book, movie, podcast,
/// playlist, and the virtual `music` grouping) plus user-generated `orphan` categories created
/// on demand from free-text item creation. They are never created on-device.
///
/// The natural key is `slug` (unique, stable). `serverID` (the backend integer PK) is stored for
/// reference but lookup always uses `slug`, matching the denormalised `categoryType` slug already
/// stored on `PreviewRecord`, `NoteRecord`, and `QuoteRecord`. There is intentionally no hard FK
/// between those records and `CatalogueCategoryRecord` — a new orphan category may not have synced
/// yet when its first item arrives; it self-heals on the next refresh.
///
@Model
public final class CatalogueCategoryRecord {

    /// Backend integer PK — stored for reference; not the join key.
    public var serverID: Int = 0

    /// Unique slug (e.g. `"song"`, `"music"`, `"recipe"`). This is the soft join key.
    public var slug: String = ""

    /// Human-readable display name (e.g. `"Songs"`, `"Music"`, `"Recipe"`).
    public var name: String = ""

    /// Raw value of `CatalogueCategoryKind`.
    var kindRaw: String = CatalogueCategoryKind.orphan.rawValue

    /// Web route segment (e.g. `"songs"`, `"music"`). May be nil for orphan categories.
    public var route: String?

    /// Icon name (e.g. `"song"`, `"link"`). Falls back to `"link"` in the UI when nil.
    public var icon: String?

    /// Slug of the parent grouping category (e.g. `"music"` for song/album/playlist). Nil for top-level.
    public var parentSlug: String?

    var syncStateRaw: String = SyncState.synced.rawValue

    public init() {}
}

// MARK: - Kind

public extension CatalogueCategoryRecord {

    var kind: CatalogueCategoryKind {
        get { CatalogueCategoryKind(rawValue: kindRaw) ?? .orphan }
        set { kindRaw = newValue.rawValue }
    }
}

// MARK: - SyncState

extension CatalogueCategoryRecord {

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}
