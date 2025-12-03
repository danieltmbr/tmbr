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

    @Parent(key: "owner_id")
    var owner: User
    
    @Field(key: "album")
    var album: String?
    
    @Field(key: "artist")
    var artist: String
    
    @OptionalParent(key: "artwork_id")
    var artwork: Image?
    
    @Field(key: "genre")
    var genre: String?
    
    @Field(key: "release_date")
    var releaseDate: Date?

    @Field(key: "title")
    var title: String

    @OptionalParent(key: "post_id")
    var post: Post?
    
    @Parent(key: "preview_id")
    var preview: Preview
    
    @Field(key: "resource_urls")
    var resourceURLs: [String]

    @Children(for: \.$song)
    private var songNotes: [SongNote]
    
    var notes: [Note] {
        songNotes.map { $0.$note.wrappedValue }
    }
    
    var ownerID: UserID { $owner.id }
}
