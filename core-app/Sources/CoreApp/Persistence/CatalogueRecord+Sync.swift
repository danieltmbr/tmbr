import Foundation
import CoreTmbr

// Pure single-record field mapping from server DTOs — used by CatalogueStore.
// Each method mirrors PostRecord.update(from:) in PostRecord+Sync.swift.
// No ModelContext, no fetching, no saving — just field assignment.

public extension PreviewRecord {
    /// Overwrites this record's fields from a server `PreviewResponse`.
    func update(from preview: PreviewResponse, access: Access) {
        // `category` is set only for orphans; typed items fall back to the source type.
        categoryType = preview.category ?? preview.source.type
        sourceID = preview.source.id
        primaryInfo = preview.primaryInfo
        secondaryInfo = preview.secondaryInfo
        imageURL = preview.image?.url
        externalLinks = preview.resources
        self.access = access
        syncState = .synced
    }
}

public extension NoteRecord {
    /// Overwrites this record from a server `NoteResponse`, denormalizing the parent preview fields.
    func update(from note: NoteResponse, preview: PreviewResponse) {
        serverID = note.id
        body = note.body
        access = note.access
        language = note.language
        createdAt = note.created
        attachmentPreviewID = preview.id
        attachmentTitle = preview.primaryInfo
        attachmentSubtitle = preview.secondaryInfo
        attachmentCategoryType = preview.category ?? preview.source.type
        attachmentSourceID = preview.source.id
        syncState = .synced
    }
}

public extension SongRecord {
    func update(from response: SongResponse) {
        sourceID = response.id
        title = response.title
        artist = response.artist
        album = response.album
        genre = response.genre
        releaseDate = response.releaseDate
        artworkURL = response.artwork?.url
        resourceURLs = response.resources.map(\.urlString)
        access = response.access
        syncState = .synced
    }
}

public extension AlbumRecord {
    func update(from response: AlbumResponse) {
        sourceID = response.id
        title = response.title
        artist = response.artist
        genre = response.genre
        releaseDate = response.releaseDate
        artworkURL = response.artwork?.url
        resourceURLs = response.resources.map(\.urlString)
        access = response.access
        syncState = .synced
    }
}

public extension BookRecord {
    func update(from response: BookResponse) {
        sourceID = response.id
        title = response.title
        author = response.author
        genre = response.genre
        releaseDate = response.releaseDate
        coverURL = response.cover?.url
        resourceURLs = response.resources.map(\.urlString)
        access = response.access
        syncState = .synced
    }
}

public extension MovieRecord {
    func update(from response: MovieResponse) {
        sourceID = response.id
        title = response.title
        director = response.director
        genre = response.genre
        releaseDate = response.releaseDate
        coverURL = response.cover?.url
        resourceURLs = response.resources.map(\.urlString)
        access = response.access
        syncState = .synced
    }
}

public extension PodcastRecord {
    func update(from response: PodcastResponse) {
        sourceID = response.id
        title = response.title
        episodeTitle = response.episodeTitle
        episodeNumber = response.episodeNumber
        seasonNumber = response.seasonNumber
        genre = response.genre
        releaseDate = response.releaseDate
        artworkURL = response.artwork?.url
        resourceURLs = response.resources.map(\.urlString)
        access = response.access
        syncState = .synced
    }
}

public extension PlaylistRecord {
    func update(from response: PlaylistResponse) {
        sourceID = response.id
        title = response.title
        playlistDescription = response.description
        artworkURL = response.artwork?.url
        resourceURLs = response.resources.map(\.urlString)
        access = response.access
        syncState = .synced
    }
}
