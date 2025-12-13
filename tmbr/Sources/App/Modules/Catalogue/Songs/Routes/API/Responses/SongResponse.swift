import Vapor
import Foundation
import AuthKit

struct SongResponse: Encodable, Sendable {
    
    private let id: SongID
    
    private let access: Access
    
    private let album: String?
    
    private let artist: String
    
    private let artwork: ImageResponse?
    
    private let genre: String?
    
    private let notes: [NoteResponse]
    
    private let owner: UserResponse
            
    private let preview: PreviewResponse
    
    private let post: PostResponse?
    
    private let releaseDate: Date?
    
    private let resources: [Resource]
    
    private let title: String

    init(
        id: SongID,
        access: Access,
        album: String?,
        artist: String,
        artwork: ImageResponse?,
        genre: String?,
        notes: [NoteResponse],
        owner: UserResponse,
        preview: PreviewResponse,
        post: PostResponse?,
        releaseDate: Date?,
        resources: [Resource],
        title: String
    ) {
        self.id = id
        self.access = access
        self.album = album
        self.artist = artist
        self.artwork = artwork
        self.genre = genre
        self.notes = notes
        self.owner = owner
        self.preview = preview
        self.post = post
        self.releaseDate = releaseDate
        self.resources = resources
        self.title = title
    }
    
    init(
        song: Song,
        baseURL: String,
        notes: [Note],
        platform: Platform<Song> = .all
    ) {
        self.init(
            id: song.id!,
            access: song.access,
            album: song.album,
            artist: song.artist,
            artwork: song.artwork.map { ImageResponse(image: $0, baseURL: baseURL) },
            genre: song.genre,
            notes: notes.map { NoteResponse(note: $0, baseURL: baseURL) },
            owner: UserResponse(user: song.owner),
            preview: PreviewResponse(preview: song.preview, baseURL: baseURL),
            post: song.post.map { PostResponse(post: $0, baseURL: baseURL) },
            releaseDate: song.releaseDate,
            resources: song.resourceURLs.compactMap(platform.resource),
            title: song.title
        )
    }
}
