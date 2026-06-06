import Foundation
import Core
import Fluent
import AuthKit

struct SongSearchResult: Sendable {

    let previews: [Preview]

    let noteMatches: [Preview]
}

extension Command where Self == PlainCommand<String?, SongSearchResult> {

    static func searchSongs(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Preview>>,
        noteSearch: CommandResolver<NoteQueryPayload, [Note]>
    ) -> Self {
        PlainCommand { term in
            let safeTerm = term.flatMap { t -> String? in
                let trimmed = t.trimmed
                return trimmed.isEmpty ? nil : trimmed.replacingOccurrences(of: "'", with: "''")
            }

            guard let songCategory = try await CatalogueCategory.query(on: database)
                .filter(\.$slug == Song.previewType).first(),
                let categoryID = songCategory.id else {
                return SongSearchResult(previews: [], noteMatches: [])
            }

            let query = Preview.query(on: database)
                .with(\.$image)
                .filter(\.$catalogueCategory.$id == categoryID)
                .join(Song.self, on: \Song.$preview.$id == \Preview.$id)
                .sort(\.$createdAt, .descending)

            if let safeTerm {
                query.group(.or) { group in
                    group.filter(.sql(unsafeRaw: "songs.title ILIKE '%\(safeTerm)%'"))
                    group.filter(.sql(unsafeRaw: "songs.artist ILIKE '%\(safeTerm)%'"))
                    group.filter(.sql(unsafeRaw: "songs.album ILIKE '%\(safeTerm)%'"))
                    group.filter(.sql(unsafeRaw: "songs.genre ILIKE '%\(safeTerm)%'"))
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

            return SongSearchResult(previews: previews, noteMatches: noteMatches)
        }
    }
}

extension CommandFactory<String?, SongSearchResult> {

    static var searchSongs: Self {
        CommandFactory { request in
            .searchSongs(
                database: request.commandDB,
                permission: request.permissions.previews.query,
                noteSearch: request.commands.notes.search
            )
            .logged(name: "Search Songs", logger: request.logger)
        }
    }
}
