import Fluent
import Vapor
import Foundation
import AuthKit

final class Movie: Model, Previewable, @unchecked Sendable {
    
    static let previewType = "movie"
    
    static let schema = "movies"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Enum(key: "access")
    var access: Access
    
    @OptionalParent(key: "cover_id")
    var cover: Image?
    
    @Field(key: "director")
    var director: String?
    
    @Field(key: "genre")
    var genre: String?
    
    @Children(for: \.$movie)
    private var movieNotes: [MovieNote]
    
    @Parent(key: "owner_id")
    var owner: User
    
    @OptionalParent(key: "post_id")
    var post: Post?
    
    @Parent(key: "preview_id")
    var preview: Preview
    
    @Field(key: "release_date")
    var releaseDate: Date?
    
    @Field(key: "resource_urls")
    var resourceURLs: [String]

    @Field(key: "title")
    var title: String
    
    var notes: [Note] {
        movieNotes.map { $0.$note.wrappedValue }
    }
    
    var ownerID: UserID { $owner.id }
}
