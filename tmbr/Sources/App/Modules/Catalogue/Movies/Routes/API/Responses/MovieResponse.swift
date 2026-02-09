import Vapor
import Foundation
import AuthKit
import Core

struct MovieResponse: Encodable, Sendable {
    
    private let id: Int
    
    private let access: Access
    
    private let cover: ImageResponse?
    
    private let director: String?
    
    private let genre: String?
    
    private let notes: [NoteResponse]
    
    private let owner: UserResponse
    
    private let preview: PreviewResponse
    
    private let post: PostResponse?
    
    private let releaseDate: Date?
    
    private let resources: [Hyperlink]
    
    private let title: String
    
    init(
        id: Int,
        access: Access,
        cover: ImageResponse?,
        director: String?,
        genre: String?,
        notes: [NoteResponse],
        owner: UserResponse,
        preview: PreviewResponse,
        post: PostResponse?,
        releaseDate: Date?,
        resources: [Hyperlink],
        title: String
    ) {
        self.id = id
        self.access = access
        self.cover = cover
        self.director = director
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
        movie: Movie,
        baseURL: String,
        notes: [Note],
        platform: Platform<Movie> = .all
    ) {
        self.init(
            id: movie.id!,
            access: movie.access,
            cover: movie.cover.map { ImageResponse(image: $0, baseURL: baseURL) },
            director: movie.director,
            genre: movie.genre,
            notes: notes.map { NoteResponse(note: $0, baseURL: baseURL) },
            owner: UserResponse(user: movie.owner),
            preview: PreviewResponse(preview: movie.preview, baseURL: baseURL),
            post: movie.post.map { PostResponse(post: $0, baseURL: baseURL) },
            releaseDate: movie.releaseDate,
            resources: movie.resourceURLs.compactMap(platform.hyperlink),
            title: movie.title
        )
    }
}
