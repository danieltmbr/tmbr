import Foundation
import Vapor
import WebAuth
import WebCore
import TmbrCore

struct AlbumInput {

    fileprivate let access: Access

    fileprivate let artist: String

    fileprivate let artwork: ImageID?

    fileprivate let genre: String?

    fileprivate let releaseDate: Date?

    fileprivate let resourceURLs: [String]

    fileprivate let title: String

    let tracks: [TrackMetadata]?

    init(
        access: Access,
        artist: String,
        artwork: ImageID?,
        genre: String?,
        releaseDate: Date?,
        resourceURLs: [String],
        title: String,
        tracks: [TrackMetadata]? = nil
    ) {
        self.access = access
        self.artist = artist
        self.artwork = artwork
        self.genre = genre
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.title = title
        self.tracks = tracks
    }

    init(payload: AlbumPayload) {
        self.init(
            access: payload.access,
            artist: payload.artist,
            artwork: payload.artwork,
            genre: payload.genre,
            releaseDate: payload.releaseDate,
            resourceURLs: payload.resourceURLs,
            title: payload.title
        )
    }
}

extension ModelConfiguration where Model == Album, Parameters == AlbumInput {

    static var album: Self {
        ModelConfiguration { album, input in
            album.access = input.access
            album.artist = input.artist
            album.$artwork.id = input.artwork
            album.genre = input.genre
            album.releaseDate = input.releaseDate
            album.resourceURLs = input.resourceURLs
            album.title = input.title
        }
    }
}

extension Validator where Input == AlbumInput {

    static var album: Self {
        Validator { album in
            guard !album.title.trimmed.isEmpty,
                  !album.artist.trimmed.isEmpty else {
                throw Abort(.badRequest, reason: "The album title or artist name is missing")
            }
        }
    }
}

extension AlbumInput {

    func edit(id: AlbumID) -> EditAlbumInput {
        EditAlbumInput(id: id, parameters: self)
    }
}
