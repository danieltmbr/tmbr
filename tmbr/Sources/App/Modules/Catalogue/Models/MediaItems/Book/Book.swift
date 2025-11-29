import Fluent
import Vapor
import Foundation
import AuthKit

final class Book: Model, Previewable, @unchecked Sendable {
    
    static let previewType = "book"
    
    static let schema = "books"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Enum(key: "access")
    var access: Access
    
    @Field(key: "artist")
    var author: String
    
    @Children(for: \.$book)
    private var bookNotes: [BookNote]
    
    @OptionalParent(key: "cover_id")
    var cover: Image?

    @Field(key: "genre")
    var genre: String
    
    @Parent(key: "owner_id")
    private(set) var owner: User
    
    @OptionalParent(key: "post_id")
    var post: Post?
    
    @Parent(key: "preview_id")
    var preview: Preview
    
    @Field(key: "release_date")
    var releaseDate: Date
    
    @Field(key: "resource_urls")
    var resourceURLs: [String]

    @Field(key: "title")
    var title: String
        
    var notes: [Note] {
        bookNotes.map { $0.$note.wrappedValue }
    }
    
    var ownerID: UserID { $owner.id }
}
