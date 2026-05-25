import Vapor
import Core
import Foundation

extension Template where Model == CatalogueListViewModel {
    static let music = Template(name: "Catalogue/list")
}

extension Page {
    static var music: Self {
        Page(template: .music) { req in
            let payload = try req.query.decode(CatalogueQueryPayload.self)
            async let result = req.commands.music.search(payload)
            let compose = ComposePopupViewModel(req.permissions.compose(.music))
            let baseURL = req.baseURL
            let resolved = try await result
            return CatalogueListViewModel(
                compose: compose,
                filterItems: [FilterItemViewModel].music.map { $0.check(payload.types?.contains($0.value) ?? true) },
                term: payload.term,
                previews: resolved.previews.map { PreviewViewModel(preview: $0, baseURL: baseURL) }
                    + resolved.noteMatches.map { PreviewViewModel(preview: $0, baseURL: baseURL, isNoteMatch: true) }
            )
        }
    }
}
