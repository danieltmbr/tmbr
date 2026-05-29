import Foundation
import Core
import Fluent
import AuthKit

struct MovieSearchResult: Sendable {

    let previews: [Preview]

    let noteMatches: [Preview]
}

extension Command where Self == PlainCommand<String?, MovieSearchResult> {

    static func searchMovies(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Preview>>,
        noteSearch: CommandResolver<NoteQueryPayload, [Note]>
    ) -> Self {
        PlainCommand { term in
            let safeTerm = term.flatMap { t -> String? in
                let trimmed = t.trimmed
                return trimmed.isEmpty ? nil : trimmed.replacingOccurrences(of: "'", with: "''")
            }

            guard let movieCategory = try await CatalogueCategory.query(on: database)
                .filter(\.$slug == Movie.previewType).first(),
                let categoryID = movieCategory.id else {
                return MovieSearchResult(previews: [], noteMatches: [])
            }

            let query = Preview.query(on: database)
                .with(\.$image)
                .filter(\.$catalogueCategory.$id == categoryID)
                .join(Movie.self, on: \Movie.$preview.$id == \Preview.$id)
                .sort(\.$createdAt, .descending)

            if let safeTerm {
                query.group(.or) { group in
                    group.filter(.sql(unsafeRaw: "movies.title ILIKE '%\(safeTerm)%'"))
                    group.filter(.sql(unsafeRaw: "movies.director ILIKE '%\(safeTerm)%'"))
                    group.filter(.sql(unsafeRaw: "movies.genre ILIKE '%\(safeTerm)%'"))
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

            return MovieSearchResult(previews: previews, noteMatches: noteMatches)
        }
    }
}

extension CommandFactory<String?, MovieSearchResult> {

    static var searchMovies: Self {
        CommandFactory { request in
            .searchMovies(
                database: request.commandDB,
                permission: request.permissions.previews.query,
                noteSearch: request.commands.notes.search
            )
            .logged(name: "Search Movies", logger: request.logger)
        }
    }
}
