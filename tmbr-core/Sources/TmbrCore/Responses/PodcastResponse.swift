import Foundation

public struct PodcastResponse: Codable, Sendable {

    public let id: PodcastID

    public let access: Access

    public let artwork: ImageResponse?

    public let episodeNumber: Int?

    public let episodeTitle: String

    public let genre: String?

    public let notes: [NoteResponse]

    public let owner: UserResponse

    public let preview: PreviewResponse

    public let post: PostResponse?

    public let releaseDate: Date?

    public let resources: [Hyperlink]

    public let seasonNumber: Int?

    public let title: String

    public init(
        id: PodcastID,
        access: Access,
        artwork: ImageResponse?,
        episodeNumber: Int?,
        episodeTitle: String,
        genre: String?,
        notes: [NoteResponse],
        owner: UserResponse,
        preview: PreviewResponse,
        post: PostResponse?,
        releaseDate: Date?,
        resources: [Hyperlink],
        seasonNumber: Int?,
        title: String
    ) {
        self.id = id
        self.access = access
        self.artwork = artwork
        self.episodeNumber = episodeNumber
        self.episodeTitle = episodeTitle
        self.genre = genre
        self.notes = notes
        self.owner = owner
        self.preview = preview
        self.post = post
        self.releaseDate = releaseDate
        self.resources = resources
        self.seasonNumber = seasonNumber
        self.title = title
    }
}
