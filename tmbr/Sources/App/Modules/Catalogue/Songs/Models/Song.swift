import Fluent
import Vapor
import Foundation
import AuthKit

typealias SongID = Song.IDValue

final class Song: Model, Previewable, @unchecked Sendable {
    
    static let previewType = "song"
    
    static let schema = "songs"
    
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Enum(key: "access")
    var access: Access
    
    @Field(key: "album")
    var album: String?
    
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
        album: String?,
        artist: String,
        artwork: ImageID?,
        genre: String?,
        owner: UserID,
        releaseDate: Date?,
        resourceURLs: [String],
        title: String
    ) {
        self.access = access
        
        self.album = album
        self.artist = artist
        self.$artwork.id = artwork
        self.genre = genre
        self.$owner.id = owner
        self.resourceURLs = resourceURLs
        self.releaseDate = releaseDate
        self.title = title
    }
}

extension PreviewModelMiddleware where M == Song {
    
    static var song: Self {
        Self(
            attach: { previewID, song in
                song.$preview.id = previewID
            },
            configure: { preview, song in
                preview.primaryInfo = song.title
                preview.secondaryInfo = song.artist
                preview.$image.id = song.artwork?.id
                preview.externalLinks = song.resourceURLs
            },
            fetch: { song, database in
                try await song.$preview.load(on: database)
                return song.preview
            }
        )
    }
}
