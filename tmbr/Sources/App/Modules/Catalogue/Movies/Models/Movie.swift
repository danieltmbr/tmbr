import Fluent
import Vapor
import Foundation
import AuthKit

typealias MovieID = Movie.IDValue

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
        cover: ImageID?,
        director: String?,
        genre: String?,
        owner: UserID,
        releaseDate: Date?,
        resourceURLs: [String],
        title: String
    ) {
        self.id = id
        self.access = access
        self.$cover.id = cover
        self.director = director
        self.genre = genre
        self.$owner.id = owner
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.title = title
    }
}

extension PreviewModelMiddleware where M == Movie {
    
    static var movie: Self {
        Self(
            attach: { previewID, movie in
                movie.$preview.id = previewID
            },
            configure: { preview, movie in
                preview.primaryInfo = movie.title
                preview.secondaryInfo = movie.releaseDate?.formatted()
                preview.$image.id = movie.cover?.id
                preview.externalLinks = movie.resourceURLs
            },
            fetch: { movie, database in
                try await movie.$preview.load(on: database)
                return movie.preview
            }
        )
    }
}
