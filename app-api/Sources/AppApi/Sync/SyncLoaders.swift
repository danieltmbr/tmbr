import Foundation
import TmbrCore

// Loader typealiases — the `RequestLoader` counterpart to the request typealiases in `SyncRequests.swift`.
// Each pairs with its request: `SongsRequest` ↔ `SongsLoader`, `PostsRequest` ↔ `PostsLoader`, etc.

public typealias SongsLoader     = RequestLoader<PageQuery, PageResult<SongResponse>>
public typealias AlbumsLoader    = RequestLoader<PageQuery, PageResult<AlbumResponse>>
public typealias BooksLoader     = RequestLoader<PageQuery, PageResult<BookResponse>>
public typealias MoviesLoader    = RequestLoader<PageQuery, PageResult<MovieResponse>>
public typealias PodcastsLoader  = RequestLoader<PageQuery, PageResult<PodcastResponse>>
public typealias PlaylistsLoader = RequestLoader<PageQuery, PageResult<PlaylistResponse>>
public typealias PostsLoader     = RequestLoader<PageQuery, PageResult<PostResponse>>
public typealias OrphansLoader   = RequestLoader<OrphanPageQuery, PageResult<PreviewResponse>>
public typealias DeletionsLoader = RequestLoader<SinceQuery, [DeletionRecord]>

// Unauthenticated loader factories — for public endpoints (Reader app).
// Drive with `.load(from:)` and a plain `PageQuery` / `OrphanPageQuery`.

public extension SongsLoader {
    static func songs(baseURL: URL, session: URLSession = .shared) -> Self {
        SongsLoader(request: SongsRequest.songQuery(baseURL: baseURL), session: session)
    }
}

public extension AlbumsLoader {
    static func albums(baseURL: URL, session: URLSession = .shared) -> Self {
        AlbumsLoader(request: AlbumsRequest.albumQuery(baseURL: baseURL), session: session)
    }
}

public extension BooksLoader {
    static func books(baseURL: URL, session: URLSession = .shared) -> Self {
        BooksLoader(request: BooksRequest.bookQuery(baseURL: baseURL), session: session)
    }
}

public extension MoviesLoader {
    static func movies(baseURL: URL, session: URLSession = .shared) -> Self {
        MoviesLoader(request: MoviesRequest.movieQuery(baseURL: baseURL), session: session)
    }
}

public extension PodcastsLoader {
    static func podcasts(baseURL: URL, session: URLSession = .shared) -> Self {
        PodcastsLoader(request: PodcastsRequest.podcastQuery(baseURL: baseURL), session: session)
    }
}

public extension PlaylistsLoader {
    static func playlists(baseURL: URL, session: URLSession = .shared) -> Self {
        PlaylistsLoader(request: PlaylistsRequest.playlistQuery(baseURL: baseURL), session: session)
    }
}

public extension PostsLoader {
    static func posts(baseURL: URL, session: URLSession = .shared) -> Self {
        PostsLoader(request: PostsRequest.postQuery(baseURL: baseURL), session: session)
    }
}

public extension OrphansLoader {
    static func orphans(baseURL: URL, session: URLSession = .shared) -> Self {
        OrphansLoader(request: OrphansRequest.orphanQuery(baseURL: baseURL), session: session)
    }
}

// Ready-to-use, auth-refreshing loader factories — drive with `.syncAll(since:)` or `.load(from:)`, e.g.
//
//     let songs = try await SongsLoader.songs(baseURL: url, auth: auth).syncAll(since: lastSync)

public extension SongsLoader {
    static func songs(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        SongsLoader(request: SongsRequest.songQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension AlbumsLoader {
    static func albums(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        AlbumsLoader(request: AlbumsRequest.albumQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension BooksLoader {
    static func books(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        BooksLoader(request: BooksRequest.bookQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension MoviesLoader {
    static func movies(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        MoviesLoader(request: MoviesRequest.movieQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension PodcastsLoader {
    static func podcasts(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        PodcastsLoader(request: PodcastsRequest.podcastQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension PlaylistsLoader {
    static func playlists(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        PlaylistsLoader(request: PlaylistsRequest.playlistQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension PostsLoader {
    static func posts(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        PostsLoader(request: PostsRequest.postQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension OrphansLoader {
    static func orphans(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        OrphansLoader(request: OrphansRequest.orphanQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension DeletionsLoader {
    static func deletions(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        DeletionsLoader(request: DeletionsRequest.deletionQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

// MARK: - Single-item loaders (unauthenticated — Reader app)

// MARK: - Single-item loaders
//
// `Input` is the item id type (Int for typed catalogue items, UUID for orphans). The loader is
// created once per base URL; the id is supplied at call time via `load(from:)` — consistent with
// how `CatalogueItemSyncer<ID>` passes the id through `Syncer(loader:from:into:)`.

public typealias SongItemLoader     = RequestLoader<Int, SongResponse>
public typealias AlbumItemLoader    = RequestLoader<Int, AlbumResponse>
public typealias BookItemLoader     = RequestLoader<Int, BookResponse>
public typealias MovieItemLoader    = RequestLoader<Int, MovieResponse>
public typealias PodcastItemLoader  = RequestLoader<Int, PodcastResponse>
public typealias PlaylistItemLoader = RequestLoader<Int, PlaylistResponse>
public typealias PreviewItemLoader  = RequestLoader<UUID, PreviewResponse>

public extension SongItemLoader {
    static func song(baseURL: URL, session: URLSession = .shared) -> Self {
        SongItemLoader(request: SongItemRequest.song(baseURL: baseURL), session: session)
    }
}

public extension AlbumItemLoader {
    static func album(baseURL: URL, session: URLSession = .shared) -> Self {
        AlbumItemLoader(request: AlbumItemRequest.album(baseURL: baseURL), session: session)
    }
}

public extension BookItemLoader {
    static func book(baseURL: URL, session: URLSession = .shared) -> Self {
        BookItemLoader(request: BookItemRequest.book(baseURL: baseURL), session: session)
    }
}

public extension MovieItemLoader {
    static func movie(baseURL: URL, session: URLSession = .shared) -> Self {
        MovieItemLoader(request: MovieItemRequest.movie(baseURL: baseURL), session: session)
    }
}

public extension PodcastItemLoader {
    static func podcast(baseURL: URL, session: URLSession = .shared) -> Self {
        PodcastItemLoader(request: PodcastItemRequest.podcast(baseURL: baseURL), session: session)
    }
}

public extension PlaylistItemLoader {
    static func playlist(baseURL: URL, session: URLSession = .shared) -> Self {
        PlaylistItemLoader(request: PlaylistItemRequest.playlist(baseURL: baseURL), session: session)
    }
}

public extension PreviewItemLoader {
    static func previewItem(baseURL: URL, session: URLSession = .shared) -> Self {
        PreviewItemLoader(request: PreviewItemRequest.previewItem(baseURL: baseURL), session: session)
    }
}
