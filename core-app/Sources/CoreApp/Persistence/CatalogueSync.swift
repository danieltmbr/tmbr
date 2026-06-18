import Foundation
import SwiftData
import CoreTmbr

/// Any typed catalogue response carries a `preview` projection, embedded `notes`, and an `access`.
/// Conforming the DTOs lets the upsert share the Preview + note handling across all six types.
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

// MARK: - Shared: PreviewRecord + NoteRecord

public extension PreviewRecord {

    static func indexByID(_ context: ModelContext) throws -> [UUID: PreviewRecord] {
        var index: [UUID: PreviewRecord] = [:]
        for record in try context.fetch(FetchDescriptor<PreviewRecord>()) { index[record.id] = record }
        return index
    }

    /// Upsert the unified projection (the catalogue list row + note anchor). Returns the PreviewID.
    @discardableResult
    static func upsert(
        _ preview: PreviewResponse,
        access: Access,
        in context: ModelContext,
        index: inout [UUID: PreviewRecord]
    ) -> UUID? {
        guard let id = preview.id else { return nil }
        let record = index[id] ?? {
            let new = PreviewRecord(id: id)
            context.insert(new)
            index[id] = new
            return new
        }()
        // `category` is set only for orphans; typed items fall back to the source type.
        record.categoryType = preview.category ?? preview.source.type
        record.sourceID = preview.source.id
        record.primaryInfo = preview.primaryInfo
        record.secondaryInfo = preview.secondaryInfo
        record.imageURL = preview.image?.url
        record.externalLinks = preview.resources
        record.access = access
        record.syncState = .synced
        return id
    }

    /// Upsert orphan items (`PreviewResponse` is their complete data; `?notes=true` embeds notes).
    static func upsertOrphans(_ responses: [PreviewResponse], in context: ModelContext) throws {
        var previews = try indexByID(context)
        var notes = try NoteRecord.indexByPreview(context)
        for preview in responses {
            guard upsert(preview, access: .public, in: context, index: &previews) != nil else { continue }
            NoteRecord.reconcile(preview.notes ?? [], for: preview, in: context, byPreview: &notes)
        }
    }
}

public extension NoteRecord {

    static func indexByPreview(_ context: ModelContext) throws -> [UUID: [NoteRecord]] {
        var index: [UUID: [NoteRecord]] = [:]
        for note in try context.fetch(FetchDescriptor<NoteRecord>()) {
            if let previewID = note.attachmentPreviewID { index[previewID, default: []].append(note) }
        }
        return index
    }

    /// Item-level reconcile: upsert the embedded notes by `serverID` and drop this item's `.synced`
    /// notes that are absent from the array (server-side deletes). Locally-pending notes are preserved.
    static func reconcile(
        _ notes: [NoteResponse],
        for preview: PreviewResponse,
        in context: ModelContext,
        byPreview: inout [UUID: [NoteRecord]]
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
            record.serverID = note.id
            record.body = note.body
            record.access = note.access
            record.language = note.language
            record.createdAt = note.created
            record.attachmentPreviewID = previewID
            record.attachmentTitle = preview.primaryInfo
            record.attachmentSubtitle = preview.secondaryInfo
            record.attachmentCategoryType = preview.category ?? preview.source.type
            record.attachmentSourceID = preview.source.id
            record.syncState = .synced
        }

        byPreview[previewID] = current
    }
}

/// Upserts the shared `PreviewRecord` + reconciles notes for one typed response; returns its PreviewID.
private func upsertShared<R: CatalogueItemResponse>(
    _ response: R,
    in context: ModelContext,
    previews: inout [UUID: PreviewRecord],
    notes: inout [UUID: [NoteRecord]]
) -> UUID? {
    guard let id = PreviewRecord.upsert(response.preview, access: response.access, in: context, index: &previews) else {
        return nil
    }
    NoteRecord.reconcile(response.notes, for: response.preview, in: context, byPreview: &notes)
    return id
}

// MARK: - Per-type records

public extension SongRecord {
    static func upsert(_ responses: [SongResponse], in context: ModelContext) throws {
        var previews = try PreviewRecord.indexByID(context)
        var notes = try NoteRecord.indexByPreview(context)
        var typed: [UUID: SongRecord] = Dictionary(
            (try context.fetch(FetchDescriptor<SongRecord>())).map { ($0.previewID, $0) },
            uniquingKeysWith: { a, _ in a }
        )
        for response in responses {
            guard let pid = upsertShared(response, in: context, previews: &previews, notes: &notes) else { continue }
            let record = typed[pid] ?? {
                let new = SongRecord(previewID: pid)
                context.insert(new)
                typed[pid] = new
                return new
            }()
            record.previewID = pid
            record.sourceID = response.id
            record.title = response.title
            record.artist = response.artist
            record.album = response.album
            record.genre = response.genre
            record.releaseDate = response.releaseDate
            record.artworkURL = response.artwork?.url
            record.resourceURLs = response.resources.map(\.urlString)
            record.access = response.access
            record.syncState = .synced
        }
    }
}

public extension AlbumRecord {
    static func upsert(_ responses: [AlbumResponse], in context: ModelContext) throws {
        var previews = try PreviewRecord.indexByID(context)
        var notes = try NoteRecord.indexByPreview(context)
        var typed: [UUID: AlbumRecord] = Dictionary(
            (try context.fetch(FetchDescriptor<AlbumRecord>())).map { ($0.previewID, $0) },
            uniquingKeysWith: { a, _ in a }
        )
        for response in responses {
            guard let pid = upsertShared(response, in: context, previews: &previews, notes: &notes) else { continue }
            let record = typed[pid] ?? {
                let new = AlbumRecord(previewID: pid)
                context.insert(new)
                typed[pid] = new
                return new
            }()
            record.previewID = pid
            record.sourceID = response.id
            record.title = response.title
            record.artist = response.artist
            record.genre = response.genre
            record.releaseDate = response.releaseDate
            record.artworkURL = response.artwork?.url
            record.resourceURLs = response.resources.map(\.urlString)
            record.access = response.access
            record.syncState = .synced
        }
    }
}

public extension BookRecord {
    static func upsert(_ responses: [BookResponse], in context: ModelContext) throws {
        var previews = try PreviewRecord.indexByID(context)
        var notes = try NoteRecord.indexByPreview(context)
        var typed: [UUID: BookRecord] = Dictionary(
            (try context.fetch(FetchDescriptor<BookRecord>())).map { ($0.previewID, $0) },
            uniquingKeysWith: { a, _ in a }
        )
        for response in responses {
            guard let pid = upsertShared(response, in: context, previews: &previews, notes: &notes) else { continue }
            let record = typed[pid] ?? {
                let new = BookRecord(previewID: pid)
                context.insert(new)
                typed[pid] = new
                return new
            }()
            record.previewID = pid
            record.sourceID = response.id
            record.title = response.title
            record.author = response.author
            record.genre = response.genre
            record.releaseDate = response.releaseDate
            record.coverURL = response.cover?.url
            record.resourceURLs = response.resources.map(\.urlString)
            record.access = response.access
            record.syncState = .synced
        }
    }
}

public extension MovieRecord {
    static func upsert(_ responses: [MovieResponse], in context: ModelContext) throws {
        var previews = try PreviewRecord.indexByID(context)
        var notes = try NoteRecord.indexByPreview(context)
        var typed: [UUID: MovieRecord] = Dictionary(
            (try context.fetch(FetchDescriptor<MovieRecord>())).map { ($0.previewID, $0) },
            uniquingKeysWith: { a, _ in a }
        )
        for response in responses {
            guard let pid = upsertShared(response, in: context, previews: &previews, notes: &notes) else { continue }
            let record = typed[pid] ?? {
                let new = MovieRecord(previewID: pid)
                context.insert(new)
                typed[pid] = new
                return new
            }()
            record.previewID = pid
            record.sourceID = response.id
            record.title = response.title
            record.director = response.director
            record.genre = response.genre
            record.releaseDate = response.releaseDate
            record.coverURL = response.cover?.url
            record.resourceURLs = response.resources.map(\.urlString)
            record.access = response.access
            record.syncState = .synced
        }
    }
}

public extension PodcastRecord {
    static func upsert(_ responses: [PodcastResponse], in context: ModelContext) throws {
        var previews = try PreviewRecord.indexByID(context)
        var notes = try NoteRecord.indexByPreview(context)
        var typed: [UUID: PodcastRecord] = Dictionary(
            (try context.fetch(FetchDescriptor<PodcastRecord>())).map { ($0.previewID, $0) },
            uniquingKeysWith: { a, _ in a }
        )
        for response in responses {
            guard let pid = upsertShared(response, in: context, previews: &previews, notes: &notes) else { continue }
            let record = typed[pid] ?? {
                let new = PodcastRecord(previewID: pid)
                context.insert(new)
                typed[pid] = new
                return new
            }()
            record.previewID = pid
            record.sourceID = response.id
            record.title = response.title
            record.episodeTitle = response.episodeTitle
            record.episodeNumber = response.episodeNumber
            record.seasonNumber = response.seasonNumber
            record.genre = response.genre
            record.releaseDate = response.releaseDate
            record.artworkURL = response.artwork?.url
            record.resourceURLs = response.resources.map(\.urlString)
            record.access = response.access
            record.syncState = .synced
        }
    }
}

public extension PlaylistRecord {
    static func upsert(_ responses: [PlaylistResponse], in context: ModelContext) throws {
        var previews = try PreviewRecord.indexByID(context)
        var notes = try NoteRecord.indexByPreview(context)
        var typed: [UUID: PlaylistRecord] = Dictionary(
            (try context.fetch(FetchDescriptor<PlaylistRecord>())).map { ($0.previewID, $0) },
            uniquingKeysWith: { a, _ in a }
        )
        for response in responses {
            guard let pid = upsertShared(response, in: context, previews: &previews, notes: &notes) else { continue }
            let record = typed[pid] ?? {
                let new = PlaylistRecord(previewID: pid)
                context.insert(new)
                typed[pid] = new
                return new
            }()
            record.previewID = pid
            record.sourceID = response.id
            record.title = response.title
            record.playlistDescription = response.description
            record.artworkURL = response.artwork?.url
            record.resourceURLs = response.resources.map(\.urlString)
            record.access = response.access
            record.syncState = .synced
        }
    }
}
