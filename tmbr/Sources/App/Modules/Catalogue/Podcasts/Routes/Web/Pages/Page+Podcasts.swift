import Vapor
import Core
import Foundation

extension Template where Model == CatalogueListViewModel {
    static let podcasts = Template(name: "Catalogue/list")
}

extension Page {
    static var podcasts: Self {
        Page(template: .podcasts) { req in
            let term = try? req.query.get(String.self, at: "term")
            async let result = req.commands.podcasts.search(term)
            let compose = ComposePopupViewModel(req.permissions.compose(.podcast))
            let baseURL = req.baseURL
            let resolved = try await result
            return CatalogueListViewModel(
                compose: compose,
                term: term,
                previews: resolved.previews.map { PreviewViewModel(preview: $0, baseURL: baseURL) }
                    + resolved.noteMatches.map { PreviewViewModel(preview: $0, baseURL: baseURL, isNoteMatch: true) }
            )
        }
    }
}
