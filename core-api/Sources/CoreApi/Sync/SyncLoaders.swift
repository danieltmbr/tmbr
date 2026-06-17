import Foundation
import CoreTmbr

// Ready-to-use, auth-refreshing loaders for each sync endpoint — the loader counterpart to the
// request factories in `SyncRequests.swift`. Drive them to completion with `.syncAll(since:)`
// (or `.load(from:)` for the unpaginated deletions endpoint), e.g.
//
//     let songs = try await RequestLoader<SongsRequest>.songs(baseURL: url, auth: auth).syncAll(since: lastSync)

public extension RequestLoader where R == SongsRequest {
    static func songs(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        RequestLoader(request: .songQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension RequestLoader where R == AlbumsRequest {
    static func albums(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        RequestLoader(request: .albumQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension RequestLoader where R == BooksRequest {
    static func books(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        RequestLoader(request: .bookQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension RequestLoader where R == MoviesRequest {
    static func movies(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        RequestLoader(request: .movieQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension RequestLoader where R == PodcastsRequest {
    static func podcasts(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        RequestLoader(request: .podcastQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension RequestLoader where R == PlaylistsRequest {
    static func playlists(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        RequestLoader(request: .playlistQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension RequestLoader where R == PostsRequest {
    static func posts(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        RequestLoader(request: .postQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension RequestLoader where R == OrphansRequest {
    static func orphans(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        RequestLoader(request: .orphanQuery(baseURL: baseURL), session: session, auth: auth)
    }
}

public extension RequestLoader where R == DeletionsRequest {
    static func deletions(baseURL: URL, session: URLSession = .shared, auth: AuthProvider) -> Self {
        RequestLoader(request: .deletionQuery(baseURL: baseURL), session: session, auth: auth)
    }
}
