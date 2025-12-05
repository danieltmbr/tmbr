import Foundation
import Vapor
import AuthKit

struct BookInput {
    
    fileprivate let access: Access
    
    fileprivate let author: String
    
    fileprivate let cover: ImageID?
    
    fileprivate let genre: String?
        
    fileprivate let releaseDate: Date?
    
    fileprivate let resourceURLs: [String]
    
    fileprivate let title: String

    func validate() throws {
        guard !author.trimmed.isEmpty && !title.trimmed.isEmpty else {
            throw Abort(.badRequest, reason: "The book author or title is missing")
        }
    }
    
    init(
        access: Access,
        author: String,
        cover: ImageID?,
        genre: String?,
        releaseDate: Date?,
        resourceURLs: [String],
        title: String
    ) {
        self.access = access
        self.author = author
        self.cover = cover
        self.genre = genre
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.title = title
    }
    
    init(payload: BookPayload) {
        self.init(
            access: payload.access,
            author: payload.author,
            cover: payload.cover,
            genre: payload.genre,
            releaseDate: payload.releaseDate,
            resourceURLs: payload.resourceURLs,
            title: payload.title
        )
    }
}

struct BookConfiguration {
    
    static let `default` = BookConfiguration { book, input in
        book.access = input.access
        book.author = input.author
        book.$cover.id = input.cover
        book.genre = input.genre
        book.releaseDate = input.releaseDate
        book.resourceURLs = input.resourceURLs
        book.title = input.title
    }
    
    private let configure: @Sendable (Book, BookInput) -> Void
    
    init(configure: @Sendable @escaping (Book, BookInput) -> Void) {
        self.configure = configure
    }
    
    func callAsFunction(_ book: Book, with input: BookInput) {
        configure(book, input)
    }
}
