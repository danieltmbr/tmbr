import Vapor
import Core

struct CatalogueViewModel: Encodable, Sendable {

    let filterItems: [FilterItemViewModel]

    let previews: [PreviewViewModel]

    let term: String?
}

extension FilterItemViewModel {
    
    static let book = FilterItemViewModel(
        iconName: "book",
        label: "Books",
        value: Book.previewType
    )
    
    static let movie = FilterItemViewModel(
        iconName: "movie",
        label: "Movies",
        value: Movie.previewType
    )
    
    static let podcast = FilterItemViewModel(
        iconName: "podcast",
        label: "Podcasts",
        value: Podcast.previewType
    )
    
    static let song = FilterItemViewModel(
        iconName: "song",
        label: "Songs",
        value: Song.previewType
    )
}

extension [FilterItemViewModel] {
    static let catalogue: Self = [
        .book, .movie, .podcast, .song,
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
            return CatalogueViewModel(
                filterItems: .catalogue.map { filter in
                    filter.check(selectedTypes?.contains(filter.value) ?? true)
                },
                previews: result.previews.map { PreviewViewModel(preview: $0, baseURL: baseURL) }
                    + result.noteMatches.map { PreviewViewModel(preview: $0, baseURL: baseURL, isNoteMatch: true) },
                term: term
            )
        }
    }
}
