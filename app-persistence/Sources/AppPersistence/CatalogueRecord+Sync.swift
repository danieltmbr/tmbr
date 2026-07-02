import Foundation
import TmbrCore

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

public extension QuoteRecord {
    /// Overwrites this record from a server `QuoteResponse` (a synced pull).
    func update(from response: QuoteResponse) {
        serverID = response.id
        body = response.body
        createdAt = response.createdAt
        switch response.source.kind {
        case .note:
            if let noteID = response.source.noteID {
                source = .note(noteID)
            }
        case .post:
            if let postID = response.source.postID {
                source = .post(postID)
            }
        }
        sourceTitle = response.source.title
        sourceSubtitle = response.source.subtitle
        sourceType = response.source.type
        sourcePreviewID = response.source.preview?.id
        syncState = .synced
    }
}

public extension CatalogueCategoryRecord {
    /// Overwrites this record's fields from a server `CategoryResponse` (a synced pull).
    func update(from response: CategoryResponse) {
        serverID = response.id
        slug = response.slug
        name = response.name
        kind = response.kind
        route = response.route
        icon = response.icon
        parentSlug = response.parentSlug
        syncState = .synced
    }
}

public extension ContainerEntryRecord {
    /// Overwrites this entry's fields from a `TrackItem`. Denormalises the title and URLs so
    /// the track list renders standalone without requiring the member's `PreviewRecord` to be cached.
    func update(from track: TrackItem, containerType: String, containerSourceID: Int) {
        self.containerType = containerType
        self.containerSourceID = containerSourceID
        if let id = UUID(uuidString: track.previewID) {
            memberPreviewID = id
        }
        position = track.position
        title = track.title
        trackURL = track.trackURL
        href = track.href
        syncState = .synced
    }
}
