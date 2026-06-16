import Vapor
import Foundation
import CoreAuth
import CoreWeb
import CoreTmbr

struct BookViewModel: Encodable, Sendable {

    private let id: BookID

    private let author: String?

    private let allowsNewNote: Bool

    private let cover: ImageViewModel?

    private let info: String?

    private let notes: [NoteViewModel]

    private let notesEndpoint: String

    private let post: PostItemViewModel?

    private let resources: [Hyperlink]

    private let title: String

    init(
        id: BookID,
        author: String?,
        allowsNewNote: Bool,
        cover: ImageViewModel?,
        info: String?,
        notes: [NoteViewModel],
        notesEndpoint: String,
        post: PostItemViewModel?,
        resources: [Hyperlink],
        title: String
    ) {
        self.id = id
        self.author = author
        self.allowsNewNote = allowsNewNote
        self.cover = cover
        self.info = info
        self.notes = notes
        self.notesEndpoint = notesEndpoint
        self.post = post
        self.resources = resources
        self.title = title
    }

    init(
        id: BookID,
        author: String?,
        allowsNewNote: Bool,
        cover: ImageViewModel?,
        genre: String?,
        notes: [NoteViewModel],
        notesEndpoint: String,
        post: PostItemViewModel?,
        releaseDate: String?,
        resources: [Hyperlink],
        title: String
    ) {
        self.init(
            id: id,
            author: author,
            allowsNewNote: allowsNewNote,
            cover: cover,
            info: {
                let parts = [genre, releaseDate].compactMap(\.self).filter { !$0.isEmpty }
                return parts.isEmpty ? nil : parts.joined(separator: ", ")
            }(),
            notes: notes,
            notesEndpoint: notesEndpoint,
            post: post,
            resources: resources,
            title: title
        )
    }

    init(
        book: Book,
        notes: [Note],
        baseURL: String,
        allowsNewNote: Bool,
        platform: Platform<BookMetadata> = .book
    ) throws {
        let bookID = try book.requireID()
        self.init(
            id: bookID,
            author: book.author,
            allowsNewNote: allowsNewNote,
            cover: book.cover.flatMap {
                ImageViewModel(image: $0, baseURL: baseURL)
            },
            info: {
                let parts = [book.genre, book.releaseDate?.formatted(.releaseDate)].compactMap(\.self).filter { !$0.isEmpty }
                return parts.isEmpty ? nil : parts.joined(separator: ", ")
            }(),
            notes: try notes.map { try NoteViewModel(note: $0, isEditable: allowsNewNote) },
            notesEndpoint: "/books/\(bookID)/notes",
            post: try book.post.map(PostItemViewModel.init),
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
            async let bookTask = request.commands.books.fetch(bookID, for: .read)
            async let notesTask = request.commands.notes.query(id: bookID, of: Book.previewType, languages: request.languagePreference)
            let resolvedBook = try await bookTask
            let allowsNewNote = (try? await request.permissions.books.edit.grant(resolvedBook)) != nil
            return try BookViewModel(
                book: resolvedBook,
                notes: await notesTask,
                baseURL: request.baseURL,
                allowsNewNote: allowsNewNote
            )
        }
    }
}
