import Foundation
import CoreApi
import CoreTmbr

/// A self-contained recipe for one catalogue item type: its loader factory, its store sink,
/// and `assemble` which pairs a pre-resolved loader with the sink to produce a
/// `CatalogueItemSyncer<ID>`. Nothing is built until `assemble` is called.
///
/// `@Loader(\.song)` reads `loaderFactory`; `@Upserter(\.song)` calls `assemble`.
/// Both wrappers keypath into `CatalogueItemSyncs` so they share the same source of truth.
public struct CatalogueItemSync<ID: Sendable, Response: Decodable & Sendable>: Sendable {

    public let label: String
    public let loaderFactory: @Sendable (URL, URLSession) -> RequestLoader<ID, Response>
    public let sink: @MainActor (CatalogueStore, Response) throws -> Void

    public init(
        _ label: String,
        loader loaderFactory: @escaping @Sendable (URL, URLSession) -> RequestLoader<ID, Response>,
        sink: @escaping @MainActor (CatalogueStore, Response) throws -> Void
    ) {
        self.label = label
        self.loaderFactory = loaderFactory
        self.sink = sink
    }

    /// Pair an already-resolved loader with the store sink. The loader is built exactly once
    /// (by the caller) and injected here; no networking happens until the returned syncer runs.
    @MainActor
    public func assemble(_ loader: RequestLoader<ID, Response>, _ store: CatalogueStore) -> CatalogueItemSyncer<ID> {
        CatalogueItemSyncer { [label, sink] id in
            try await Syncer(label, loader: loader, from: id) { try await sink(store, $0) }.run()
        }
    }
}

// MARK: - Namespace

/// Keypath-addressable namespace of one `CatalogueItemSync` per catalogue type.
/// Both `@Loader` and `@Upserter` address into this single namespace — loader and syncer
/// wiring can never drift apart.
///
/// The default `init()` wires real loader factories with their store sinks. Tests override
/// individual recipes via the memberwise init (only one recipe changes; the rest stay real).
public struct CatalogueItemSyncs: Sendable {

    public let song:     CatalogueItemSync<Int, SongResponse>
    public let album:    CatalogueItemSync<Int, AlbumResponse>
    public let book:     CatalogueItemSync<Int, BookResponse>
    public let movie:    CatalogueItemSync<Int, MovieResponse>
    public let podcast:  CatalogueItemSync<Int, PodcastResponse>
    public let playlist: CatalogueItemSync<Int, PlaylistResponse>
    public let orphan:   CatalogueItemSync<UUID, PreviewResponse>

    public init(
        song:     CatalogueItemSync<Int, SongResponse>     = .init("song",     loader: { SongItemLoader.song(baseURL: $0, session: $1) },     sink: { try $0.upsert([$1]) }),
        album:    CatalogueItemSync<Int, AlbumResponse>    = .init("album",    loader: { AlbumItemLoader.album(baseURL: $0, session: $1) },    sink: { try $0.upsert([$1]) }),
        book:     CatalogueItemSync<Int, BookResponse>     = .init("book",     loader: { BookItemLoader.book(baseURL: $0, session: $1) },     sink: { try $0.upsert([$1]) }),
        movie:    CatalogueItemSync<Int, MovieResponse>    = .init("movie",    loader: { MovieItemLoader.movie(baseURL: $0, session: $1) },    sink: { try $0.upsert([$1]) }),
        podcast:  CatalogueItemSync<Int, PodcastResponse>  = .init("podcast",  loader: { PodcastItemLoader.podcast(baseURL: $0, session: $1) }, sink: { try $0.upsert([$1]) }),
        playlist: CatalogueItemSync<Int, PlaylistResponse> = .init("playlist", loader: { PlaylistItemLoader.playlist(baseURL: $0, session: $1) }, sink: { try $0.upsert([$1]) }),
        orphan:   CatalogueItemSync<UUID, PreviewResponse> = .init("orphan",   loader: { PreviewItemLoader.previewItem(baseURL: $0, session: $1) }, sink: { try $0.upsertOrphans([$1]) })
    ) {
        self.song = song; self.album = album; self.book = book; self.movie = movie
        self.podcast = podcast; self.playlist = playlist; self.orphan = orphan
    }
}
