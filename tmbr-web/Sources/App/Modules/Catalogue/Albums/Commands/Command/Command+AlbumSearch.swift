import Foundation
import CoreWeb
import Fluent
import CoreAuth

struct AlbumSearchResult: Sendable {

    let previews: [Preview]

    let noteMatches: [Preview]
}

extension Command where Self == PlainCommand<String?, AlbumSearchResult> {

    static func searchAlbums(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Preview>>,
        noteSearch: CommandResolver<NoteQueryPayload, [Note]>
    ) -> Self {
        PlainCommand { term in
            let safeTerm = term.flatMap { t -> String? in
                let trimmed = t.trimmed
                return trimmed.isEmpty ? nil : trimmed.replacingOccurrences(of: "'", with: "''")
            }

            let query = Preview.query(on: database)
                .with(\.$image)
                .join(CatalogueCategory.self, on: \CatalogueCategory.$id == \Preview.$catalogueCategory.$id)
                .filter(CatalogueCategory.self, \.$slug == Album.previewType)
                .join(Album.self, on: \Album.$preview.$id == \Preview.$id)
                .sort(\.$createdAt, .descending)

            if let safeTerm {
                query.group(.or) { group in
                    group.filter(.sql(unsafeRaw: "albums.title ILIKE '%\(safeTerm)%'"))
                    group.filter(.sql(unsafeRaw: "albums.artist ILIKE '%\(safeTerm)%'"))
                    group.filter(.sql(unsafeRaw: "albums.genre ILIKE '%\(safeTerm)%'"))
                }
            }

            try await permission.grant(query)

            async let previewsTask = query.all()
            async let notesTask = noteSearch(NoteQueryPayload(term: term, categorySlug: Album.previewType))
            let (previews, notes) = try await (previewsTask, notesTask)

            let previewIDs = Set(previews.compactMap(\.id))
            var seen = previewIDs
            let noteMatches = notes.compactMap { note -> Preview? in
                guard let id = note.attachment.id, !seen.contains(id) else { return nil }
                seen.insert(id)
                return note.attachment
            }

            return AlbumSearchResult(previews: previews, noteMatches: noteMatches)
        }
    }
}

extension CommandFactory<String?, AlbumSearchResult> {

    static var searchAlbums: Self {
        CommandFactory { request in
            .searchAlbums(
                database: request.commandDB,
                permission: request.permissions.previews.query,
                noteSearch: request.commands.notes.search
            )
            .logged(name: "Search Albums", logger: request.logger)
        }
    }
}
