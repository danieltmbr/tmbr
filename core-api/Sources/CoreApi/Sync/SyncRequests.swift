import Foundation
import CoreTmbr

// Per-endpoint query requests for native catalogue/blog sync. The request is just the query endpoint;
// the "sync" behaviour (walking every page) lives on `RequestLoader.syncAll`. See `SyncLoaders.swift`
// for the matching loader factories.
//
// Each per-type list response embeds its `.notes` and its `.preview.id`.

public typealias SongsRequest = BasicRequest<PageQuery, PageResult<SongResponse>>
public extension Request where Self == SongsRequest {
    static func songQuery(baseURL: URL) -> Self { .query(baseURL: baseURL, path: "api/songs") }
}

public typealias AlbumsRequest = BasicRequest<PageQuery, PageResult<AlbumResponse>>
public extension Request where Self == AlbumsRequest {
    static func albumQuery(baseURL: URL) -> Self { .query(baseURL: baseURL, path: "api/albums") }
}

public typealias BooksRequest = BasicRequest<PageQuery, PageResult<BookResponse>>
public extension Request where Self == BooksRequest {
    static func bookQuery(baseURL: URL) -> Self { .query(baseURL: baseURL, path: "api/books") }
}

public typealias MoviesRequest = BasicRequest<PageQuery, PageResult<MovieResponse>>
public extension Request where Self == MoviesRequest {
    static func movieQuery(baseURL: URL) -> Self { .query(baseURL: baseURL, path: "api/movies") }
}

public typealias PodcastsRequest = BasicRequest<PageQuery, PageResult<PodcastResponse>>
public extension Request where Self == PodcastsRequest {
    static func podcastQuery(baseURL: URL) -> Self { .query(baseURL: baseURL, path: "api/podcasts") }
}

public typealias PlaylistsRequest = BasicRequest<PageQuery, PageResult<PlaylistResponse>>
public extension Request where Self == PlaylistsRequest {
    static func playlistQuery(baseURL: URL) -> Self { .query(baseURL: baseURL, path: "api/playlists") }
}

public typealias PostsRequest = BasicRequest<PageQuery, PageResult<PostResponse>>
public extension Request where Self == PostsRequest {
    static func postQuery(baseURL: URL) -> Self { .query(baseURL: baseURL, path: "api/posts") }
}

/// Orphans are sent with `?notes=true` so each orphan carries its embedded notes.
public typealias OrphansRequest = BasicRequest<OrphanPageQuery, PageResult<PreviewResponse>>
public extension Request where Self == OrphansRequest {
    static func orphanQuery(baseURL: URL) -> Self { .query(baseURL: baseURL, path: "api/catalogue/orphans") }
}

/// Deletion tombstones — sparse, unpaginated; always queried since the last sync.
public typealias DeletionsRequest = BasicRequest<SinceQuery, [DeletionRecord]>
public extension Request where Self == DeletionsRequest {
    static func deletionQuery(baseURL: URL) -> Self { .query(baseURL: baseURL, path: "api/sync/deletions") }
}
