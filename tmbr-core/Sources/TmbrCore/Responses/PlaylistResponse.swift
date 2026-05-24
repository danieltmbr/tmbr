import Foundation

public struct PlaylistResponse: Codable, Sendable {

    public let id: PlaylistID

    public let access: Access

    public let artwork: ImageResponse?

    public let description: String?

    public let notes: [NoteResponse]

    public let owner: UserResponse

    public let preview: PreviewResponse

    public let post: PostResponse?

    public let resources: [Hyperlink]

    public let title: String

    public init(
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
}
