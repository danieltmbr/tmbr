import Fluent
import Vapor
import Foundation
import AuthKit

typealias AlbumID = Album.IDValue

final class Album: Model, Previewable, @unchecked Sendable {

    static let previewType = "album"

    static let schema = "albums"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Enum(key: "access")
    var access: Access

    @Field(key: "artist")
    var artist: String

    @OptionalParent(key: "artwork_id")
    var artwork: Image?

    @Field(key: "genre")
    var genre: String?

    @Parent(key: "owner_id")
    private(set) var owner: User

    @OptionalParent(key: "post_id")
    var post: Post?

    @Parent(key: "preview_id")
    fileprivate(set) var preview: Preview

    @Field(key: "release_date")
    var releaseDate: Date?

    @Field(key: "resource_urls")
    var resourceURLs: [String]

    @Field(key: "title")
    var title: String

    var ownerID: UserID { $owner.id }

    init() {}

    init(owner: UserID) {
        self.$owner.id = owner
    }

    init(
        access: Access,
        artist: String,
        artwork: ImageID?,
        genre: String?,
        owner: UserID,
        releaseDate: Date?,
        resourceURLs: [String],
        title: String
    ) {
        self.access = access
        self.artist = artist
        self.$artwork.id = artwork
        self.genre = genre
        self.$owner.id = owner
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.title = title
    }
}

extension PreviewModelMiddleware where M == Album {

    static var album: Self {
        Self(
            attach: { previewID, album in
                album.$preview.id = previewID
            },
            configure: { preview, album in
                preview.primaryInfo = album.title
                preview.secondaryInfo = "by \(album.artist)"
                preview.$image.id = album.artwork?.id
                preview.externalLinks = album.resourceURLs
            },
            fetch: { album, database in
                try await album.$preview.load(on: database)
                return album.preview
            }
        )
    }
}
