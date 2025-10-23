import Fluent
import Vapor
import Foundation

final class Media: Content, Model, @unchecked Sendable {
    static let schema = "media"
    
    enum Collaboration: String, Codable, Sendable {
        case none
        case authors
        case users
    }
    
    enum Content: Sendable {
        case music(Music)
        case movie(Movie)
        case book(Book)
        case podcast(Podcast)
        
        var id: Int {
            get throws {
                switch self {
                case .book(let book): try book.requireID()
                case .music(let music): try music.requireID()
                case .movie(let movie): try movie.requireID()
                case .podcast(let podcast): try podcast.requireID()
                }
            }
        }
    }
    
    enum Kind: String, Codable, Sendable {
        case music
        case movie
        case book
        case podcast
    }
    
    struct LoadOption: OptionSet {
        let rawValue: UInt
        
        static let notes = LoadOption(rawValue: 1 << 0)
        
        static let content = LoadOption(rawValue: 1 << 1)
    }
    
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Parent(key: "owner_id")
    private(set) var owner: User

    @Field(key: "kind")
    private var kind: Kind
    
    @Group(key: "preview")
    private(set) var preview: Preview

    @Field(key: "collaboration")
    var collaboration: Collaboration
    
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
    
    @OptionalChild(for: \.$media)
    private(set) var post: Post?
    
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
    
    init(
        kind: Kind,
        ownerID: Int,
        preview: Preview,
        collaboration: Collaboration = .none
    ) {
        self.kind = kind
        self.preview = preview
        self.$owner.id = ownerID
        self.collaboration = collaboration
    }
    
    func load(_ options: LoadOption, on database: any Database) async throws {
        if options.contains(.notes) {
            try await $notes.load(on: database)
        }
        if options.contains(.content) {
            try await loadContent(on: database)
        }
    }
    
    private func loadContent(on database: any Database) async throws {
        switch kind {
        case .music:
            try await $music.load(on: database, eager: true)
        case .movie:
            try await $movie.load(on: database, eager: true)
        case .book:
            try await $book.load(on: database, eager: true)
        case .podcast:
            try await $podcast.load(on: database, eager: true)
        }
    }
}

