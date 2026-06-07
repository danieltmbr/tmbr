import Vapor
import Core
import TmbrCore

struct CatalogueViewModel: Encodable, Sendable {

    let panels: [FilterPanelViewModel]

    let previews: [PreviewViewModel]

    let term: String?

    let compose: ComposePopupViewModel?
}

extension FilterItemViewModel {

    static let album = FilterItemViewModel(
        icon: "album",
        label: "Albums",
        value: Album.previewType
    )

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

    static let music = FilterItemViewModel(
        icon: "music",
        label: "Music",
        value: "music"
    )

    static let playlist = FilterItemViewModel(
        icon: "playlist",
        label: "Playlists",
        value: Playlist.previewType
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

}

extension [FilterItemViewModel] {
    static let catalogue: Self = [
        .book, .movie, .music, .podcast,
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
            let effectivePayload = CatalogueQueryPayload(
                term: payload.term,
                types: payload.types,
                languages: req.languagePreference
            )

            let allCategories = try await req.commands.catalogueCategories.list()
            let mapper = CatalogueQueryMapper(categories: allCategories)
            let search: PlainCommand<CatalogueQueryPayload, CatalogueSearchResult> = .searchCatalogue(
                mapper: mapper,
                noteSearch: req.commands.notes.search,
                previewSearch: req.commands.previews.list
            )
            let result = try await search(effectivePayload)
            let baseURL = req.baseURL
            let compose = ComposePopupViewModel(req.permissions.compose(.standard))

            let typeItems = allCategories.map { cat in
                FilterItemViewModel(
                    icon: cat.icon ?? "link",
                    label: cat.name,
                    value: cat.slug
                ).check(payload.types?.contains(cat.slug) ?? true)
            }

            return CatalogueViewModel(
                panels: [.types(typeItems)],
                previews: result.previews.map { PreviewViewModel(preview: $0, baseURL: baseURL) }
                    + result.noteMatches.map { PreviewViewModel(preview: $0, baseURL: baseURL, isNoteMatch: true) },
                term: payload.term,
                compose: compose
            )
        }
    }
}
