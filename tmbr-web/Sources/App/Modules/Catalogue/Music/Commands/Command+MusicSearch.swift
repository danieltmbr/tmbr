import Foundation
import Core

struct MusicSearchResult: Sendable {
    let previews: [Preview]
    let noteMatches: [Preview]
}

extension Command where Self == PlainCommand<CatalogueQueryPayload, MusicSearchResult> {

    static func searchMusic(
        noteSearch: CommandResolver<NoteQueryPayload, [Note]>,
        previewSearch: CommandResolver<PreviewQueryInput, [Preview]>
    ) -> Self {
        PlainCommand { payload in
            let allMusicTypes: Set<String> = [Album.previewType, Playlist.previewType, Song.previewType]
            let musicTypes = payload.types.map { allMusicTypes.intersection($0) } ?? allMusicTypes
            let previewInput = PreviewQueryInput(term: payload.term, types: musicTypes)
            let noteInput = NoteQueryPayload(term: payload.term, types: musicTypes)

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
                noteSearch: request.commands.notes.search,
                previewSearch: request.commands.previews.list
            )
        }
    }
}
