import Foundation
import TmbrCore
import ApiKit

/// Vends typed `RequestLoader`s for every endpoint the native catalogue/blog sync needs.
///
/// Lightweight `Sendable` value — created once at the app layer with the base URL + `AuthProvider`,
/// then handed to the per-app sync (Author's `SyncEngine`, Reader's `CacheLoader`). It owns no state.
public struct SyncAPI: Sendable {

    public let baseURL: URL
    public let auth: AuthProvider
    public let session: URLSession

    public init(baseURL: URL, auth: AuthProvider, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.auth = auth
        self.session = session
    }

    private func loader<I: Encodable & Sendable, R: Decodable & Sendable>(
        _ path: String
    ) -> RequestLoader<BasicRequest<I, R>> {
        RequestLoader(request: .query(baseURL: baseURL, path: path), session: session, auth: auth)
    }

    // MARK: Per-type catalogue lists (each response embeds its `.notes` and its `.preview.id`)

    public func songs() -> RequestLoader<BasicRequest<PageQuery, PageResult<SongResponse>>> { loader("api/songs") }
    public func albums() -> RequestLoader<BasicRequest<PageQuery, PageResult<AlbumResponse>>> { loader("api/albums") }
    public func books() -> RequestLoader<BasicRequest<PageQuery, PageResult<BookResponse>>> { loader("api/books") }
    public func movies() -> RequestLoader<BasicRequest<PageQuery, PageResult<MovieResponse>>> { loader("api/movies") }
    public func podcasts() -> RequestLoader<BasicRequest<PageQuery, PageResult<PodcastResponse>>> { loader("api/podcasts") }
    public func playlists() -> RequestLoader<BasicRequest<PageQuery, PageResult<PlaylistResponse>>> { loader("api/playlists") }

    // MARK: Blog

    public func posts() -> RequestLoader<BasicRequest<PageQuery, PageResult<PostResponse>>> { loader("api/posts") }

    // MARK: Orphans (sent with ?notes=true so each orphan carries its embedded notes)

    public func orphans() -> RequestLoader<BasicRequest<OrphanPageQuery, PageResult<PreviewResponse>>> {
        loader("api/catalogue/orphans")
    }

    // MARK: Deletion tombstones (sparse; no cursor — always queried since last sync)

    public func deletions() -> RequestLoader<BasicRequest<SinceQuery, [DeletionRecord]>> {
        loader("api/sync/deletions")
    }
}

/// `PageQuery` plus `notes=true` — the orphans endpoint embeds notes only when asked.
public struct OrphanPageQuery: Encodable, Sendable {
    public let since: Date?
    public let cursor: String?
    public let limit: Int
    public let notes: Bool

    public init(since: Date? = nil, cursor: String? = nil, limit: Int = 50, notes: Bool = true) {
        self.since = since
        self.cursor = cursor
        self.limit = limit
        self.notes = notes
    }
}

/// Query for the deletions endpoint — just a delta cursor.
public struct SinceQuery: Encodable, Sendable {
    public let since: Date?
    public init(since: Date? = nil) { self.since = since }
}
