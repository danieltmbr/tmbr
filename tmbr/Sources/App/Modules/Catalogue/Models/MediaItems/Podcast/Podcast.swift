import Fluent
import Vapor
import Foundation
import AuthKit

typealias PodcastID = Podcast.IDValue

final class Podcast: Model, Previewable, @unchecked Sendable {
    
    static let previewType = "podcast"
    
    static let schema = "podcasts"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Enum(key: "access")
    var access: Access
    
    @OptionalParent(key: "artwork_id")
    var artwork: Image?
    
    @Field(key: "episode_number")
    var episodeNumber: Int?
    
    @Field(key: "episode_title")
    var episodeTitle: String
    
    @Field(key: "genre")
    var genre: String?
    
    @Parent(key: "owner_id")
    private(set) var owner: User
    
    @Children(for: \.$podcast)
    private(set) var podcastNotes: [PodcastNote]
    
    @OptionalParent(key: "post_id")
    var post: Post?
    
    @Parent(key: "preview_id")
    fileprivate(set) var preview: Preview
    
    @Field(key: "release_date")
    var releaseDate: Date?
    
    @Field(key: "resource_urls")
    var resourceURLs: [String]
    
    @Field(key: "season")
    var seasonNumber: Int?

    @Field(key: "title")
    var title: String
    
    var notes: [Note] {
        podcastNotes.map { $0.$note.wrappedValue }
    }
    
    var ownerID: UserID { $owner.id }
    
    init() {}
    
    init(owner: UserID) {
        self.$owner.id = owner
    }
    
    init(
        access: Access,
        artwork: ImageID?,
        episodeNumber: Int?,
        episodeTitle: String,
        genre: String?,
        owner: UserID,
        releaseDate: Date?,
        resourceURLs: [String],
        seasonNumber: Int?,
        title: String
    ) {
        self.access = access
        self.$artwork.id = artwork
        self.episodeNumber = episodeNumber
        self.episodeTitle = episodeTitle
        self.genre = genre
        self.$owner.id = owner
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.seasonNumber = seasonNumber
        self.title = title
    }
}

extension PreviewModelMiddleware where M == Podcast {
    
    static var podcast: Self {
        Self(
            attach: { previewID, podcast in
                podcast.$preview.id = previewID
            },
            configure: { preview, podcast in
                preview.primaryInfo = podcast.episodeTitle
                preview.secondaryInfo = podcast.title
                preview.$image.id = podcast.artwork?.id
                preview.externalLinks = podcast.resourceURLs
            },
            fetch: { podcast, database in
                try await podcast.$preview.load(on: database)
                return podcast.preview
            }
        )
    }
}
