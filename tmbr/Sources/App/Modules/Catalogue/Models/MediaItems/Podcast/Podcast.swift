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
    var owner: User
    
    @Children(for: \.$podcast)
    private var podcastNotes: [PodcastNote]
    
    @OptionalParent(key: "post_id")
    var post: Post?
    
    @Parent(key: "preview_id")
    var preview: Preview
    
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
}
