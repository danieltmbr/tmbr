import Vapor
import Core
import Foundation

struct BooksViewModel: Encodable, Sendable {
    let compose: String?
    let term: String?
    let previews: [PreviewViewModel]
}

extension Template where Model == BooksViewModel {
    static let books = Template(name: "Catalogue/Books/books")
}

extension Page {
    static var books: Self {
        Page(template: .books) { req in
            let term = try? req.query.get(String.self, at: "term")
            async let composeURL: String? = (try? await req.permissions.books.create()) != nil ? "/books/new" : nil
            async let result = req.commands.books.search(term)
            let baseURL = req.baseURL
            let resolved = try await result
            return BooksViewModel(
                compose: await composeURL,
                term: term,
                previews: resolved.previews.map { PreviewViewModel(preview: $0, baseURL: baseURL) }
                    + resolved.noteMatches.map { PreviewViewModel(preview: $0, baseURL: baseURL, isNoteMatch: true) }
            )
        }
    }
}
