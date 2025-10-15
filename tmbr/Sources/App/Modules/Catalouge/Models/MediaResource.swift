import Fluent
import Vapor
import Foundation

final class MediaResource<ContentType: MediaItem>: Model, @unchecked Sendable {
    static var schema: String { "media_resources" }
    
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @OptionalParent(key: "book_id")
    private(set) var book: Book?
    
    @OptionalParent(key: "music_id")
    private(set) var music: Music?
    
    @OptionalParent(key: "movie_id")
    private(set) var movie: Movie?
    
    @OptionalParent(key: "podcast_id")
    private(set) var podcast: Podcast?
    
    @Field(key: "platform")
    var platform: MediaPlatform<ContentType>
    
    @Field(key: "external_id")
    var externalID: String
    
    @Field(key: "url")
    var urlString: String
    
    var url: URL {
        get { URL(string: urlString)! }
        set { urlString = newValue.absoluteString }
    }
    
    init() {}
    
    @Sendable
    init(
        platform: MediaPlatform<ContentType>,
        externalID: String,
        url: URL
    ) {
        self.platform = platform
        self.externalID = externalID
        self.urlString = url.absoluteString
    }
}
