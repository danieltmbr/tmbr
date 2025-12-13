import Vapor
import Foundation
import AuthKit
import Core

struct SongViewModel: Encodable, Sendable {
    
    private let id: SongID
    
    private let album: String?
    
    private let artist: String
    
    private let artwork: ImageViewModel?
    
    private let genre: String?
    
    private let notes: [NoteViewModel]
    
    private let post: PostItemViewModel?
    
    private let releaseDate: String?
    
    private let resources: [ResourceViewModel]
    
    private let title: String
    
    init(
        id: SongID,
        album: String?,
        artist: String,
        artwork: ImageViewModel?,
        genre: String?,
        notes: [NoteViewModel],
        post: PostItemViewModel?,
        releaseDate: String?,
        resources: [ResourceViewModel],
        title: String
    ) {
        self.id = id
        self.album = album
        self.artist = artist
        self.artwork = artwork
        self.genre = genre
        self.notes = notes
        self.post = post
        self.releaseDate = releaseDate
        self.resources = resources
        self.title = title
    }
    
    init(
        song: Song,
        notes: [Note],
        baseURL: String,
        platform: Platform<Song> = .all
    ) throws {
        self.init(
            id: try song.requireID(),
            album: song.album,
            artist: song.artist,
            artwork: song.artwork.flatMap {
                ImageViewModel(image: $0, baseURL: baseURL)
            },
            genre: song.genre,
            notes: try notes.map {
                NoteViewModel(
                    id: try $0.requireID(),
                    body: $0.body,
                    created: $0.createdAt!.formatted(.publishDate)
                )
            },
            post: try song.post.map {
                PostItemViewModel(
                    id: try $0.requireID(),
                    title: $0.title,
                    publishDate: $0.createdAt.formatted(.publishDate)
                )
            },
            releaseDate: song.releaseDate?.formatted(.releaseDate),
            resources: song.resourceURLs.compactMap {
                guard let resource = platform.resource(from: $0) else { return nil }
                return ResourceViewModel(resource: resource)
            },
            title: song.title
        )
    }
}

extension Template where Model == SongViewModel {
    static let song = Template(name: "Catalogue/Songs/song")
}

extension Page {
    static var song: Self {
        Page(template: .song) { request in
            guard let songID = request.parameters.get("songID", as: Int.self) else {
                throw Abort(.badRequest)
            }
            return try await request.commands.transaction { commands in
                async let song = commands.songs.fetch(songID, for: .read)
                async let notes = commands.notes.query(id: songID, of: Song.previewType)
                
                return try SongViewModel(
                    song: await song,
                    notes: await notes,
                    baseURL: request.baseURL
                )
            }
        }
    }
}
