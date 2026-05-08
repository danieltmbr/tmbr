import Foundation
import Core

struct CatalogueSearchResult: Sendable {
    let previews: [Preview]
    let noteMatches: [Preview]
}

extension Command where Self == PlainCommand<CatalogueQueryPayload, CatalogueSearchResult> {
    static func searchCatalogue(
        previewSearch: CommandResolver<PreviewQueryInput, [Preview]>,
        noteSearch: CommandResolver<NoteQueryPayload, [Note]>
    ) -> Self {
        let mapper = CatalogueQueryMapper()
        return PlainCommand { payload in
            let previewInput = mapper.toPreviewQuery(from: payload)
            let noteInput = mapper.toNotesQuery(from: payload)

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

            return CatalogueSearchResult(previews: previews, noteMatches: noteMatches)
        }
    }
}

extension CommandFactory<CatalogueQueryPayload, CatalogueSearchResult> {
    static var searchCatalogue: Self {
        CommandFactory { request in
            .searchCatalogue(
                previewSearch: request.commands.previews.list,
                noteSearch: request.commands.notes.search
            )
        }
    }
}
