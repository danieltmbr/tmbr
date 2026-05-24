import Vapor
import Foundation
import AuthKit
import Core

struct PlaylistResponse: Encodable, Sendable, AsyncResponseEncodable {

    private let id: PlaylistID

    private let access: Access

    private let artwork: ImageResponse?

    private let description: String?

    private let notes: [NoteResponse]

    private let owner: UserResponse

    private let preview: PreviewResponse

    private let post: PostResponse?

    private let resources: [Hyperlink]

    private let title: String

    init(
        id: PlaylistID,
        access: Access,
        artwork: ImageResponse?,
        description: String?,
        notes: [NoteResponse],
        owner: UserResponse,
        preview: PreviewResponse,
        post: PostResponse?,
        resources: [Hyperlink],
        title: String
    ) {
        self.id = id
        self.access = access
        self.artwork = artwork
        self.description = description
        self.notes = notes
        self.owner = owner
        self.preview = preview
        self.post = post
        self.resources = resources
        self.title = title
    }

    init(
        playlist: Playlist,
        notes: [Note],
        baseURL: String,
        platform: Platform<PlaylistMetadata> = .playlist
    ) {
        self.init(
            id: playlist.id!,
            access: playlist.access,
            artwork: playlist.artwork.map { ImageResponse(image: $0, baseURL: baseURL) },
            description: playlist.description,
            notes: notes.map { NoteResponse(note: $0, baseURL: baseURL) },
            owner: UserResponse(user: playlist.owner),
            preview: PreviewResponse(preview: playlist.preview, baseURL: baseURL),
            post: playlist.post.map { PostResponse(post: $0, baseURL: baseURL) },
            resources: playlist.resourceURLs.compactMap(platform.hyperlink),
            title: playlist.title
        )
    }
}
