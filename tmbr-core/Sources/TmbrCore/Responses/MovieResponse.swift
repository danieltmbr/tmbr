import Foundation

public struct MovieResponse: Codable, Sendable {

    public let id: MovieID

    public let access: Access

    public let cover: ImageResponse?

    public let director: String?

    public let genre: String?

    public let notes: [NoteResponse]

    public let owner: UserResponse

    public let preview: PreviewResponse

    public let post: PostResponse?

    public let releaseDate: Date?

    public let resources: [Hyperlink]

    public let title: String

    public init(
        id: MovieID,
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
}
