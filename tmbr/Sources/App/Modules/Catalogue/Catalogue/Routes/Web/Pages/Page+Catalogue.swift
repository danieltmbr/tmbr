import Vapor
import Core

struct CatalogueViewModel: Encodable, Sendable {

    let filterItems: [FilterItemViewModel]

    let previews: [PreviewViewModel]

    let term: String?

    let compose: ComposePopupViewModel?
}

extension FilterItemViewModel {
    
    static let book = FilterItemViewModel(
        icon: "book",
        label: "Books",
        value: Book.previewType
    )
    
    static let movie = FilterItemViewModel(
        icon: "movie",
        label: "Movies",
        value: Movie.previewType
    )
    
    static let podcast = FilterItemViewModel(
        icon: "podcast",
        label: "Podcasts",
        value: Podcast.previewType
    )
    
    static let song = FilterItemViewModel(
        icon: "song",
        label: "Songs",
        value: Song.previewType
    )
    
    static let album = FilterItemViewModel(
        icon: "album",
        label: "Albums",
        value: Album.previewType
    )
    
    static let playlist = FilterItemViewModel(
        icon: "playlist",
        label: "Playlists",
        value: Playlist.previewType
    )
}

extension [FilterItemViewModel] {
    static let catalogue: Self = [
        .book, .movie, .podcast, .song
    ]
    
    static let music: Self = [
        .song, .album, .playlist
    ]
}

extension Template where Model == CatalogueViewModel {
    static let catalogue = Template(name: "Catalogue/catalogue")
}

extension Page {
    static var catalogue: Self {
        Page(template: .catalogue) { req in
            let payload = try req.query.decode(CatalogueQueryPayload.self)
            let term = payload.term
            let selectedTypes = payload.types
            let result = try await req.commands.catalogue.search(payload)
            let baseURL = req.baseURL
            let compose = ComposePopupViewModel(req.permissions.compose(.standard))
            return CatalogueViewModel(
                filterItems: .catalogue.map { filter in
                    filter.check(selectedTypes?.contains(filter.value) ?? true)
                },
                previews: result.previews.map { PreviewViewModel(preview: $0, baseURL: baseURL) }
                    + result.noteMatches.map { PreviewViewModel(preview: $0, baseURL: baseURL, isNoteMatch: true) },
                term: term,
                compose: compose
            )
        }
    }
}
