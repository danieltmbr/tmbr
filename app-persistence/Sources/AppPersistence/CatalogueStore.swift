import Foundation
import SwiftData
import TmbrCore

/// Any typed catalogue response carries a `preview` projection, embedded `notes`, and an `access`.
/// Conforming the DTOs lets the Store share Preview + note handling across all six types.
public protocol CatalogueItemResponse {
    var preview: PreviewResponse { get }
    var notes: [NoteResponse] { get }
    var access: Access { get }
}

extension SongResponse: CatalogueItemResponse {}
extension AlbumResponse: CatalogueItemResponse {}
extension BookResponse: CatalogueItemResponse {}
extension MovieResponse: CatalogueItemResponse {}
extension PodcastResponse: CatalogueItemResponse {}
extension PlaylistResponse: CatalogueItemResponse {}

/// A persistence façade for the unified catalogue (previews, per-type records, notes, and quotes).
///
/// Wraps a SwiftData `ModelContext`. Folding `context.save()` into each call keeps callers
/// free of dual-step save boilerplate.
@MainActor
public struct CatalogueStore {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Public API

    public func upsert(_ responses: [SongResponse]) throws {
        var previews = try previewsByID()
        var notes = try notesByPreview()
        var quotes = try quotesByNoteServerID()
        var typed = try typedIndex(SongRecord.self, key: \.previewID)
        for r in responses {
            guard let pid = upsertItem(r, into: &previews, notes: &notes, quotes: &quotes) else { continue }
            let record = typed[pid] ?? {
                let new = SongRecord(previewID: pid)
                context.insert(new)
                typed[pid] = new
                return new
            }()
            record.update(from: r)
        }
        try context.save()
    }

    public func upsert(_ responses: [AlbumResponse]) throws {
        var previews = try previewsByID()
        var notes = try notesByPreview()
        var quotes = try quotesByNoteServerID()
        var typed = try typedIndex(AlbumRecord.self, key: \.previewID)
        var containers = try containerEntriesByKey()
        for r in responses {
            guard let pid = upsertItem(r, into: &previews, notes: &notes, quotes: &quotes) else { continue }
            let record = typed[pid] ?? {
                let new = AlbumRecord(previewID: pid)
                context.insert(new)
                typed[pid] = new
                return new
            }()
            record.update(from: r)
            reconcileTracks(r.tracks, containerType: "album", containerSourceID: r.id, into: &containers)
        }
        try context.save()
    }

    public func upsert(_ responses: [BookResponse]) throws {
        var previews = try previewsByID()
        var notes = try notesByPreview()
        var quotes = try quotesByNoteServerID()
        var typed = try typedIndex(BookRecord.self, key: \.previewID)
        for r in responses {
            guard let pid = upsertItem(r, into: &previews, notes: &notes, quotes: &quotes) else { continue }
            let record = typed[pid] ?? {
                let new = BookRecord(previewID: pid)
                context.insert(new)
                typed[pid] = new
                return new
            }()
            record.update(from: r)
        }
        try context.save()
    }

    public func upsert(_ responses: [MovieResponse]) throws {
        var previews = try previewsByID()
        var notes = try notesByPreview()
        var quotes = try quotesByNoteServerID()
        var typed = try typedIndex(MovieRecord.self, key: \.previewID)
        for r in responses {
            guard let pid = upsertItem(r, into: &previews, notes: &notes, quotes: &quotes) else { continue }
            let record = typed[pid] ?? {
                let new = MovieRecord(previewID: pid)
                context.insert(new)
                typed[pid] = new
                return new
            }()
            record.update(from: r)
        }
        try context.save()
    }

    public func upsert(_ responses: [PodcastResponse]) throws {
        var previews = try previewsByID()
        var notes = try notesByPreview()
        var quotes = try quotesByNoteServerID()
        var typed = try typedIndex(PodcastRecord.self, key: \.previewID)
        for r in responses {
            guard let pid = upsertItem(r, into: &previews, notes: &notes, quotes: &quotes) else { continue }
            let record = typed[pid] ?? {
                let new = PodcastRecord(previewID: pid)
                context.insert(new)
                typed[pid] = new
                return new
            }()
            record.update(from: r)
        }
        try context.save()
    }

    public func upsert(_ responses: [PlaylistResponse]) throws {
        var previews = try previewsByID()
        var notes = try notesByPreview()
        var quotes = try quotesByNoteServerID()
        var typed = try typedIndex(PlaylistRecord.self, key: \.previewID)
        var containers = try containerEntriesByKey()
        for r in responses {
            guard let pid = upsertItem(r, into: &previews, notes: &notes, quotes: &quotes) else { continue }
            let record = typed[pid] ?? {
                let new = PlaylistRecord(previewID: pid)
                context.insert(new)
                typed[pid] = new
                return new
            }()
            record.update(from: r)
            reconcileTracks(r.tracks, containerType: "playlist", containerSourceID: r.id, into: &containers)
        }
        try context.save()
    }

    /// Upserts a `CatalogueSearchResponse` — the combined result of a server-side catalogue search.
    ///
    /// `items` (title/subtitle matches) are upserted as `PreviewRecord`s without touching their
    /// notes. `notes` (body matches) are upserted along with their attachment preview, letting the
    /// app find note-body matches in future offline searches. Existing quotes for those notes are
    /// preserved — this path does not delete quotes absent from the search response.
    public func upsertSearch(_ response: CatalogueSearchResponse) throws {
        var previews = try previewsByID()
        // Upsert item matches (preview metadata only, no embedded notes from this path).
        for preview in response.items {
            upsertPreview(preview, access: .public, into: &previews)
        }
        // Upsert note matches with their attachment previews.
        var noteIndex: [UUID: NoteRecord] = [:]
        for record in try context.fetch(FetchDescriptor<NoteRecord>()) {
            if let sid = record.serverID { noteIndex[sid] = record }
        }
        for note in response.notes {
            // Ensure the note's attachment preview is stored.
            upsertPreview(note.attachment, access: .public, into: &previews)
            // Upsert the note record itself without touching its existing quotes.
            let record = noteIndex[note.id] ?? {
                let new = NoteRecord(serverID: note.id)
                context.insert(new)
                noteIndex[note.id] = new
                return new
            }()
            record.update(from: note, preview: note.attachment)
        }
        try context.save()
    }

    /// Upserts standalone `QuoteResponse`s (e.g. from a quotes search result) into `QuoteRecord`s.
    ///
    /// Language is set to unknown (empty string) for search results since the response carries no
    /// language field. It will be corrected on the next full catalogue/blog sync.
    /// Existing quote records are updated in place; new server IDs create fresh records.
    public func upsert(_ responses: [QuoteResponse]) throws {
        var byServerID: [UUID: QuoteRecord] = [:]
        for record in try context.fetch(FetchDescriptor<QuoteRecord>()) {
            byServerID[record.serverID] = record
        }
        for response in responses {
            let record = byServerID[response.id] ?? {
                let new = QuoteRecord()
                context.insert(new)
                byServerID[response.id] = new
                return new
            }()
            record.update(from: response)
            // Preserve existing language — `QuoteResponse` carries no language field.
            // `languageRaw` already has the right value if the quote was previously synced.
        }
        try context.save()
    }

    /// Searches the local SwiftData store for catalogue items and notes matching `term`.
    ///
    /// All filtering and text matching is done in the DB:
    /// - Previews: `PreviewRecord.search(term:categories:languages:)` — a composed predicate that
    ///   applies the text match on `primaryInfo`/`secondaryInfo` plus category and language filters.
    /// - Notes: `NoteRecord.search(term:languages:)` — body text + language filter.
    /// - Note→preview join is resolved via a targeted predicate fetch of only the IDs needed.
    ///
    /// Returns an empty array when `term` is blank.
    public func search(
        term: String,
        categories: Set<CatalogueCategory>,
        languages: Set<Language>
    ) throws -> [CatalogueSearchResult] {
        let trimmed = term.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }

        // 1. Fetch preview matches — text + category + language all applied in DB.
        let previewMatches = try context.fetch(FetchDescriptor<PreviewRecord>(
            predicate: PreviewRecord.search(term: trimmed, categories: categories, languages: languages),
            sortBy: [SortDescriptor(\.primaryInfo)]
        ))

        // 2. Fetch note-body matches — body text + language filter applied in DB.
        let noteMatches = try context.fetch(FetchDescriptor<NoteRecord>(
            predicate: NoteRecord.search(term: trimmed, languages: languages)
        ))

        // Seed results from preview matches.
        var seen = Set(previewMatches.map(\.id))
        var results = previewMatches.map { CatalogueSearchResult(preview: $0) }

        // 3. Resolve note matches to their PreviewRecord via a targeted predicate fetch of needed IDs.
        let neededPreviewIDs = Set(noteMatches.compactMap(\.attachmentPreviewID)).subtracting(seen)
        guard !neededPreviewIDs.isEmpty else { return results }

        let ids = Array(neededPreviewIDs)
        let additionalPreviews = try context.fetch(FetchDescriptor<PreviewRecord>(
            predicate: #Predicate { ids.contains($0.id) }
        ))
        let previewByID = Dictionary(uniqueKeysWithValues: additionalPreviews.map { ($0.id, $0) })

        let slugs = Array(categories.map(\.rawValue))
        for note in noteMatches {
            guard let previewID = note.attachmentPreviewID,
                  !seen.contains(previewID),
                  let preview = previewByID[previewID] else { continue }
            // Category filter applied here (cross-model join — not expressible in DB predicate).
            guard slugs.isEmpty || slugs.contains(preview.categoryType) else { continue }
            seen.insert(previewID)
            results.append(CatalogueSearchResult(preview: preview, noteSnippet: note.body))
        }

        return results
    }

    /// Full-replaces the catalogue category lookup table from the server's authoritative list.
    ///
    /// Upserts each incoming category by `slug` (the natural key); deletes any locally-stored
    /// category whose slug is absent from the server response. The server list is small and
    /// complete, so full-replace is safe and avoids delta-cursor complexity.
    public func replaceCategories(_ responses: [CategoryResponse]) throws {
        var bySlug: [String: CatalogueCategoryRecord] = [:]
        for record in try context.fetch(FetchDescriptor<CatalogueCategoryRecord>()) {
            bySlug[record.slug] = record
        }
        let incomingSlugs = Set(responses.map(\.slug))
        // Delete categories no longer on the server.
        for (slug, record) in bySlug where !incomingSlugs.contains(slug) {
            context.delete(record)
        }
        // Upsert incoming categories.
        for response in responses {
            let record = bySlug[response.slug] ?? {
                let new = CatalogueCategoryRecord()
                context.insert(new)
                bySlug[response.slug] = new
                return new
            }()
            record.update(from: response)
        }
        try context.save()
    }

    /// Upserts orphan items (`PreviewResponse` is their complete data; `?notes=true` embeds notes).
    public func upsertOrphans(_ responses: [PreviewResponse]) throws {
        var previews = try previewsByID()
        var notes = try notesByPreview()
        var quotes = try quotesByNoteServerID()
        for r in responses {
            guard let pid = upsertPreview(r, access: .public, into: &previews) else { continue }
            let embedded = r.notes ?? []
            reconcileNotes(embedded, for: r, into: &notes, quotes: &quotes)
            previews[pid]?.languages = Set(embedded.map(\.language))
        }
        try context.save()
    }

    // MARK: - Private: Indexes

    private func previewsByID() throws -> [UUID: PreviewRecord] {
        var index: [UUID: PreviewRecord] = [:]
        for record in try context.fetch(FetchDescriptor<PreviewRecord>()) { index[record.id] = record }
        return index
    }

    private func notesByPreview() throws -> [UUID: [NoteRecord]] {
        var index: [UUID: [NoteRecord]] = [:]
        for note in try context.fetch(FetchDescriptor<NoteRecord>()) {
            if let pid = note.attachmentPreviewID { index[pid, default: []].append(note) }
        }
        return index
    }

    private func quotesByNoteServerID() throws -> [UUID: [QuoteRecord]] {
        var index: [UUID: [QuoteRecord]] = [:]
        for quote in try context.fetch(FetchDescriptor<QuoteRecord>()) {
            if let nid = quote.noteServerID { index[nid, default: []].append(quote) }
        }
        return index
    }

    /// Builds an index of `ContainerEntryRecord`s keyed by `"\(containerType):\(containerSourceID)"`.
    private func containerEntriesByKey() throws -> [String: [ContainerEntryRecord]] {
        var index: [String: [ContainerEntryRecord]] = [:]
        for entry in try context.fetch(FetchDescriptor<ContainerEntryRecord>()) {
            let key = "\(entry.containerType):\(entry.containerSourceID)"
            index[key, default: []].append(entry)
        }
        return index
    }

    private func typedIndex<T: PersistentModel>(_ type: T.Type, key: KeyPath<T, UUID>) throws -> [UUID: T] {
        Dictionary(
            try context.fetch(FetchDescriptor<T>()).map { ($0[keyPath: key], $0) },
            uniquingKeysWith: { a, _ in a }
        )
    }

    // MARK: - Private: Upsert helpers

    @discardableResult
    private func upsertPreview(_ preview: PreviewResponse, access: Access, into index: inout [UUID: PreviewRecord]) -> UUID? {
        guard let id = preview.id else { return nil }
        let record = index[id] ?? {
            let new = PreviewRecord(id: id)
            context.insert(new)
            index[id] = new
            return new
        }()
        record.update(from: preview, access: access)
        return id
    }

    /// Item-level note reconcile: upsert embedded notes by `serverID`; drop this item's `.synced`
    /// notes absent from the incoming array (server-side blockquote removals); preserve
    /// locally-pending notes. Cascades `QuoteRecord` deletion when a note is removed.
    private func reconcileNotes(
        _ notes: [NoteResponse],
        for preview: PreviewResponse,
        into byPreview: inout [UUID: [NoteRecord]],
        quotes byNote: inout [UUID: [QuoteRecord]]
    ) {
        guard let previewID = preview.id else { return }
        let incomingIDs = Set(notes.map(\.id))
        var current = byPreview[previewID] ?? []

        current.removeAll { note in
            guard note.syncState == .synced, let sid = note.serverID, !incomingIDs.contains(sid) else {
                return false
            }
            // Cascade: delete this note's quotes before deleting the note.
            byNote[sid]?.forEach { context.delete($0) }
            byNote.removeValue(forKey: sid)
            context.delete(note)
            return true
        }

        for note in notes {
            let record = current.first { $0.serverID == note.id } ?? {
                let new = NoteRecord(serverID: note.id)
                context.insert(new)
                current.append(new)
                return new
            }()
            record.update(from: note, preview: preview)
            reconcileQuotes(note.quotes, forNoteServerID: note.id, language: note.language, into: &byNote)
        }

        byPreview[previewID] = current
    }

    /// Quote reconcile for a single note: upsert embedded quotes by `serverID`; delete `.synced`
    /// quotes absent from the incoming array (blockquote removed from note body).
    private func reconcileQuotes(
        _ quotes: [QuoteResponse],
        forNoteServerID noteID: NoteID,
        language: Language,
        into byNote: inout [UUID: [QuoteRecord]]
    ) {
        let incomingIDs = Set(quotes.map(\.id))
        var current = byNote[noteID] ?? []

        current.removeAll { quote in
            if quote.syncState == .synced, !incomingIDs.contains(quote.serverID) {
                context.delete(quote)
                return true
            }
            return false
        }

        for quote in quotes {
            let record = current.first { $0.serverID == quote.id } ?? {
                let new = QuoteRecord()
                context.insert(new)
                current.append(new)
                return new
            }()
            record.update(from: quote)
            record.language = language
        }

        byNote[noteID] = current
    }

    /// Track reconcile: mirrors `reconcileNotes` but for `ContainerEntryRecord`s within an album
    /// or playlist. Inserts new entries, updates existing ones, and deletes `.synced` entries
    /// absent from the incoming track list (server-side removes).
    private func reconcileTracks(
        _ tracks: [TrackItem],
        containerType: String,
        containerSourceID: Int,
        into byContainer: inout [String: [ContainerEntryRecord]]
    ) {
        let key = "\(containerType):\(containerSourceID)"
        let incomingIDs = Set(tracks.compactMap { UUID(uuidString: $0.previewID) })
        var current = byContainer[key] ?? []

        current.removeAll { entry in
            if entry.syncState == .synced, !incomingIDs.contains(entry.memberPreviewID) {
                context.delete(entry)
                return true
            }
            return false
        }

        for track in tracks {
            guard let memberID = UUID(uuidString: track.previewID) else { continue }
            let record = current.first { $0.memberPreviewID == memberID } ?? {
                let new = ContainerEntryRecord()
                context.insert(new)
                current.append(new)
                return new
            }()
            record.update(from: track, containerType: containerType, containerSourceID: containerSourceID)
        }

        byContainer[key] = current
    }

    private func upsertItem<R: CatalogueItemResponse>(
        _ response: R,
        into previews: inout [UUID: PreviewRecord],
        notes: inout [UUID: [NoteRecord]],
        quotes: inout [UUID: [QuoteRecord]]
    ) -> UUID? {
        guard let pid = upsertPreview(response.preview, access: response.access, into: &previews) else { return nil }
        reconcileNotes(response.notes, for: response.preview, into: &notes, quotes: &quotes)
        previews[pid]?.languages = Set(response.notes.map(\.language))
        return pid
    }
}
