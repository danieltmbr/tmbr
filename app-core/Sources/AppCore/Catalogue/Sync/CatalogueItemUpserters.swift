import Foundation
import AppPersistence
import TmbrCore

/// The persistence injection seam for per-item catalogue sync.
///
/// Each property is a typed store-upsert closure. The default `init()` wires real upsert
/// methods; tests/previews can substitute a spy for one type while leaving the rest real.
///
/// Injected via `\.itemUpserters`. Read by `@Upserter` via the recipe.
public struct CatalogueItemUpserters: Sendable {

    public let album:    @MainActor (CatalogueStore, AlbumResponse) throws -> Void
    
    public let book:     @MainActor (CatalogueStore, BookResponse) throws -> Void
    
    public let movie:    @MainActor (CatalogueStore, MovieResponse) throws -> Void
    
    public let podcast:  @MainActor (CatalogueStore, PodcastResponse) throws -> Void
    
    public let playlist: @MainActor (CatalogueStore, PlaylistResponse) throws -> Void
    
    public let orphan:   @MainActor (CatalogueStore, PreviewResponse) throws -> Void
    
    public let song:     @MainActor (CatalogueStore, SongResponse) throws -> Void

    public init(
        album:    @escaping @MainActor (CatalogueStore, AlbumResponse) throws -> Void    = { try $0.upsert([$1]) },
        book:     @escaping @MainActor (CatalogueStore, BookResponse) throws -> Void     = { try $0.upsert([$1]) },
        movie:    @escaping @MainActor (CatalogueStore, MovieResponse) throws -> Void    = { try $0.upsert([$1]) },
        podcast:  @escaping @MainActor (CatalogueStore, PodcastResponse) throws -> Void  = { try $0.upsert([$1]) },
        playlist: @escaping @MainActor (CatalogueStore, PlaylistResponse) throws -> Void = { try $0.upsert([$1]) },
        orphan:   @escaping @MainActor (CatalogueStore, PreviewResponse) throws -> Void  = { try $0.upsertOrphans([$1]) },
        song:     @escaping @MainActor (CatalogueStore, SongResponse) throws -> Void     = { try $0.upsert([$1]) }
    ) {
        self.album = album
        self.book = book
        self.movie = movie
        self.podcast = podcast
        self.playlist = playlist
        self.orphan = orphan
        self.song = song
    }
}
