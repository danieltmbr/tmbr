import Vapor
import Foundation
import AuthKit
import Core

struct BookViewModel: Encodable, Sendable {
    
    private let id: BookID
    
    private let author: String?
    
    private let cover: ImageViewModel?
    
    private let genre: String?
    
    private let notes: [NoteViewModel]
    
    private let post: PostItemViewModel?
    
    private let releaseDate: String?
    
    private let resources: [Hyperlink]
    
    private let title: String
    
    init(
        id: BookID,
        author: String?,
        cover: ImageViewModel?,
        genre: String?,
        notes: [NoteViewModel],
        post: PostItemViewModel?,
        releaseDate: String?,
        resources: [Hyperlink],
        title: String
    ) {
        self.id = id
        self.author = author
        self.cover = cover
        self.genre = genre
        self.notes = notes
        self.post = post
        self.releaseDate = releaseDate
        self.resources = resources
        self.title = title
    }
    
    init(
        book: Book,
        notes: [Note],
        baseURL: String,
        platform: Platform<Void> = .book
    ) throws {
        self.init(
            id: try book.requireID(),
            author: book.author,
            cover: book.cover.flatMap {
                ImageViewModel(image: $0, baseURL: baseURL)
            },
            genre: book.genre,
            notes: try notes.map(NoteViewModel.init),
            post: try book.post.map(PostItemViewModel.init),
            releaseDate: book.releaseDate?.formatted(.releaseDate),
            resources: book.resourceURLs.compactMap(platform.hyperlink),
            title: book.title
        )
    }
}

extension Template where Model == BookViewModel {
    static let book = Template(name: "Catalogue/Books/book")
}

extension Page {
    static var book: Self {
        Page(template: .book) { request in
            guard let bookID = request.parameters.get("bookID", as: Int.self) else {
                throw Abort(.badRequest)
            }
            return try await request.commands.transaction { commands in
                async let book = commands.books.fetch(bookID, for: .read)
                async let notes = commands.notes.query(id: bookID, of: Book.previewType)
                
                return try BookViewModel(
                    book: await book,
                    notes: await notes,
                    baseURL: request.baseURL
                )
            }
        }
    }
}
