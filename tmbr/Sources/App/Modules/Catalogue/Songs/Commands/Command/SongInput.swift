import Foundation
import Vapor
import AuthKit
import Core

struct SongInput {
    
    fileprivate let access: Access
    
    fileprivate let album: String?
    
    fileprivate let artist: String
        
    fileprivate let artwork: ImageID?
    
    fileprivate let genre: String?
        
    fileprivate let releaseDate: Date?
    
    fileprivate let resourceURLs: [String]
    
    fileprivate let title: String
    
    init(
        access: Access,
        album: String?,
        artist: String,
        artwork: ImageID?,
        genre: String?,
        releaseDate: Date?,
        resourceURLs: [String],
        title: String
    ) {
        self.access = access
        self.album = album
        self.artist = artist
        self.artwork = artwork
        self.genre = genre
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.title = title
    }
    
    init(payload: SongPayload) {
        self.init(
            access: payload.access,
            album: payload.album,
            artist: payload.artist,
            artwork: payload.artwork,
            genre: payload.genre,
            releaseDate: payload.releaseDate,
            resourceURLs: payload.resourceURLs,
            title: payload.title
        )
    }
}

extension ModelConfiguration where Model == Song, Parameters == SongInput {
    
    static var song: Self {
        ModelConfiguration { song, input in
            song.access = input.access
            song.album = input.album
            song.artist = input.artist
            song.$artwork.id = input.artwork
            song.genre = input.genre
            song.releaseDate = input.releaseDate
            song.resourceURLs = input.resourceURLs
            song.title = input.title
        }
    }
}

extension Validator where Input == SongInput {
    
    static var song: Self {
        Validator { song in
            guard !song.title.trimmed.isEmpty,
                  !song.artist.trimmed.isEmpty else {
                throw Abort(.badRequest, reason: "The song title or artist name is missing")
            }
        }
    }
}
