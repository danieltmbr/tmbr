import Foundation
import AppApi
import TmbrCore

/// Links the loader factory and store upsert function for one catalogue item type.
///
/// `@Loader(\.song)` reads `\.itemLoaders` directly (no recipe needed).
/// `@Upserter(\.song)` keys into this recipe to find both `loaderPath` and `upserterPath`,
/// ensuring the loader output type always matches the upserter input type at compile time.
public struct CatalogueItemSync<ID: Sendable, Response: Decodable & Sendable>: Sendable {

    public let label: String
    public let loaderPath:   KeyPath<CatalogueItemLoaders,   @Sendable (URL, URLSession) -> RequestLoader<ID, Response>> & Sendable
    public let upserterPath: KeyPath<CatalogueItemUpserters, @MainActor (CatalogueStore, Response) throws -> Void> & Sendable

    public init(
        _ label: String,
        loaderPath:   KeyPath<CatalogueItemLoaders,   @Sendable (URL, URLSession) -> RequestLoader<ID, Response>> & Sendable,
        upserterPath: KeyPath<CatalogueItemUpserters, @MainActor (CatalogueStore, Response) throws -> Void> & Sendable
    ) {
        self.label = label
        self.loaderPath = loaderPath
        self.upserterPath = upserterPath
    }
}

// MARK: - Namespace

/// Keypath-pair recipes linking each catalogue type's loader factory to its store upsert function.
///
/// `@Upserter` addresses into this namespace to compose the two seams. The network seam
/// (`\.itemLoaders`) and persistence seam (`\.itemUpserters`) are each independently injectable
/// via the environment; overriding one does not affect the other.
public struct CatalogueItemSyncs: Sendable {

    public let song:     CatalogueItemSync<Int,  SongResponse>
    public let album:    CatalogueItemSync<Int,  AlbumResponse>
    public let book:     CatalogueItemSync<Int,  BookResponse>
    public let movie:    CatalogueItemSync<Int,  MovieResponse>
    public let podcast:  CatalogueItemSync<Int,  PodcastResponse>
    public let playlist: CatalogueItemSync<Int,  PlaylistResponse>
    public let orphan:   CatalogueItemSync<UUID, PreviewResponse>

    public init() {
        song     = .init("song",     loaderPath: \.song,     upserterPath: \.song)
        album    = .init("album",    loaderPath: \.album,    upserterPath: \.album)
        book     = .init("book",     loaderPath: \.book,     upserterPath: \.book)
        movie    = .init("movie",    loaderPath: \.movie,    upserterPath: \.movie)
        podcast  = .init("podcast",  loaderPath: \.podcast,  upserterPath: \.podcast)
        playlist = .init("playlist", loaderPath: \.playlist, upserterPath: \.playlist)
        orphan   = .init("orphan",   loaderPath: \.orphan,   upserterPath: \.orphan)
    }
}
