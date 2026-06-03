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

extension FilterItemViewModel {
    static let en = FilterItemViewModel(icon: "🇬🇧", label: "English", value: Language.en.rawValue)
    static let hu = FilterItemViewModel(icon: "🇭🇺", label: "Hungarian", value: Language.hu.rawValue)
}

extension [FilterItemViewModel] {
    static let catalogue: Self = [
        .book, .movie, .music, .podcast,
    ]

    static let music: Self = [
        .song, .album, .playlist
    ]

    static let languages: Self = [.en, .hu]
}

extension Template where Model == CatalogueViewModel {
    static let catalogue = Template(name: "Catalogue/catalogue")
}

extension Page {
    static var catalogue: Self {
        Page(template: .catalogue) { req in
            let payload = try req.query.decode(CatalogueQueryPayload.self)
            let effectivePayload = CatalogueQueryPayload(term: payload.term, types: payload.types, languages: req.languagePreference)
            let result = try await req.commands.catalogue.search(effectivePayload)
            let baseURL = req.baseURL
            let compose = ComposePopupViewModel(req.permissions.compose(.standard))
            let typeItems = [FilterItemViewModel].catalogue.map { $0.check(payload.types?.contains($0.value) ?? true) }
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
