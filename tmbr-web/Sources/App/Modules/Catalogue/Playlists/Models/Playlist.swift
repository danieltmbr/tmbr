import Fluent
import Vapor
import Foundation
import WebAuth
import TmbrCore

typealias PlaylistID = Playlist.IDValue

final class Playlist: Model, Previewable, @unchecked Sendable {

    static let previewType = "playlist"

    static let schema = "playlists"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Enum(key: "access")
    var access: Access

    @OptionalParent(key: "artwork_id")
    var artwork: Image?

    @OptionalField(key: "created_at")
    var platformCreatedAt: Date?

    @Field(key: "description")
    var description: String?

    @Parent(key: "owner_id")
    private(set) var owner: User

    @OptionalParent(key: "post_id")
    var post: Post?

    @Parent(key: "preview_id")
    fileprivate(set) var preview: Preview

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
        artwork: ImageID?,
        description: String?,
        owner: UserID,
        resourceURLs: [String],
        title: String
    ) {
        self.access = access
        self.$artwork.id = artwork
        self.description = description
        self.$owner.id = owner
        self.resourceURLs = resourceURLs
        self.title = title
    }
}

extension PreviewModelMiddleware where M == Playlist {

    static var playlist: Self {
        Self(
            attach: { previewID, playlist in
                playlist.$preview.id = previewID
            },
            configure: { preview, playlist in
                preview.primaryInfo = playlist.title
                preview.secondaryInfo = playlist.description
                preview.$image.id = playlist.artwork?.id
                preview.externalLinks = playlist.resourceURLs
            },
            fetch: { playlist, database in
                try await playlist.$preview.load(on: database)
                return playlist.preview
            }
        )
    }
}
