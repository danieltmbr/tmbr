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
            async let composeURL: String? = (try? await req.permissions.albums.create()) != nil ? "/albums/new" : nil
            async let result = req.commands.albums.search(term)
            let baseURL = req.baseURL
            let resolved = try await result
            return CatalogueListViewModel(
                compose: await composeURL,
                term: term,
                previews: resolved.previews.map { PreviewViewModel(preview: $0, baseURL: baseURL) }
                    + resolved.noteMatches.map { PreviewViewModel(preview: $0, baseURL: baseURL, isNoteMatch: true) }
            )
        }
    }
}
