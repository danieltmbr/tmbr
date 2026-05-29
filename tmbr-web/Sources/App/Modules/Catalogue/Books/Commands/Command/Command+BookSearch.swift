import Foundation
import Core
import Fluent
import AuthKit

struct BookSearchResult: Sendable {

    let previews: [Preview]

    let noteMatches: [Preview]
}

extension Command where Self == PlainCommand<String?, BookSearchResult> {

    static func searchBooks(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Preview>>,
        noteSearch: CommandResolver<NoteQueryPayload, [Note]>
    ) -> Self {
        PlainCommand { term in
            let safeTerm = term.flatMap { t -> String? in
                let trimmed = t.trimmed
                return trimmed.isEmpty ? nil : trimmed.replacingOccurrences(of: "'", with: "''")
            }

            guard let bookCategory = try await CatalogueCategory.query(on: database)
                .filter(\.$slug == Book.previewType).first(),
                let categoryID = bookCategory.id else {
                return BookSearchResult(previews: [], noteMatches: [])
            }

            let query = Preview.query(on: database)
                .with(\.$image)
                .filter(\.$catalogueCategory.$id == categoryID)
                .join(Book.self, on: \Book.$preview.$id == \Preview.$id)
                .sort(\.$createdAt, .descending)

            if let safeTerm {
                query.group(.or) { group in
                    group.filter(.sql(unsafeRaw: "books.title ILIKE '%\(safeTerm)%'"))
                    group.filter(.sql(unsafeRaw: "books.author ILIKE '%\(safeTerm)%'"))
                    group.filter(.sql(unsafeRaw: "books.genre ILIKE '%\(safeTerm)%'"))
                }
            }

            try await permission.grant(query)

            async let previewsTask = query.all()
            async let notesTask = noteSearch(NoteQueryPayload(term: term, categoryIDs: [categoryID]))
            let (previews, notes) = try await (previewsTask, notesTask)

            let previewIDs = Set(previews.compactMap(\.id))
            var seen = previewIDs
            let noteMatches = notes.compactMap { note -> Preview? in
                guard let id = note.attachment.id, !seen.contains(id) else { return nil }
                seen.insert(id)
                return note.attachment
            }

            return BookSearchResult(previews: previews, noteMatches: noteMatches)
        }
    }
}

extension CommandFactory<String?, BookSearchResult> {

    static var searchBooks: Self {
        CommandFactory { request in
            .searchBooks(
                database: request.commandDB,
                permission: request.permissions.previews.query,
                noteSearch: request.commands.notes.search
            )
            .logged(name: "Search Books", logger: request.logger)
        }
    }
}
