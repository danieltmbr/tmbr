import CoreWeb
import Foundation
import Vapor
import Fluent
import CoreAuth
import CoreTmbr

struct BookEditorViewModel: Encodable, Sendable {


    private let id: Int?

    private let pageTitle: String?

    private let access: Access

    private let author: String

    private let coverId: Int?

    private let coverSourceURL: String?

    private let coverThumbnailURL: String?

    private let genre: String

    private let notes: [NoteEditorViewModel]

    private let releaseDate: String

    private let resourceURLs: [String]

    private let submit: Form.Submit

    private let title: String

    let _csrf: String?

    private let error: String?

    init(
        id: Int? = nil,
        pageTitle: String? = nil,
        access: Access = .private,
        author: String = "",
        coverId: Int? = nil,
        coverSourceURL: String? = nil,
        coverThumbnailURL: String? = nil,
        genre: String = "",
        notes: [NoteEditorViewModel] = [],
        releaseDate: String = "",
        resourceURLs: [String] = [],
        submit: Form.Submit,
        title: String = "",
        csrf: String? = nil,
        error: String? = nil
    ) {
        self.id = id
        self.pageTitle = pageTitle
        self.access = access
        self.author = author
        self.coverId = coverId
        self.coverSourceURL = coverSourceURL
        self.coverThumbnailURL = coverThumbnailURL
        self.genre = genre
        self.notes = notes
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.submit = submit
        self.title = title
        self._csrf = csrf
        self.error = error
    }

    init(
        book: Book,
        notes: [Note],
        baseURL: String,
        csrf: String?
    ) throws {
        let id = try book.requireID()
        let coverId = book.$cover.id
        let coverThumbnailURL: String?
        if let cover = book.cover {
            coverThumbnailURL = "\(baseURL)/gallery/data/\(cover.thumbnailKey)"
        } else {
            coverThumbnailURL = nil
        }
        self.init(
            id: id,
            pageTitle: "Edit '\(book.title)'",
            access: book.access,
            author: book.author,
            coverId: coverId,
            coverSourceURL: nil,
            coverThumbnailURL: coverThumbnailURL,
            genre: book.genre ?? "",
            notes: notes.map { NoteEditorViewModel(id: $0.id?.uuidString, body: $0.body, access: $0.access, language: $0.language) },
            releaseDate: book.releaseDate?.formatted(.releaseDate) ?? "",
            resourceURLs: book.resourceURLs,
            submit: Form.Submit(
                action: "/books/\(id)",
                label: "Save"
            ),
            title: book.title,
            csrf: csrf
        )
    }
}

extension Template where Model == BookEditorViewModel {
    static let bookEditor = Template(name: "Catalogue/Books/book-editor")
}

extension Page {
    static var createBook: Self {
        Page(template: .bookEditor) { req in
            try await req.permissions.books.create()
            let submit = Form.Submit(
                action: "/books/new",
                label: "Save"
            )
            let csrf = UUID().uuidString
            req.session.data["csrf.editor"] = csrf
            return BookEditorViewModel(pageTitle: "New book", submit: submit, csrf: csrf)
        }
    }

    static var editBook: Self {
        Page(template: .bookEditor) { request in
            guard let bookID = request.parameters.get("bookID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Book ID is incorrect or missing.")
            }
            async let book = request.commands.books.fetch(bookID, for: .write)
            async let notes = request.commands.notes.query(id: bookID, of: Book.previewType)
            let csrf = UUID().uuidString
            request.session.data["csrf.editor"] = csrf
            return try await BookEditorViewModel(
                book: book,
                notes: notes,
                baseURL: request.baseURL,
                csrf: csrf
            )
        }
    }
}

private struct BookPreviewPayload: Content {
    let title: String
    let author: String
    let genre: String?
    let releaseDate: String?
    let coverURL: String?
    let resourceURLs: String?
    let notes: String
}

extension Page {
    static var bookPreview: Self {
        Page(template: .book) { req in
            try await req.permissions.books.create.grant()
            let payload = try req.content.decode(BookPreviewPayload.self)
            let formatter = MarkdownFormatter.html
            let notes: [NoteViewModel] = payload.notes.isEmpty ? [] : [
                NoteViewModel(
                    id: UUID(),
                    body: formatter.format(payload.notes),
                    created: Date.now.formatted(.publishDate)
                )
            ]
            let platform = Platform<BookMetadata>.book
            let resources = (payload.resourceURLs ?? "")
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map(String.init)
                .compactMap(platform.hyperlink)
            return BookViewModel(
                id: 0,
                author: payload.author,
                allowsNewNote: false,
                cover: payload.coverURL.flatMap { url in
                    url.isEmpty ? nil : ImageViewModel(previewURL: url)
                },
                genre: payload.genre,
                notes: notes,
                notesEndpoint: "",
                post: nil,
                releaseDate: payload.releaseDate,
                resources: resources,
                title: "Preview: \(payload.title)"
            )
        }
    }
}
