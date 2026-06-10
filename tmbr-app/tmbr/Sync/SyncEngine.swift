import Foundation
import SwiftData
import TmbrCore
import ApiKit

/// Orchestrates sync between the backend API and the local SwiftData store.
///
/// Data flow (pull): network response → upsert into ModelContext → @Query in views auto-updates.
/// Data flow (push): SwiftData record (.pendingCreate/.pendingUpdate/.pendingDelete) → HTTP call → mark .synced.
@MainActor
final class SyncEngine {

    private let authState: AuthState
    private let modelContext: ModelContext
    private let baseURL: URL

    private let lastSyncAtKey = "SyncEngine.lastSyncAt"
    private var lastSyncAt: Date? {
        get { UserDefaults.standard.object(forKey: lastSyncAtKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastSyncAtKey) }
    }

    init(authState: AuthState, modelContext: ModelContext, baseURL: URL) {
        self.authState = authState
        self.modelContext = modelContext
        self.baseURL = baseURL
    }

    // MARK: - Public interface

    /// Full cycle: push pending local changes, then delta-pull from server.
    /// Called on every foreground activation and explicit refresh.
    func runSync() async throws {
        try await pushPendingPosts()
        try await pushPendingNotes()
        try await syncDelta()
    }

    /// Pull-only delta sync. Fetches items newer than `lastSyncAt`.
    func syncDelta() async throws {
        let since = lastSyncAt
        try await fetchAll(since: since)
        lastSyncAt = .now
    }

    /// Pull-only full sync. Fetches all history regardless of last sync.
    func syncFull() async throws {
        try await fetchAll(since: nil)
        lastSyncAt = .now
    }

    // MARK: - Push

    // MARK: - Load more (older history)

    /// Fetches one page of posts older than the oldest currently stored post.
    /// Returns `true` if even older posts remain.
    @discardableResult
    func fetchOlderPosts() async throws -> Bool {
        let descriptor = FetchDescriptor<PostRecord>(
            sortBy: [SortDescriptor(\PostRecord.createdAt, order: .forward)]
        )
        guard let oldest = (try? modelContext.fetch(descriptor))?.first?.createdAt else {
            return false
        }
        let cursor = ISO8601DateFormatter().string(from: oldest)
        let query = PageQuery(cursor: cursor, limit: 50)
        let loader = authState.loader(for: BasicRequest<PageQuery, PageResult<PostResponse>>.query(
            baseURL: baseURL, path: "/api/posts"
        ))
        let page = try await loader.load(from: query)
        mergePosts(page.items)
        return page.hasMore
    }

    /// Fetches one page of catalogue items older than the oldest currently stored item, across all types.
    /// Returns `true` if even older items remain in any type.
    @discardableResult
    func fetchOlderCatalogueItems() async throws -> Bool {
        let descriptor = FetchDescriptor<CatalogueItemRecord>(
            sortBy: [SortDescriptor(\CatalogueItemRecord.lastFetchedAt, order: .forward)]
        )
        guard let oldest = (try? modelContext.fetch(descriptor))?.first?.lastFetchedAt else {
            return false
        }
        let cursor = ISO8601DateFormatter().string(from: oldest)
        let query = PageQuery(cursor: cursor, limit: 50)

        async let songs    = authState.loader(for: BasicRequest<PageQuery, PageResult<SongResponse>>.query(baseURL: baseURL, path: "/api/songs")).load(from: query)
        async let albums   = authState.loader(for: BasicRequest<PageQuery, PageResult<AlbumResponse>>.query(baseURL: baseURL, path: "/api/albums")).load(from: query)
        async let books    = authState.loader(for: BasicRequest<PageQuery, PageResult<BookResponse>>.query(baseURL: baseURL, path: "/api/books")).load(from: query)
        async let movies   = authState.loader(for: BasicRequest<PageQuery, PageResult<MovieResponse>>.query(baseURL: baseURL, path: "/api/movies")).load(from: query)
        async let podcasts = authState.loader(for: BasicRequest<PageQuery, PageResult<PodcastResponse>>.query(baseURL: baseURL, path: "/api/podcasts")).load(from: query)
        async let playlists = authState.loader(for: BasicRequest<PageQuery, PageResult<PlaylistResponse>>.query(baseURL: baseURL, path: "/api/playlists")).load(from: query)

        let (s, al, b, mv, po, pl) = try await (songs, albums, books, movies, podcasts, playlists)
        upsertCatalogueItems(songs: s.items, albums: al.items, books: b.items, movies: mv.items, podcasts: po.items, playlists: pl.items)

        return s.hasMore || al.hasMore || b.hasMore || mv.hasMore || po.hasMore || pl.hasMore
    }

    // MARK: - Push

    func pushPendingNotes() async throws {
        let descriptor = FetchDescriptor<NoteRecord>(
            predicate: #Predicate { $0.syncStateRaw != "synced" }
        )
        let pending = (try? modelContext.fetch(descriptor)) ?? []
        for record in pending {
            try await pushNote(record)
        }
    }

    func pushPendingPosts() async throws {
        let descriptor = FetchDescriptor<PostRecord>(
            predicate: #Predicate { $0.syncStateRaw != "synced" }
        )
        let pending = (try? modelContext.fetch(descriptor)) ?? []
        for record in pending {
            try await pushPost(record)
        }
    }

    private func pushNote(_ record: NoteRecord) async throws {
        let input = NoteInput(
            body: record.body,
            access: Access(rawValue: record.accessRaw) ?? .private,
            language: Language(rawValue: record.languageRaw) ?? .en
        )
        switch record.syncState {
        case .pendingCreate:
            guard let previewID = record.attachmentPreviewID else { return }
            let loader = authState.loader(for: BasicRequest<NoteInput, NoteResponse>.post(
                baseURL: baseURL, path: "/api/catalogue/item/\(previewID)/notes"
            ))
            let response = try await loader.load(from: input)
            record.serverID = response.id
            record.syncState = .synced
        case .pendingUpdate:
            guard let serverID = record.serverID else { return }
            let loader = authState.loader(for: BasicRequest<NoteInput, NoteResponse>.put(
                baseURL: baseURL, path: "/api/notes/\(serverID)"
            ))
            _ = try await loader.load(from: input)
            record.syncState = .synced
        case .pendingDelete:
            if let serverID = record.serverID {
                let loader = authState.loader(for: BasicRequest<Void, NoContent>.delete(
                    baseURL: baseURL, path: "/api/notes/\(serverID)"
                ))
                _ = try await loader.load()
            }
            modelContext.delete(record)
        case .synced:
            break
        }
    }

    private func pushPost(_ record: PostRecord) async throws {
        let input = PostInput(
            title: record.title,
            body: record.content,
            state: PostState(rawValue: record.stateRaw) ?? .draft,
            language: Language(rawValue: record.languageRaw) ?? .en
        )
        switch record.syncState {
        case .pendingCreate:
            let loader = authState.loader(for: BasicRequest<PostInput, PostResponse>.post(
                baseURL: baseURL, path: "/api/posts"
            ))
            let response = try await loader.load(from: input)
            record.serverID = response.id
            record.syncState = .synced
        case .pendingUpdate:
            guard let serverID = record.serverID else { return }
            let loader = authState.loader(for: BasicRequest<PostInput, PostResponse>.put(
                baseURL: baseURL, path: "/api/posts/\(serverID)"
            ))
            _ = try await loader.load(from: input)
            record.syncState = .synced
        case .pendingDelete:
            if let serverID = record.serverID {
                let loader = authState.loader(for: BasicRequest<Void, NoContent>.delete(
                    baseURL: baseURL, path: "/api/posts/\(serverID)"
                ))
                _ = try await loader.load()
            }
            modelContext.delete(record)
        case .synced:
            break
        }
    }

    // MARK: - Parallel fetch

    private func fetchAll(since: Date?) async throws {
        async let notes     = fetchNotes(since: since)
        async let posts     = fetchPosts(since: since)
        async let songs     = fetchSongs(since: since)
        async let albums    = fetchAlbums(since: since)
        async let books     = fetchBooks(since: since)
        async let movies    = fetchMovies(since: since)
        async let podcasts  = fetchPodcasts(since: since)
        async let playlists = fetchPlaylists(since: since)
        async let orphans   = fetchOrphans(since: since)

        let (n, p, s, al, b, mv, po, pl, or) = try await (
            notes, posts, songs, albums, books, movies, podcasts, playlists, orphans
        )

        upsertNotes(n)
        upsertPosts(p)
        upsertCatalogueItems(songs: s, albums: al, books: b, movies: mv, podcasts: po, playlists: pl)
        upsertOrphans(or)
    }

    // MARK: - Network fetch helpers

    private func fetchAll<T: Decodable & Sendable>(
        loader: RequestLoader<BasicRequest<PageQuery, PageResult<T>>>,
        since: Date?
    ) async throws -> [T] {
        var all: [T] = []
        var cursor: String? = nil
        var hasMore = true
        while hasMore {
            let query = PageQuery(since: all.isEmpty ? since : nil, cursor: cursor, limit: 50)
            let page = try await loader.load(from: query)
            all.append(contentsOf: page.items)
            cursor = page.nextCursor
            hasMore = page.hasMore
        }
        return all
    }

    private func fetchNotes(since: Date?) async throws -> [NoteResponse] {
        try await fetchAll(
            loader: authState.loader(for: BasicRequest<PageQuery, PageResult<NoteResponse>>.query(baseURL: baseURL, path: "/api/notes")),
            since: since
        )
    }

    private func fetchPosts(since: Date?) async throws -> [PostResponse] {
        try await fetchAll(
            loader: authState.loader(for: BasicRequest<PageQuery, PageResult<PostResponse>>.query(baseURL: baseURL, path: "/api/posts")),
            since: since
        )
    }

    private func fetchSongs(since: Date?) async throws -> [SongResponse] {
        try await fetchAll(
            loader: authState.loader(for: BasicRequest<PageQuery, PageResult<SongResponse>>.query(baseURL: baseURL, path: "/api/songs")),
            since: since
        )
    }

    private func fetchAlbums(since: Date?) async throws -> [AlbumResponse] {
        try await fetchAll(
            loader: authState.loader(for: BasicRequest<PageQuery, PageResult<AlbumResponse>>.query(baseURL: baseURL, path: "/api/albums")),
            since: since
        )
    }

    private func fetchBooks(since: Date?) async throws -> [BookResponse] {
        try await fetchAll(
            loader: authState.loader(for: BasicRequest<PageQuery, PageResult<BookResponse>>.query(baseURL: baseURL, path: "/api/books")),
            since: since
        )
    }

    private func fetchMovies(since: Date?) async throws -> [MovieResponse] {
        try await fetchAll(
            loader: authState.loader(for: BasicRequest<PageQuery, PageResult<MovieResponse>>.query(baseURL: baseURL, path: "/api/movies")),
            since: since
        )
    }

    private func fetchPodcasts(since: Date?) async throws -> [PodcastResponse] {
        try await fetchAll(
            loader: authState.loader(for: BasicRequest<PageQuery, PageResult<PodcastResponse>>.query(baseURL: baseURL, path: "/api/podcasts")),
            since: since
        )
    }

    private func fetchPlaylists(since: Date?) async throws -> [PlaylistResponse] {
        try await fetchAll(
            loader: authState.loader(for: BasicRequest<PageQuery, PageResult<PlaylistResponse>>.query(baseURL: baseURL, path: "/api/playlists")),
            since: since
        )
    }

    private func fetchOrphans(since: Date?) async throws -> [PreviewResponse] {
        try await fetchAll(
            loader: authState.loader(for: BasicRequest<PageQuery, PageResult<PreviewResponse>>.query(baseURL: baseURL, path: "/api/catalogue/orphans")),
            since: since
        )
    }

    // MARK: - Upsert helpers

    private func upsertNotes(_ responses: [NoteResponse]) {
        let serverIDs = Set(responses.map(\.id))

        // Delete synced records absent from the server response
        let allSynced = (try? modelContext.fetch(FetchDescriptor<NoteRecord>())) ?? []
        for record in allSynced {
            guard let sid = record.serverID, record.syncState == .synced else { continue }
            if !serverIDs.contains(sid) { modelContext.delete(record) }
        }

        let existing = Dictionary(
            uniqueKeysWithValues: allSynced.compactMap { r in r.serverID.map { ($0, r) } }
        )

        for response in responses {
            if let record = existing[response.id] {
                guard record.syncState == .synced else { continue }
                record.body = response.body
                record.accessRaw = response.access.rawValue
                record.languageRaw = response.language.rawValue
                record.createdAt = response.created
                record.attachmentTitle = response.attachment.primaryInfo
                record.attachmentSubtitle = response.attachment.secondaryInfo
                record.attachmentCategoryType = response.attachment.source.type
                record.attachmentSourceID = response.attachment.source.id
            } else {
                let record = NoteRecord(
                    serverID: response.id,
                    body: response.body,
                    accessRaw: response.access.rawValue,
                    languageRaw: response.language.rawValue,
                    createdAt: response.created,
                    syncState: .synced,
                    attachmentTitle: response.attachment.primaryInfo,
                    attachmentSubtitle: response.attachment.secondaryInfo,
                    attachmentCategoryType: response.attachment.source.type,
                    attachmentSourceID: response.attachment.source.id
                )
                modelContext.insert(record)
            }
        }
    }

    /// Insert/update posts without deleting records absent from the response.
    /// Used for load-more where the response is a partial page, not the full dataset.
    private func mergePosts(_ responses: [PostResponse]) {
        let allSynced = (try? modelContext.fetch(FetchDescriptor<PostRecord>())) ?? []
        let existing = Dictionary(
            uniqueKeysWithValues: allSynced.compactMap { r in r.serverID.map { ($0, r) } }
        )
        for response in responses {
            guard let responseID = response.id else { continue }
            if let record = existing[responseID] {
                guard record.syncState == .synced else { continue }
                record.title = response.title
                record.content = response.content
                record.stateRaw = response.state.rawValue
                record.languageRaw = response.language.rawValue
                record.createdAt = response.createdAt
                record.publishedAt = response.publishedAt
            } else {
                let record = PostRecord(
                    serverID: responseID,
                    title: response.title,
                    content: response.content,
                    stateRaw: response.state.rawValue,
                    languageRaw: response.language.rawValue,
                    createdAt: response.createdAt,
                    publishedAt: response.publishedAt,
                    syncState: .synced
                )
                modelContext.insert(record)
            }
        }
    }

    private func upsertPosts(_ responses: [PostResponse]) {
        let serverIDs = Set(responses.compactMap(\.id))
        let allSynced = (try? modelContext.fetch(FetchDescriptor<PostRecord>())) ?? []
        for record in allSynced {
            guard let sid = record.serverID, record.syncState == .synced else { continue }
            if !serverIDs.contains(sid) { modelContext.delete(record) }
        }
        let existing = Dictionary(
            uniqueKeysWithValues: allSynced.compactMap { r in r.serverID.map { ($0, r) } }
        )
        for response in responses {
            guard let responseID = response.id else { continue }
            if let record = existing[responseID] {
                guard record.syncState == .synced else { continue }
                record.title = response.title
                record.content = response.content
                record.stateRaw = response.state.rawValue
                record.languageRaw = response.language.rawValue
                record.createdAt = response.createdAt
                record.publishedAt = response.publishedAt
            } else {
                let record = PostRecord(
                    serverID: responseID,
                    title: response.title,
                    content: response.content,
                    stateRaw: response.state.rawValue,
                    languageRaw: response.language.rawValue,
                    createdAt: response.createdAt,
                    publishedAt: response.publishedAt,
                    syncState: .synced
                )
                modelContext.insert(record)
            }
        }
    }

    private func upsertCatalogueItems(
        songs: [SongResponse], albums: [AlbumResponse], books: [BookResponse],
        movies: [MovieResponse], podcasts: [PodcastResponse], playlists: [PlaylistResponse]
    ) {
        upsertTyped(songs,     type: "song")     { SongRecord(song: $0) }
        upsertTyped(albums,    type: "album")    { AlbumRecord(album: $0) }
        upsertTyped(books,     type: "book")     { BookRecord(book: $0) }
        upsertTyped(movies,    type: "movie")    { MovieRecord(movie: $0) }
        upsertTyped(podcasts,  type: "podcast")  { PodcastRecord(podcast: $0) }
        upsertTyped(playlists, type: "playlist") { PlaylistRecord(playlist: $0) }
    }

    private func upsertTyped<T: CatalogueItemResponse, R: CatalogueItemRecord>(
        _ responses: [T],
        type categoryType: String,
        make: (T) -> R
    ) {
        let all = (try? modelContext.fetch(FetchDescriptor<R>())) ?? []
        let existing = Dictionary(uniqueKeysWithValues: all.compactMap { r in r.sourceID.map { ($0, r) } })
        for response in responses {
            guard let sourceID = response.sourceID else { continue }
            if let record = existing[sourceID] {
                response.apply(to: record)
            } else {
                let record = make(response)
                modelContext.insert(record)
            }
        }
    }

    private func upsertOrphans(_ responses: [PreviewResponse]) {
        let all = (try? modelContext.fetch(FetchDescriptor<OrphanRecord>())) ?? []
        // Orphans are identified by sourceType (their category slug) + primaryInfo
        // since they have no backing model Int ID. For simplicity, use primaryInfo as key.
        let existing = Dictionary(grouping: all, by: \.title).compactMapValues(\.first)
        for response in responses {
            if existing[response.primaryInfo] == nil {
                let record = OrphanRecord(
                    id: UUID(),
                    title: response.primaryInfo,
                    subtitle: response.secondaryInfo,
                    categoryType: response.source.type,
                    imageURL: response.image?.url,
                    thumbnailURL: response.image?.thumbnailUrl
                )
                modelContext.insert(record)
            }
        }
    }
}

// MARK: - Protocol for typed catalogue item upsert

private protocol CatalogueItemResponse {
    var sourceID: Int? { get }
    var title: String { get }
    var subtitle: String? { get }
    var imageURL: String? { get }
    var thumbnailURL: String? { get }
    var genre: String? { get }
    var releaseDate: Date? { get }
    func apply(to record: CatalogueItemRecord)
}

extension SongResponse: CatalogueItemResponse {
    var sourceID: Int? { id }
    var subtitle: String? { artist }
    var imageURL: String? { artwork?.url }
    var thumbnailURL: String? { artwork?.thumbnailUrl }
    var genre: String? { genre }
    var releaseDate: Date? { releaseDate }
    func apply(to record: CatalogueItemRecord) {
        record.title = title
        record.subtitle = artist
        record.imageURL = artwork?.url
        record.thumbnailURL = artwork?.thumbnailUrl
        record.genre = genre
        record.releaseDate = releaseDate
        record.accessRaw = access.rawValue
        record.lastFetchedAt = .now
        if let r = record as? SongRecord { r.artist = artist; r.albumTitle = album }
    }
}

extension AlbumResponse: CatalogueItemResponse {
    var sourceID: Int? { id }
    var subtitle: String? { artist }
    var imageURL: String? { artwork?.url }
    var thumbnailURL: String? { artwork?.thumbnailUrl }
    func apply(to record: CatalogueItemRecord) {
        record.title = title; record.subtitle = artist
        record.imageURL = artwork?.url; record.thumbnailURL = artwork?.thumbnailUrl
        record.genre = genre; record.releaseDate = releaseDate
        record.accessRaw = access.rawValue; record.lastFetchedAt = .now
        if let r = record as? AlbumRecord { r.artist = artist }
    }
}

extension BookResponse: CatalogueItemResponse {
    var sourceID: Int? { id }
    var subtitle: String? { author }
    var imageURL: String? { cover?.url }
    var thumbnailURL: String? { cover?.thumbnailUrl }
    func apply(to record: CatalogueItemRecord) {
        record.title = title; record.subtitle = author
        record.imageURL = cover?.url; record.thumbnailURL = cover?.thumbnailUrl
        record.genre = genre; record.releaseDate = releaseDate
        record.accessRaw = access.rawValue; record.lastFetchedAt = .now
        if let r = record as? BookRecord { r.author = author }
    }
}

extension MovieResponse: CatalogueItemResponse {
    var sourceID: Int? { id }
    var subtitle: String? { director }
    var imageURL: String? { cover?.url }
    var thumbnailURL: String? { cover?.thumbnailUrl }
    func apply(to record: CatalogueItemRecord) {
        record.title = title; record.subtitle = director
        record.imageURL = cover?.url; record.thumbnailURL = cover?.thumbnailUrl
        record.genre = genre; record.releaseDate = releaseDate
        record.accessRaw = access.rawValue; record.lastFetchedAt = .now
        if let r = record as? MovieRecord { r.director = director }
    }
}

extension PodcastResponse: CatalogueItemResponse {
    var sourceID: Int? { id }
    var subtitle: String? { nil }
    var imageURL: String? { artwork?.url }
    var thumbnailURL: String? { artwork?.thumbnailUrl }
    func apply(to record: CatalogueItemRecord) {
        record.title = title
        record.imageURL = artwork?.url; record.thumbnailURL = artwork?.thumbnailUrl
        record.genre = genre; record.releaseDate = releaseDate
        record.accessRaw = access.rawValue; record.lastFetchedAt = .now
    }
}

extension PlaylistResponse: CatalogueItemResponse {
    var sourceID: Int? { id }
    var subtitle: String? { nil }
    var imageURL: String? { artwork?.url }
    var thumbnailURL: String? { artwork?.thumbnailUrl }
    var genre: String? { nil }
    var releaseDate: Date? { nil }
    func apply(to record: CatalogueItemRecord) {
        record.title = title
        record.imageURL = artwork?.url; record.thumbnailURL = artwork?.thumbnailUrl
        record.accessRaw = access.rawValue; record.lastFetchedAt = .now
    }
}

// MARK: - CatalogueItemRecord convenience inits for typed responses

private extension SongRecord {
    convenience init(song: SongResponse) {
        self.init(id: UUID(), title: song.title, subtitle: song.artist,
                  categoryType: "song", sourceID: song.id,
                  imageURL: song.artwork?.url, thumbnailURL: song.artwork?.thumbnailUrl,
                  syncState: .synced)
        self.artist = song.artist; self.albumTitle = song.album
        self.genre = song.genre; self.releaseDate = song.releaseDate
        self.accessRaw = song.access.rawValue; self.detailFetchedAt = .now
    }
}

private extension AlbumRecord {
    convenience init(album: AlbumResponse) {
        self.init(id: UUID(), title: album.title, subtitle: album.artist,
                  categoryType: "album", sourceID: album.id,
                  imageURL: album.artwork?.url, thumbnailURL: album.artwork?.thumbnailUrl,
                  syncState: .synced)
        self.artist = album.artist
        self.genre = album.genre; self.releaseDate = album.releaseDate
        self.accessRaw = album.access.rawValue; self.detailFetchedAt = .now
    }
}

private extension BookRecord {
    convenience init(book: BookResponse) {
        self.init(id: UUID(), title: book.title, subtitle: book.author,
                  categoryType: "book", sourceID: book.id,
                  imageURL: book.cover?.url, thumbnailURL: book.cover?.thumbnailUrl,
                  syncState: .synced)
        self.author = book.author
        self.genre = book.genre; self.releaseDate = book.releaseDate
        self.accessRaw = book.access.rawValue; self.detailFetchedAt = .now
    }
}

private extension MovieRecord {
    convenience init(movie: MovieResponse) {
        self.init(id: UUID(), title: movie.title, subtitle: movie.director,
                  categoryType: "movie", sourceID: movie.id,
                  imageURL: movie.cover?.url, thumbnailURL: movie.cover?.thumbnailUrl,
                  syncState: .synced)
        self.director = movie.director
        self.genre = movie.genre; self.releaseDate = movie.releaseDate
        self.accessRaw = movie.access.rawValue; self.detailFetchedAt = .now
    }
}

private extension PodcastRecord {
    convenience init(podcast: PodcastResponse) {
        self.init(id: UUID(), title: podcast.title,
                  categoryType: "podcast", sourceID: podcast.id,
                  imageURL: podcast.artwork?.url, thumbnailURL: podcast.artwork?.thumbnailUrl,
                  syncState: .synced)
        self.genre = podcast.genre
        self.accessRaw = podcast.access.rawValue; self.detailFetchedAt = .now
    }
}

private extension PlaylistRecord {
    convenience init(playlist: PlaylistResponse) {
        self.init(id: UUID(), title: playlist.title,
                  categoryType: "playlist", sourceID: playlist.id,
                  imageURL: playlist.artwork?.url, thumbnailURL: playlist.artwork?.thumbnailUrl,
                  syncState: .synced)
        self.playlistDescription = playlist.description
        self.accessRaw = playlist.access.rawValue; self.detailFetchedAt = .now
    }
}

// MARK: - Push payload types

private struct NoteInput: Encodable, Sendable {
    let body: String
    let access: Access
    let language: Language
}

private struct PostInput: Encodable, Sendable {
    let title: String
    let body: String       // "body" matches the backend PostPayload field name
    let state: PostState
    let language: Language
}

/// Response type for endpoints that return HTTP 204 No Content.
private struct NoContent: Decodable, Sendable {
    init(from decoder: any Decoder) throws {}
}
