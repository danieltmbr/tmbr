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

/// A persistence façade for the unified catalogue (previews, per-type records, and notes).
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
        var typed = try typedIndex(SongRecord.self, key: \.previewID)
        for r in responses {
            guard let pid = upsertItem(r, into: &previews, notes: &notes) else { continue }
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
        var typed = try typedIndex(AlbumRecord.self, key: \.previewID)
        var containers = try containerEntriesByKey()
        for r in responses {
            guard let pid = upsertItem(r, into: &previews, notes: &notes) else { continue }
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
        var typed = try typedIndex(BookRecord.self, key: \.previewID)
        for r in responses {
            guard let pid = upsertItem(r, into: &previews, notes: &notes) else { continue }
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
        var typed = try typedIndex(MovieRecord.self, key: \.previewID)
        for r in responses {
            guard let pid = upsertItem(r, into: &previews, notes: &notes) else { continue }
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
        var typed = try typedIndex(PodcastRecord.self, key: \.previewID)
        for r in responses {
            guard let pid = upsertItem(r, into: &previews, notes: &notes) else { continue }
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
        var typed = try typedIndex(PlaylistRecord.self, key: \.previewID)
        var containers = try containerEntriesByKey()
        for r in responses {
            guard let pid = upsertItem(r, into: &previews, notes: &notes) else { continue }
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

    /// Upserts orphan items (`PreviewResponse` is their complete data; `?notes=true` embeds notes).
    public func upsertOrphans(_ responses: [PreviewResponse]) throws {
        var previews = try previewsByID()
        var notes = try notesByPreview()
        for r in responses {
            guard upsertPreview(r, access: .public, into: &previews) != nil else { continue }
            reconcileNotes(r.notes ?? [], for: r, into: &notes)
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
    /// notes absent from the incoming array (server-side deletes); preserve locally-pending notes.
    private func reconcileNotes(
        _ notes: [NoteResponse],
        for preview: PreviewResponse,
        into byPreview: inout [UUID: [NoteRecord]]
    ) {
        guard let previewID = preview.id else { return }
        let incomingIDs = Set(notes.map(\.id))
        var current = byPreview[previewID] ?? []

        current.removeAll { note in
            if note.syncState == .synced, let sid = note.serverID, !incomingIDs.contains(sid) {
                context.delete(note)
                return true
            }
            return false
        }

        for note in notes {
            let record = current.first { $0.serverID == note.id } ?? {
                let new = NoteRecord(serverID: note.id)
                context.insert(new)
                current.append(new)
                return new
            }()
            record.update(from: note, preview: preview)
        }

        byPreview[previewID] = current
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
        notes: inout [UUID: [NoteRecord]]
    ) -> UUID? {
        guard let pid = upsertPreview(response.preview, access: response.access, into: &previews) else { return nil }
        reconcileNotes(response.notes, for: response.preview, into: &notes)
        return pid
    }
}
