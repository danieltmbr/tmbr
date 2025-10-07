import Fluent
import Vapor
import Foundation

final class MediaResource: Model, Content, @unchecked Sendable {
    static let schema = "media_resources"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    // One of these optional parents must be set depending on the kind
    @OptionalParent(key: "book_id")
    var book: Book?

    @OptionalParent(key: "music_id")
    var music: Music?

    @OptionalParent(key: "movie_id")
    var movie: Movie?

    @OptionalParent(key: "podcast_id")
    var podcast: Podcast?

    @Field(key: "platform")
    var platform: MediaPlatform

    @Field(key: "external_id")
    var externalID: String

    @Field(key: "url")
    var urlString: String

    var url: URL {
        get { URL(string: urlString)! }
        set { urlString = newValue.absoluteString }
    }

    init() {}

    // Convenience initializers for each kind
    init(bookID: Int, platform: MediaPlatform, externalID: String, url: URL) {
        self.$book.id = bookID
        self.platform = platform
        self.externalID = externalID
        self.urlString = url.absoluteString
    }

    init(musicID: Int, platform: MediaPlatform, externalID: String, url: URL) {
        self.$music.id = musicID
        self.platform = platform
        self.externalID = externalID
        self.urlString = url.absoluteString
    }

    init(movieID: Int, platform: MediaPlatform, externalID: String, url: URL) {
        self.$movie.id = movieID
        self.platform = platform
        self.externalID = externalID
        self.urlString = url.absoluteString
    }

    init(podcastID: Int, platform: MediaPlatform, externalID: String, url: URL) {
        self.$podcast.id = podcastID
        self.platform = platform
        self.externalID = externalID
        self.urlString = url.absoluteString
    }
}
