import Foundation
import WebCore

/// Web-internal input for a catalogue search.
struct CatalogueSearchInput: Sendable {

    let payload: CatalogueQueryPayload

    /// "Return only items created before this date" — the decoded form of the opaque `cursor` string.
    let before: Date?

    /// Maximum results per page. `nil` means no limit — used by web pages that display all results
    /// without pagination. Native API callers always supply a non-nil limit.
    let limit: Int?
}

// MARK: -

struct CatalogueSearchResult: Sendable {

    let previews: [Preview]

    /// Notes whose body matched the search term. De-duplicated against `previews` so items
    /// whose title/subtitle also matched don't appear twice. Each note carries its eagerly-loaded
    /// `attachment`, `author`, and `quotes` — enough to build a full `NoteResponse`.
    let noteMatches: [Note]

    /// The `createdAt` of the last item in this page. Pass as the `cursor` in the next request.
    /// `nil` when this is the final page or when no limit was requested.
    let nextCursor: Date?
}

// MARK: - Merge helper

/// Wraps a single catalogue search result item (preview or note) with its creation date for
/// merge-sorting. Defined at file scope to avoid the "type cannot be nested in closure in generic
/// context" limitation.
private enum CatalogueSearchEntry {
    case preview(Preview, Date)
    case note(Note, Date)

    var date: Date {
        switch self {
        case .preview(_, let d): return d
        case .note(_, let d): return d
        }
    }
}

// MARK: -

extension Command where Self == PlainCommand<CatalogueSearchInput, CatalogueSearchResult> {

    /// Cross-entity catalogue search, optionally paginated.
    ///
    /// When `input.limit` is set: fetches `limit + 1` items from each sub-query, merge-sorts by
    /// `createdAt desc`, takes `limit` items, and returns the oldest item's `createdAt` as the next
    /// cursor. When `limit` is nil (web page path): fetches with no cap and returns all results.
    static func searchCatalogue(
        mapper: CatalogueQueryMapper = CatalogueQueryMapper(),
        noteSearch: CommandResolver<NoteQueryPayload, [Note]>,
        previewSearch: CommandResolver<PreviewQueryInput, [Preview]>
    ) -> Self {
        PlainCommand { input in
            // fetchLimit is limit+1 (to detect hasMore) when paging; nil when no limit.
            let fetchLimit = input.limit.map { $0 + 1 }

            // Build sub-queries, layering in the cursor bound and fetch limit.
            let basePreviews = mapper.toPreviewQuery(from: input.payload)
            let baseNotes = mapper.toNotesQuery(from: input.payload)
            let previewInput = PreviewQueryInput(
                term: basePreviews.term,
                categoryIDs: basePreviews.categoryIDs,
                before: input.before,
                limit: fetchLimit
            )
            let noteInput = NoteQueryPayload(
                term: baseNotes.term,
                categoryIDs: baseNotes.categoryIDs,
                categorySlug: baseNotes.categorySlug,
                languages: baseNotes.languages,
                before: input.before,
                limit: fetchLimit
            )

            async let previewsTask = previewSearch(previewInput)
            async let notesTask = noteSearch(noteInput)
            let (allPreviews, allNotes) = try await (previewsTask, notesTask)

            // De-dup: skip notes whose attachment preview already appears in the preview results.
            let previewIDs = Set(allPreviews.compactMap(\.id))
            var seen = previewIDs
            let uniqueNotes = allNotes.compactMap { note -> Note? in
                guard let id = note.attachment.id, !seen.contains(id) else { return nil }
                seen.insert(id)
                return note
            }

            // Tag each item with its createdAt for the merge.
            let taggedPreviews: [CatalogueSearchEntry] = allPreviews.map { .preview($0, $0.createdAt) }
            let taggedNotes: [CatalogueSearchEntry] = uniqueNotes.map { .note($0, $0.createdAt) }

            // Both sub-arrays are already sorted descending by the DB; merge them in one pass.
            var merged: [CatalogueSearchEntry] = []
            merged.reserveCapacity(taggedPreviews.count + taggedNotes.count)
            var pi = taggedPreviews.startIndex, ni = taggedNotes.startIndex
            while pi < taggedPreviews.endIndex && ni < taggedNotes.endIndex {
                if taggedPreviews[pi].date >= taggedNotes[ni].date {
                    merged.append(taggedPreviews[pi])
                    pi += 1
                } else {
                    merged.append(taggedNotes[ni])
                    ni += 1
                }
            }
            merged.append(contentsOf: taggedPreviews[pi...])
            merged.append(contentsOf: taggedNotes[ni...])

            // If a limit is set, take the page and compute the next cursor.
            // If limit is nil (web pages), return all results with no cursor.
            let page: [CatalogueSearchEntry]
            let nextCursor: Date?
            if let limit = input.limit {
                page = Array(merged.prefix(limit))
                nextCursor = merged.count > limit ? page.last?.date : nil
            } else {
                page = merged
                nextCursor = nil
            }

            var previews: [Preview] = []
            var noteMatches: [Note] = []
            for entry in page {
                switch entry {
                case .preview(let p, _): previews.append(p)
                case .note(let n, _): noteMatches.append(n)
                }
            }

            return CatalogueSearchResult(previews: previews, noteMatches: noteMatches, nextCursor: nextCursor)
        }
    }
}

extension CommandFactory<CatalogueSearchInput, CatalogueSearchResult> {

    static var searchCatalogue: Self {
        CommandFactory { request in
            .searchCatalogue(
                noteSearch: request.commands.notes.search,
                previewSearch: request.commands.previews.list
            )
        }
    }
}
