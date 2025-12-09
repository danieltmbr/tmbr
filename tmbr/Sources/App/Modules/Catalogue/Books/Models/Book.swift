import Fluent
import Vapor
import Foundation
import AuthKit

typealias BookID = Book.IDValue

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
    var bookNotes: [BookNote]
    
    @OptionalParent(key: "cover_id")
    var cover: Image?

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
        
    var notes: [Note] {
        bookNotes.map { $0.$note.wrappedValue }
    }
    
    var ownerID: UserID { $owner.id }
    
    init() {}
    
    init(owner: UserID) {
        self.$owner.id = owner
    }
    
    init(
        access: Access,
        author: String,
        cover: ImageID?,
        genre: String?,
        owner: UserID,
        releaseDate: Date?,
        resourceURLs: [String],
        title: String
    ) {
        self.access = access
        self.author = author
        self.$cover.id = cover
        self.genre = genre
        self.$owner.id = owner
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.title = title
    }
}

extension PreviewModelMiddleware where M == Book {
    
    static var book: Self {
        Self(
            attach: { previewID, book in
                book.$preview.id = previewID
            },
            configure: { preview, book in
                preview.primaryInfo = book.title
                preview.secondaryInfo = book.author
                preview.$image.id = book.cover?.id
                preview.externalLinks = book.resourceURLs
            },
            fetch: { book, database in
                try await book.$preview.load(on: database)
                return book.preview
            }
        )
    }
}
