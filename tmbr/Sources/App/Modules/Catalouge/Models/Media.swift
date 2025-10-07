import Fluent
import Vapor
import Foundation

final class MediaPreview: Fields, Codable, @unchecked Sendable {
    @Field(key: "title")
    var title: String
    
    @OptionalField(key: "subtitle")
    var subtitle: String?
    
    @OptionalField(key: "body")
    var body: String?
    
    @OptionalField(key: "image_url")
    var imageURL: String?
    
    init() {
        self.title = ""
        self.subtitle = nil
        self.body = nil
        self.imageURL = nil
    }
    
    init(
        title: String,
        subtitle: String? = nil,
        body: String? = nil,
        imageURL: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.imageURL = imageURL
    }
}

final class Media: Model, Content, @unchecked Sendable {
    static let schema = "media"
    
    enum Content: Codable, Sendable {
        case music(Music)
        case movie(Movie)
        case book(Book)
        case podcast(Podcast)
    }
    
    enum Kind: String, Codable, Sendable {
        case music
        case movie
        case book
        case podcast
    }
    
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "kind")
    private var kind: Kind
    
    @Group(key: "preview")
    private(set) var preview: MediaPreview
    
    @Children(for: \.$media)
    var notes: [MediaNote]
    
    @OptionalChild(for: \.$media)
    private var music: Music?

    @OptionalChild(for: \.$media)
    private var movie: Movie?

    @OptionalChild(for: \.$media)
    private var book: Book?

    @OptionalChild(for: \.$media)
    private var podcast: Podcast?
    
    var content: Content? {
        switch kind {
        case .music:
            guard let music else { return nil }
            return .music(music)
        case .movie:
            guard let movie else { return nil }
            return .movie(movie)
        case .book:
            guard let book else { return nil }
            return .book(book)
        case .podcast:
            guard let podcast else { return nil }
            return .podcast(podcast)
        }
    }
    
    init() {}
    
    init(kind: Kind, preview: MediaPreview) {
        self.kind = kind
        self.preview = preview
    }
}
