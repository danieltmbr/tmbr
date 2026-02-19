import Vapor
import Foundation
import AuthKit
import Core

struct SongViewModel: Encodable, Sendable {
    
    private let id: SongID
        
    private let artist: String
    
    private let artwork: ImageViewModel?
    
    private let info: String?
        
    private let notes: [NoteViewModel]
    
    private let post: PostItemViewModel?
        
    private let resources: [Hyperlink]
    
    private let title: String
    
    init(
        id: SongID,
        artist: String,
        artwork: ImageViewModel?,
        info: String?,
        notes: [NoteViewModel],
        post: PostItemViewModel?,
        resources: [Hyperlink],
        title: String
    ) {
        self.id = id
        self.artist = artist
        self.artwork = artwork
        self.info = info
        self.notes = notes
        self.post = post
        self.resources = resources
        self.title = title
    }
    
    init(
        id: SongID,
        album: String?,
        artist: String,
        artwork: ImageViewModel?,
        genre: String?,
        notes: [NoteViewModel],
        post: PostItemViewModel?,
        releaseDate: String?,
        resources: [Hyperlink],
        title: String,
        listFormatter: ListFormatter = .init()
    ) {
        self.init(
            id: id,
            artist: artist,
            artwork: artwork,
            info: listFormatter.string(from: [album, genre, releaseDate].compactMap(\.self)),
            notes: notes,
            post: post,
            resources: resources,
            title: title
        )
    }
    
    init(
        song: Song,
        notes: [Note],
        baseURL: String,
        platform: Platform<SongMetadata> = .song,
        listFormatter: ListFormatter = .init()
    ) throws {
        self.init(
            id: try song.requireID(),
            album: song.album,
            artist: song.artist,
            artwork: song.artwork.flatMap {
                ImageViewModel(image: $0, baseURL: baseURL)
            },
            genre: song.genre,
            notes: try notes.map(NoteViewModel.init),
            post: try song.post.map(PostItemViewModel.init),
            releaseDate: song.releaseDate?.formatted(.releaseDate),
            resources: song.resourceURLs.compactMap(platform.hyperlink),
            title: song.title,
            listFormatter: listFormatter
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
            async let song = request.commands.songs.fetch(songID, for: .read)
            async let notes = request.commands.notes.query(id: songID, of: Song.previewType)
            return try SongViewModel(
                song: await song,
                notes: await notes,
                baseURL: request.baseURL
            )
        }
    }
}
