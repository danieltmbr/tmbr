import Foundation
import OSLog
import SwiftData
import CoreApi
import CoreApp
import CoreTmbr

/// Reader's lazy data-in for the catalogue: fetch every public per-type list + orphans
/// (unauthenticated, in parallel), then upsert into the local store. `@Query<PreviewRecord>` renders
/// the unified result. No tombstones, no `since` — most-recent page, stale-while-revalidate.
@MainActor
final class ReaderCatalogue {

    private let baseURL: URL

    private let store: CatalogueStore

    private let logger = Logger(subsystem: "me.tmbr", category: "sync")

    init(baseURL: URL, store: CatalogueStore) {
        self.baseURL = baseURL
        self.store = store
    }

    func refresh() async throws {
        let session = URLSession.shared
        let page = PageQuery(limit: 50)

        async let songs = RequestLoader(request: SongsRequest.songQuery(baseURL: baseURL), session: session).load(from: page)
        async let albums = RequestLoader(request: AlbumsRequest.albumQuery(baseURL: baseURL), session: session).load(from: page)
        async let books = RequestLoader(request: BooksRequest.bookQuery(baseURL: baseURL), session: session).load(from: page)
        async let movies = RequestLoader(request: MoviesRequest.movieQuery(baseURL: baseURL), session: session).load(from: page)
        async let podcasts = RequestLoader(request: PodcastsRequest.podcastQuery(baseURL: baseURL), session: session).load(from: page)
        async let playlists = RequestLoader(request: PlaylistsRequest.playlistQuery(baseURL: baseURL), session: session).load(from: page)
        async let orphans = RequestLoader(request: OrphansRequest.orphanQuery(baseURL: baseURL), session: session).load(from: OrphanPageQuery(limit: 50))

        try store.upsert(try await songs.items)
        try store.upsert(try await albums.items)
        try store.upsert(try await books.items)
        try store.upsert(try await movies.items)
        try store.upsert(try await podcasts.items)
        try store.upsert(try await playlists.items)
        try store.upsertOrphans(try await orphans.items)

        logger.info("Catalogue refresh: upserted all catalogue types")
    }
}
