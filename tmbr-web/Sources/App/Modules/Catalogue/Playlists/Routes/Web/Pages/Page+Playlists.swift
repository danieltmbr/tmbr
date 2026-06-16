import Vapor
import CoreWeb
import Foundation

extension Template where Model == CatalogueListViewModel {
    static let playlists = Template(name: "Catalogue/list")
}

extension Page {
    static var playlists: Self {
        Page(template: .playlists) { req in
            let term = try? req.query.get(String.self, at: "term")
            async let result = req.commands.playlists.search(term)
            let compose = ComposePopupViewModel(req.permissions.compose(.playlist))
            let baseURL = req.baseURL
            let resolved = try await result
            return CatalogueListViewModel(
                pageTitle: "Catalogue",
                compose: compose,
                term: term,
                previews: resolved.previews.map { PreviewViewModel(preview: $0, baseURL: baseURL) }
                    + resolved.noteMatches.map { PreviewViewModel(preview: $0, baseURL: baseURL, isNoteMatch: true) }
            )
        }
    }
}
