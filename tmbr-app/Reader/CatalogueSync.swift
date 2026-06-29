import Foundation
import AppApi
import AppCore
import TmbrCore

extension SyncGroup {
    /// Standard Reader catalogue sync: fetches the six typed lists + orphans from `baseURL` and
    /// upserts each result into `store`. Runs all seven in parallel with partial-success semantics —
    /// individual endpoint failures are logged and surfaced without discarding successes.
    static func catalogue(baseURL: URL, store: CatalogueStore) -> SyncGroup {
        let page = PageQuery(limit: 50)
        return SyncGroup([
            Syncer("songs",     loader: .songs(baseURL: baseURL),     from: page) { try await store.upsert($0) },
            Syncer("albums",    loader: .albums(baseURL: baseURL),    from: page) { try await store.upsert($0) },
            Syncer("books",     loader: .books(baseURL: baseURL),     from: page) { try await store.upsert($0) },
            Syncer("movies",    loader: .movies(baseURL: baseURL),    from: page) { try await store.upsert($0) },
            Syncer("podcasts",  loader: .podcasts(baseURL: baseURL),  from: page) { try await store.upsert($0) },
            Syncer("playlists", loader: .playlists(baseURL: baseURL), from: page) { try await store.upsert($0) },
            Syncer("orphans",   loader: .orphans(baseURL: baseURL),   from: OrphanPageQuery(limit: 50)) { try await store.upsertOrphans($0) },
        ])
    }
}
