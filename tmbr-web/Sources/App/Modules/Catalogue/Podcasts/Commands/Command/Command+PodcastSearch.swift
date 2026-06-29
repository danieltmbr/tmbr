import Foundation
import WebCore
import Fluent
import WebAuth

struct PodcastSearchResult: Sendable {

    let previews: [Preview]

    let noteMatches: [Preview]
}

extension Command where Self == PlainCommand<String?, PodcastSearchResult> {

    static func searchPodcasts(
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
                .filter(CatalogueCategory.self, \.$slug == Podcast.previewType)
                .join(Podcast.self, on: \Podcast.$preview.$id == \Preview.$id)
                .sort(\.$createdAt, .descending)

            if let safeTerm {
                query.group(.or) { group in
                    group.filter(.sql(unsafeRaw: "podcasts.episode_title ILIKE '%\(safeTerm)%'"))
                    group.filter(.sql(unsafeRaw: "podcasts.title ILIKE '%\(safeTerm)%'"))
                    group.filter(.sql(unsafeRaw: "podcasts.genre ILIKE '%\(safeTerm)%'"))
                }
            }

            try await permission.grant(query)

            async let previewsTask = query.all()
            async let notesTask = noteSearch(NoteQueryPayload(term: term, categorySlug: Podcast.previewType))
            let (previews, notes) = try await (previewsTask, notesTask)

            let previewIDs = Set(previews.compactMap(\.id))
            var seen = previewIDs
            let noteMatches = notes.compactMap { note -> Preview? in
                guard let id = note.attachment.id, !seen.contains(id) else { return nil }
                seen.insert(id)
                return note.attachment
            }

            return PodcastSearchResult(previews: previews, noteMatches: noteMatches)
        }
    }
}

extension CommandFactory<String?, PodcastSearchResult> {

    static var searchPodcasts: Self {
        CommandFactory { request in
            .searchPodcasts(
                database: request.commandDB,
                permission: request.permissions.previews.query,
                noteSearch: request.commands.notes.search
            )
            .logged(name: "Search Podcasts", logger: request.logger)
        }
    }
}
