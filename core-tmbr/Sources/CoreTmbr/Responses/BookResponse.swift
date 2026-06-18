import Foundation

public struct BookResponse: Codable, Sendable {

    public let id: BookID

    public let access: Access

    public let author: String

    public let cover: ImageResponse?

    public let genre: String?

    public let notes: [NoteResponse]

    public let owner: UserResponse

    public let preview: PreviewResponse

    public let post: PostResponse?

    public let releaseDate: Date?

    public let resources: [Hyperlink]

    public let title: String

    public init(
        id: BookID,
        access: Access,
        author: String,
        cover: ImageResponse?,
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
}
