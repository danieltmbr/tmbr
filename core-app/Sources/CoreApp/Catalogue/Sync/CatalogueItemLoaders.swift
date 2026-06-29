import Foundation
import CoreApi

/// The network injection seam for per-item catalogue sync.
///
/// Each property is a loader factory — a closure from `(URL, URLSession)` to a concrete
/// `RequestLoader`. The default `init()` wires real factories; tests/previews substitute a
/// single factory (e.g. a stub loader that never hits the network) while leaving the rest real.
///
/// Injected via `\.itemLoaders`. Read by `@Loader` directly and by `@Upserter` via the recipe.
public struct CatalogueItemLoaders: Sendable {

    public let album:    @Sendable (URL, URLSession) -> AlbumItemLoader
    
    public let book:     @Sendable (URL, URLSession) -> BookItemLoader
    
    public let movie:    @Sendable (URL, URLSession) -> MovieItemLoader
    
    public let podcast:  @Sendable (URL, URLSession) -> PodcastItemLoader
    
    public let playlist: @Sendable (URL, URLSession) -> PlaylistItemLoader
    
    public let orphan:   @Sendable (URL, URLSession) -> PreviewItemLoader
    
    public let song:     @Sendable (URL, URLSession) -> SongItemLoader

    public init(
        album:    @escaping @Sendable (URL, URLSession) -> AlbumItemLoader    = AlbumItemLoader.album,
        book:     @escaping @Sendable (URL, URLSession) -> BookItemLoader     = BookItemLoader.book,
        movie:    @escaping @Sendable (URL, URLSession) -> MovieItemLoader    = MovieItemLoader.movie,
        podcast:  @escaping @Sendable (URL, URLSession) -> PodcastItemLoader  = PodcastItemLoader.podcast,
        playlist: @escaping @Sendable (URL, URLSession) -> PlaylistItemLoader = PlaylistItemLoader.playlist,
        orphan:   @escaping @Sendable (URL, URLSession) -> PreviewItemLoader  = PreviewItemLoader.previewItem,
        song:     @escaping @Sendable (URL, URLSession) -> SongItemLoader     = SongItemLoader.song
    ) {
        self.album = album
        self.book = book
        self.movie = movie
        self.podcast = podcast
        self.playlist = playlist
        self.orphan = orphan
        self.song = song
    }
}
