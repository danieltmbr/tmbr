import Vapor
import Foundation
import AuthKit

struct BookResponse: Encodable, Sendable {
    
    private let id: Int
    
    private let access: Access
    
    private let author: String
    
    private let cover: ImageResponse?
    
    private let genre: String?
    
    private let notes: [NoteResponse]
    
    private let owner: UserResponse
    
    private let preview: PreviewResponse
    
    private let post: PostResponse?
    
    private let releaseDate: Date?
    
    private let resources: [Resource]

    private let title: String
    
    init(
        id: Int,
        access: Access,
        author: String,
        cover: ImageResponse?,
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
        self.author = author
        self.cover = cover
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
        book: Book,
        baseURL: String,
        notes: [Note],
        platform: Platform<Book> = .all
    ) {
        self.init(
            id: book.id!,
            access: book.access,
            author: book.author,
            cover: book.cover.map { ImageResponse(image: $0, baseURL: baseURL) },
            genre: book.genre,
            notes: notes.map { NoteResponse(note: $0, baseURL: baseURL) },
            owner: UserResponse(user: book.owner),
            preview: PreviewResponse(preview: book.preview, baseURL: baseURL),
            post: book.post.map { PostResponse(post: $0, baseURL: baseURL) },
            releaseDate: book.releaseDate,
            resources: book.resourceURLs.compactMap(platform.resource),
            title: book.title
        )
    }
}
