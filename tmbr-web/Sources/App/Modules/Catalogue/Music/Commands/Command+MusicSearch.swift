import Foundation
import WebCore
import Fluent

struct MusicSearchResult: Sendable {
    let previews: [Preview]
    let noteMatches: [Preview]
}

extension Command where Self == PlainCommand<CatalogueQueryPayload, MusicSearchResult> {

    static func searchMusic(
        database: Database,
        noteSearch: CommandResolver<NoteQueryPayload, [Note]>,
        previewSearch: CommandResolver<PreviewQueryInput, [Preview]>
    ) -> Self {
        PlainCommand { payload in
            let allMusicSlugs: Set<String> = [Album.previewType, Playlist.previewType, Song.previewType]
            let requestedSlugs = payload.types.map { allMusicSlugs.intersection($0) } ?? allMusicSlugs

            let categoryIDs = Set(
                try await CatalogueCategory.query(on: database)
                    .filter(\.$slug ~~ requestedSlugs)
                    .all()
                    .compactMap(\.id)
            )

            let previewInput = PreviewQueryInput(term: payload.term, categoryIDs: categoryIDs)
            let noteInput = NoteQueryPayload(term: payload.term, categoryIDs: categoryIDs, languages: payload.languages)

            async let previewsTask = previewSearch(previewInput)
            async let notesTask = noteSearch(noteInput)
            let (previews, notes) = try await (previewsTask, notesTask)

            let previewIDs = Set(previews.compactMap(\.id))
            var seen = previewIDs
            let noteMatches = notes.compactMap { note -> Preview? in
                guard let id = note.attachment.id, !seen.contains(id) else { return nil }
                seen.insert(id)
                return note.attachment
            }

            return MusicSearchResult(previews: previews, noteMatches: noteMatches)
        }
    }
}

extension CommandFactory<CatalogueQueryPayload, MusicSearchResult> {

    static var searchMusic: Self {
        CommandFactory { request in
            .searchMusic(
                database: request.commandDB,
                noteSearch: request.commands.notes.search,
                previewSearch: request.commands.previews.list
            )
        }
    }
}
