import Vapor
import Core
import Foundation

extension Template where Model == CatalogueListViewModel {
    static let albums = Template(name: "Catalogue/list")
}

extension Page {
    static var albums: Self {
        Page(template: .albums) { req in
            let term = try? req.query.get(String.self, at: "term")
            async let result = req.commands.albums.search(term)
            let compose = ComposePopupViewModel(req.permissions.compose(.album))
            let baseURL = req.baseURL
            let resolved = try await result
            return CatalogueListViewModel(
                pageTitle: "Albums",
                compose: compose,
                term: term,
                previews: resolved.previews.map { PreviewViewModel(preview: $0, baseURL: baseURL) }
                    + resolved.noteMatches.map { PreviewViewModel(preview: $0, baseURL: baseURL, isNoteMatch: true) }
            )
        }
    }
}
