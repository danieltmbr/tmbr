import Foundation

public struct SongResponse: Codable, Sendable {

    public let id: SongID

    public let access: Access

    public let album: String?

    public let artist: String

    public let artwork: ImageResponse?

    public let genre: String?

    public let notes: [NoteResponse]

    public let owner: UserResponse

    public let preview: PreviewResponse

    public let post: PostResponse?

    public let releaseDate: Date?

    public let resources: [Hyperlink]

    public let title: String

    public init(
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
        resources: [Hyperlink],
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
}
