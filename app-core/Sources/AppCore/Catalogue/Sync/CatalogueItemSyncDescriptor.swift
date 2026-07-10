import Foundation
import AppPersistence
import AppApi
import TmbrCore

/// Links the loader factory and store upsert function for one catalogue item type.
///
/// `@Loader(\.song)` reads `\.itemLoaders` directly (no recipe needed).
/// `@Upserter(\.song)` keys into this recipe to find both `loaderPath` and `upserterPath`,
/// ensuring the loader output type always matches the upserter input type at compile time.
public struct CatalogueItemSyncDescriptor<ID: Sendable, Response: Decodable & Sendable>: Sendable {

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

extension CatalogueItemSyncDescriptor where ID == Int, Response == SongResponse {
    
    public static let song = Self("song", loaderPath: \.song, upserterPath: \.song)
}
    
extension CatalogueItemSyncDescriptor where ID == Int, Response == AlbumResponse {
    
    public static let album = Self("album", loaderPath: \.album, upserterPath: \.album)
}

extension CatalogueItemSyncDescriptor where ID == Int, Response == BookResponse {

    public static let book = Self("book", loaderPath: \.book, upserterPath: \.book)
}
    
extension CatalogueItemSyncDescriptor where ID == Int, Response == MovieResponse {
    
    public static let movie = Self("movie", loaderPath: \.movie, upserterPath: \.movie)
}
   
extension CatalogueItemSyncDescriptor where ID == Int, Response == PodcastResponse {
    
    public static let podcast = Self("podcast", loaderPath: \.podcast, upserterPath: \.podcast)
}
    
extension CatalogueItemSyncDescriptor where ID == Int, Response == PlaylistResponse {
    
    public static let playlist = Self("playlist", loaderPath: \.playlist, upserterPath: \.playlist)
}
    
extension CatalogueItemSyncDescriptor where ID == UUID, Response == PreviewResponse {

    public static let orphan = Self( "orphan", loaderPath: \.orphan, upserterPath: \.orphan)
}
