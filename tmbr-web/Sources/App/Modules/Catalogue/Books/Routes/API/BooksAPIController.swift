import Vapor
import WebAuth
import Fluent
import WebCore
import TmbrCore

private struct BookLookupResponse: Content, Sendable {
    let id: Int
    let title: String
    let author: String
    let detailURL: String
}

struct BooksAPIController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {

        let booksRoute = routes.grouped("api", "books")

        // GET /api/books — paginated list of the authenticated user's books
        booksRoute.get { request async throws -> PageResult<BookResponse> in
            let pageQuery = try request.query.decode(PageQuery.self)
            let input = PageInput(since: pageQuery.since, before: pageQuery.cursorDate, limit: pageQuery.limit)
            let books = try await request.commands.books.list(input)
            let previewIDs = books.map { $0.$preview.id }
            let notesByPreviewID = try await request.commands.notes.grouped(previewIDs)
            let baseURL = request.baseURL
            return try PageResult(from: books, limit: input.limit) { book in
                try BookResponse(book: book, baseURL: baseURL, notes: notesByPreviewID[book.$preview.id] ?? [])
            }
        }

        // GET /api/books/lookup?url=
        booksRoute.get("lookup") { request async throws -> BookLookupResponse in
            let url = try request.query.get(String.self, at: "url")
            guard let book = try await request.commands.books.lookup(url),
                  let bookID = book.id
            else {
                throw Abort(.notFound)
            }
            return BookLookupResponse(id: bookID, title: book.title, author: book.author, detailURL: "/books/\(bookID)")
        }

        // GET /api/books/:bookID
        booksRoute.get(":bookID") { request async throws -> BookResponse in
            guard let bookID = request.parameters.get("bookID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Book ID")
            }
            async let book = request.commands.books.fetch(bookID, for: .read)
            async let notes = request.commands.notes.query(id: bookID, of: Book.previewType)
            return try BookResponse(
                book: try await book,
                baseURL: request.baseURL,
                notes: try await notes
            )
        }

        // POST /api/books
        booksRoute.post(use: { request async throws -> BookResponse in
            let payload = try request.content.decode(BookPayload.self)
            return try await request.commands.transaction { commands in
                let bookInput = BookInput(payload: payload)
                let book = try await commands.books.create(bookInput)
                try await book.$preview.load(on: request.commandDB)
                try await book.preview.$image.load(on: request.commandDB)
                try await book.preview.$catalogueCategory.load(on: request.commandDB)
                let notesInput = payload.notes.map { entries in
                    BatchCreateNoteInput(
                        attachment: book.preview,
                        notes: entries.map(NoteInput.init)
                    )
                }
                let notes = try await notesInput.map(commands.notes.batchCreate)
                return try BookResponse(
                    book: book,
                    baseURL: request.baseURL,
                    notes: notes ?? []
                )
            }
        })

        // PUT /api/books/:bookID
        booksRoute.put(":bookID") { request async throws -> BookResponse in
            guard let bookID = request.parameters.get("bookID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Book ID")
            }
            let payload = try request.content.decode(BookPayload.self)
            let input = BookInput(payload: payload)
            return try await request.commands.transaction { commands in
                let book = try await commands.books.edit(input.edit(id: bookID))
                if let entries = payload.notes {
                    let preview = try await commands.previews.fetch(book.$preview.id, for: .write)
                    let syncEntries = entries.map { entry in
                        SyncNoteEntry(id: entry.noteID, body: entry.body, access: entry.access, deleted: entry.deleted ?? false)
                    }
                    _ = try await commands.notes.sync(
                        SyncNotesInput(attachment: preview, parentAccess: payload.access, entries: syncEntries)
                    )
                }
                try await book.$preview.load(on: request.commandDB)
                try await book.preview.$image.load(on: request.commandDB)
                try await book.preview.$catalogueCategory.load(on: request.commandDB)
                let notes = try await commands.notes.query(id: bookID, of: Book.previewType)
                return try BookResponse(book: book, baseURL: request.baseURL, notes: notes)
            }
        }

        // DELETE /api/books/:bookID
        booksRoute.delete(":bookID") { req async throws -> HTTPStatus in
            guard let bookID = req.parameters.get("bookID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Book ID")
            }
            try await req.commands.books.delete(bookID)
            return .noContent
        }

        // POST /api/books/:bookID/notes
        booksRoute.post(":bookID", "notes") { request async throws -> NoteResponse in
            guard let bookID = request.parameters.get("bookID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Invalid Book ID")
            }
            let payload = try request.content.decode(NotePayload.self)
            let book = try await request.commands.books.fetch(bookID, for: .write)
            let input = CreateNoteInput(
                body: payload.body,
                access: payload.access,
                attachmentID: book.$preview.id
            )
            let note = try await request.commands.notes.create(input)
            try await note.$attachment.load(on: request.commandDB)
            try await note.$author.load(on: request.commandDB)
            return NoteResponse(note: note, baseURL: request.baseURL)
        }
    }
}
