import Foundation
import Core

private let musicTypes: Set<String> = [
    Album.previewType,
    Playlist.previewType,
    Song.previewType,
]

struct MusicSearchResult: Sendable {
    let previews: [Preview]
    let noteMatches: [Preview]
}

extension Command where Self == PlainCommand<String?, MusicSearchResult> {

    static func searchMusic(
        noteSearch: CommandResolver<NoteQueryPayload, [Note]>,
        previewSearch: CommandResolver<PreviewQueryInput, [Preview]>
    ) -> Self {
        PlainCommand { term in
            let previewInput = PreviewQueryInput(term: term, types: musicTypes)
            let noteInput = NoteQueryPayload(term: term, types: musicTypes)

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

extension CommandFactory<String?, MusicSearchResult> {

    static var searchMusic: Self {
        CommandFactory { request in
            .searchMusic(
                noteSearch: request.commands.notes.search,
                previewSearch: request.commands.previews.list
            )
        }
    }
}
