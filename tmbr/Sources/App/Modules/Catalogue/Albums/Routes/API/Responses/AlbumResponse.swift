import Vapor
import Foundation
import AuthKit
import Core

struct AlbumResponse: Encodable, Sendable, AsyncResponseEncodable {

    private let id: AlbumID

    private let access: Access

    private let artist: String

    private let artwork: ImageResponse?

    private let genre: String?

    private let notes: [NoteResponse]

    private let owner: UserResponse

    private let preview: PreviewResponse

    private let post: PostResponse?

    private let releaseDate: Date?

    private let resources: [Hyperlink]

    private let title: String

    init(
        id: AlbumID,
        access: Access,
        artist: String,
        artwork: ImageResponse?,
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
        album: Album,
        notes: [Note],
        baseURL: String,
        platform: Platform<AlbumMetadata> = .album
    ) {
        self.init(
            id: album.id!,
            access: album.access,
            artist: album.artist,
            artwork: album.artwork.map { ImageResponse(image: $0, baseURL: baseURL) },
            genre: album.genre,
            notes: notes.map { NoteResponse(note: $0, baseURL: baseURL) },
            owner: UserResponse(user: album.owner),
            preview: PreviewResponse(preview: album.preview, baseURL: baseURL),
            post: album.post.map { PostResponse(post: $0, baseURL: baseURL) },
            releaseDate: album.releaseDate,
            resources: album.resourceURLs.compactMap(platform.hyperlink),
            title: album.title
        )
    }
}
