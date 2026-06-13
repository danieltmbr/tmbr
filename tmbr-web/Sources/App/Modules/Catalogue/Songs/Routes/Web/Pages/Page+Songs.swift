import Vapor
import Core
import Foundation

extension Template where Model == CatalogueListViewModel {
    static let songs = Template(name: "Catalogue/list")
}

extension Page {
    static var songs: Self {
        Page(template: .songs) { req in
            let term = try? req.query.get(String.self, at: "term")
            async let result = req.commands.songs.search(term)
            let compose = ComposePopupViewModel(req.permissions.compose(.song))
            let baseURL = req.baseURL
            let resolved = try await result
            return CatalogueListViewModel(
                pageTitle: "Songs",
                compose: compose,
                term: term,
                previews: resolved.previews.map { PreviewViewModel(preview: $0, baseURL: baseURL) }
                    + resolved.noteMatches.map { PreviewViewModel(preview: $0, baseURL: baseURL, isNoteMatch: true) }
            )
        }
    }
}
