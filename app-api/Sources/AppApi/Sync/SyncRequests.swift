import Foundation
import TmbrCore

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

/// Full structured category list — non-paginated; the set is small and server-authoritative.
public typealias CategoriesRequest = BasicRequest<Void, [CategoryResponse]>
public extension Request where Self == CategoriesRequest {
    static func categoryQuery(baseURL: URL) -> Self { .get(baseURL: baseURL, path: "api/catalogue/categories") }
}

/// Deletion tombstones — sparse, unpaginated; always queried since the last sync.
public typealias DeletionsRequest = BasicRequest<SinceQuery, [DeletionRecord]>
public extension Request where Self == DeletionsRequest {
    static func deletionQuery(baseURL: URL) -> Self { .query(baseURL: baseURL, path: "api/sync/deletions") }
}

// MARK: - Single-item requests
//
// The item id is the `Input` type (not baked into the URL), so one loader instance can serve
// any id of the right type. The build closure receives it as `id` and appends it to the path.

public typealias SongItemRequest = BasicRequest<Int, SongResponse>
public extension Request where Self == SongItemRequest {
    static func song(baseURL: URL) -> Self {
        BasicRequest(url: baseURL.appending(path: "api/songs")) { url, id, token in
            var req = URLRequest(url: url.appending(path: "\(id)"))
            req.httpMethod = HTTPMethod.get.rawValue
            if let token { req.addHeader(.authorization.bearer(token)) }
            return req
        }
    }
}

public typealias AlbumItemRequest = BasicRequest<Int, AlbumResponse>
public extension Request where Self == AlbumItemRequest {
    static func album(baseURL: URL) -> Self {
        BasicRequest(url: baseURL.appending(path: "api/albums")) { url, id, token in
            var req = URLRequest(url: url.appending(path: "\(id)"))
            req.httpMethod = HTTPMethod.get.rawValue
            if let token { req.addHeader(.authorization.bearer(token)) }
            return req
        }
    }
}

public typealias BookItemRequest = BasicRequest<Int, BookResponse>
public extension Request where Self == BookItemRequest {
    static func book(baseURL: URL) -> Self {
        BasicRequest(url: baseURL.appending(path: "api/books")) { url, id, token in
            var req = URLRequest(url: url.appending(path: "\(id)"))
            req.httpMethod = HTTPMethod.get.rawValue
            if let token { req.addHeader(.authorization.bearer(token)) }
            return req
        }
    }
}

public typealias MovieItemRequest = BasicRequest<Int, MovieResponse>
public extension Request where Self == MovieItemRequest {
    static func movie(baseURL: URL) -> Self {
        BasicRequest(url: baseURL.appending(path: "api/movies")) { url, id, token in
            var req = URLRequest(url: url.appending(path: "\(id)"))
            req.httpMethod = HTTPMethod.get.rawValue
            if let token { req.addHeader(.authorization.bearer(token)) }
            return req
        }
    }
}

public typealias PodcastItemRequest = BasicRequest<Int, PodcastResponse>
public extension Request where Self == PodcastItemRequest {
    static func podcast(baseURL: URL) -> Self {
        BasicRequest(url: baseURL.appending(path: "api/podcasts")) { url, id, token in
            var req = URLRequest(url: url.appending(path: "\(id)"))
            req.httpMethod = HTTPMethod.get.rawValue
            if let token { req.addHeader(.authorization.bearer(token)) }
            return req
        }
    }
}

public typealias PlaylistItemRequest = BasicRequest<Int, PlaylistResponse>
public extension Request where Self == PlaylistItemRequest {
    static func playlist(baseURL: URL) -> Self {
        BasicRequest(url: baseURL.appending(path: "api/playlists")) { url, id, token in
            var req = URLRequest(url: url.appending(path: "\(id)"))
            req.httpMethod = HTTPMethod.get.rawValue
            if let token { req.addHeader(.authorization.bearer(token)) }
            return req
        }
    }
}

/// Orphan single-item: GET /api/catalogue/item/:previewID?notes=true.
/// The `?notes=true` flag is baked in so `CatalogueStore.reconcileNotes` never sees an empty
/// incoming array and mistakenly deletes existing synced notes.
public typealias PreviewItemRequest = BasicRequest<UUID, PreviewResponse>
public extension Request where Self == PreviewItemRequest {
    static func previewItem(baseURL: URL) -> Self {
        BasicRequest(url: baseURL.appending(path: "api/catalogue/item")) { url, id, token in
            guard var components = URLComponents(url: url.appending(path: id.uuidString), resolvingAgainstBaseURL: false) else {
                throw URLBuildingError.invalidURL(url)
            }
            components.queryItems = [URLQueryItem(name: "notes", value: "true")]
            guard let finalURL = components.url else {
                throw URLBuildingError.invalidComponents(components)
            }
            var req = URLRequest(url: finalURL)
            req.httpMethod = HTTPMethod.get.rawValue
            if let token { req.addHeader(.authorization.bearer(token)) }
            return req
        }
    }
}
