import Vapor
import Core
import Foundation

struct MoviesViewModel: Encodable, Sendable {
    let compose: String?
    let term: String?
    let previews: [PreviewViewModel]
}

extension Template where Model == MoviesViewModel {
    static let movies = Template(name: "Catalogue/Movies/movies")
}

extension Page {
    static var movies: Self {
        Page(template: .movies) { req in
            let term = try? req.query.get(String.self, at: "term")
            async let composeURL: String? = (try? await req.permissions.movies.create()) != nil ? "/movies/new" : nil
            async let result = req.commands.movies.search(term)
            let baseURL = req.baseURL
            let resolved = try await result
            return MoviesViewModel(
                compose: await composeURL,
                term: term,
                previews: resolved.previews.map { PreviewViewModel(preview: $0, baseURL: baseURL) }
                    + resolved.noteMatches.map { PreviewViewModel(preview: $0, baseURL: baseURL, isNoteMatch: true) }
            )
        }
    }
}
