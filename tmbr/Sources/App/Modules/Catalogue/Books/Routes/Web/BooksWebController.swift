import Vapor
import Fluent
import AuthKit
import Core

struct BooksWebController: RouteCollection {

    private enum EditorMode {
        case create
        case update(bookID: Int)
    }

    func boot(routes: RoutesBuilder) throws {
        let booksRoute = routes.grouped("books")
        let recoveringRoute = routes.grouped("books")
            .grouped(RecoverMiddleware())

        recoveringRoute.get(page: .books)

        recoveringRoute.get(":bookID", page: .book)

        recoveringRoute.get("new", page: .createBook)
        recoveringRoute.post("new", use: createBook)

        booksRoute.get("metadata", use: metadata)
        booksRoute.get("lookup", use: lookupDialog)

        recoveringRoute.get(":bookID", "edit", page: .editBook)
        recoveringRoute.post(":bookID", use: updateBook)

        recoveringRoute.post("preview", page: .bookPreview)

        booksRoute.post(":bookID", "notes", use: createNote)
    }

    @Sendable
    private func metadata(_ request: Request) async throws -> BookMetadata {
        let url = try request.query.get(String.self, at: "url")
        return try await request.commands.books.metadata(url)
    }

    @Sendable
    private func lookupDialog(_ request: Request) async throws -> Response {
        let url = try request.query.get(String.self, at: "url")
        let excludeID = try? request.query.get(Int.self, at: "excludeID")
        guard let book = try await request.commands.books.lookup(url),
              let bookID = book.id,
              bookID != excludeID
        else {
            return Response(status: .notFound)
        }
        let model = AlertDialog(
            id: "duplicate-alert",
            message: "You already have \(book.title) by \(book.author).",
            primaryAction: .init(id: "duplicate-dismiss", label: "Continue editing"),
            secondaryAction: .init(id: "duplicate-book-link", label: "Go to book", href: "/books/\(bookID)")
        )
        let view = try await Template.alertDialog.render(model, with: request.view)
        return try await view.encodeResponse(for: request)
    }

    @Sendable
    private func createBook(_ req: Request) async throws -> Response {
        try await handleEditorSubmission(req, mode: .create)
    }

    @Sendable
    private func updateBook(_ req: Request) async throws -> Response {
        guard let bookID = req.parameters.get("bookID", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid Book ID")
        }
        return try await handleEditorSubmission(req, mode: .update(bookID: bookID))
    }

    private func handleEditorSubmission(_ req: Request, mode: EditorMode) async throws -> Response {
        do {
            let payload = try req.content.decode(BookEditorPayload.self)
            guard let submittedCSRF = payload._csrf,
                  submittedCSRF == req.session.data["csrf.editor"] else {
                throw Abort(.forbidden, reason: "Invalid form token. Please reload the editor and try again.")
            }

            let coverId = try await resolveArtwork(payload: payload, on: req)

            let book = try await req.commands.transaction { commands in
                let bookInput = BookInput(payload: payload, coverId: coverId)
                let book: Book

                switch mode {
                case .create:
                    book = try await commands.books.create(bookInput)
                    let preview = try await commands.previews.fetch(book.$preview.id, for: .write)
                    let noteInputs = payload.notes.map { entry in
                        NoteInput(body: entry.body, access: entry.access && payload.access)
                    }
                    _ = try await commands.notes.batchCreate(noteInputs, for: preview)
                case .update(let bookID):
                    book = try await commands.books.edit(bookInput.edit(id: bookID))
                    let preview = try await commands.previews.fetch(book.$preview.id, for: .write)
                    let syncEntries = payload.notes.map { entry in
                        SyncNoteEntry(
                            id: entry.noteID,
                            body: entry.body,
                            access: entry.access,
                            deleted: entry.deleted ?? false
                        )
                    }
                    _ = try await commands.notes.sync(
                        SyncNotesInput(attachment: preview, parentAccess: payload.access, entries: syncEntries)
                    )
                }

                return book
            }

            req.session.data["csrf.editor"] = nil
            return req.redirect(to: "/books/\(book.id!)")
        } catch {
            return try await renderEditorWithError(req, mode: mode, error: error)
        }
    }

    private func resolveArtwork(payload: BookEditorPayload, on req: Request) async throws -> ImageID? {
        if let coverId = payload.coverId {
            return coverId
        }
        guard let artworkURL = payload.coverSourceURL else {
            return nil
        }
        if let existingImage = try await req.commands.gallery.lookup(artworkURL) {
            return try existingImage.requireID()
        }
        let alt = payload.title.isEmpty ? "Book cover" : payload.title
        let newImage = try await req.commands.gallery.addFromURL(
            ImageURLPayload(url: artworkURL, alt: alt)
        )
        return try newImage.requireID()
    }

    private func renderEditorWithError(
        _ req: Request,
        mode: EditorMode,
        error: Error
    ) async throws -> Response {
        let submitted = (try? req.content.decode(BookEditorPayload.self)) ?? BookEditorPayload()
        let submit: Form.Submit
        let bookID: Int?
        let pageTitle: String

        switch mode {
        case .create:
            bookID = nil
            submit = Form.Submit(action: "/books/new", label: "Save")
            pageTitle = "New book"
        case .update(let id):
            bookID = id
            submit = Form.Submit(action: "/books/\(id)", label: "Save")
            pageTitle = "Edit '\(submitted.title)'"
        }

        let noteViewModels = submitted.notes.map {
            BookEditorViewModel.NoteViewModel(id: $0.id, body: $0.body, access: $0.access)
        }

        let csrf = UUID().uuidString
        let model = BookEditorViewModel(
            id: bookID,
            pageTitle: pageTitle,
            access: submitted.access,
            author: submitted.author,
            coverId: submitted.coverId,
            coverSourceURL: submitted.coverSourceURL,
            coverThumbnailURL: submitted.coverSourceURL,
            genre: submitted.genre ?? "",
            notes: noteViewModels,
            releaseDate: submitted.releaseDate?.formatted(.iso8601.year().month().day()) ?? "",
            resourceURLs: submitted.resourceURLs,
            submit: submit,
            title: submitted.title,
            csrf: csrf,
            error: editorErrorHTML(for: error, on: req)
        )

        let view = try await Template.bookEditor.render(model, with: req.view)
        let response = try await view.encodeResponse(for: req)
        req.session.data["csrf.editor"] = csrf
        return response
    }

    @Sendable
    private func createNote(_ request: Request) async throws -> Response {
        guard let bookID = request.parameters.get("bookID", as: Int.self) else {
            return Response(status: .badRequest)
        }
        guard let payload = try? request.content.decode(NotePayload.self) else {
            return Response(status: .badRequest)
        }
        do {
            let book = try await request.commands.books.fetch(bookID, for: .write)
            let input = CreateNoteInput(
                body: payload.body,
                access: payload.access,
                attachmentID: book.$preview.id
            )
            let note = try await request.commands.notes.create(input)
            let model = try NoteViewModel(note: note, isEditable: true)
            let view = try await Template.noteItem.render(NoteItemContext(note: model), with: request.view)
            return try await view.encodeResponse(for: request)
        } catch {
            return Response(status: .unprocessableEntity)
        }
    }

    private func editorErrorHTML(for error: Error, on req: Request) -> String {
        if let abort = error as? AbortError {
            switch abort.status {
            case .unauthorized:
                return "Please <a href=\"/signin?return=\(req.url.path)\">sign in</a> and try again."
            case .forbidden:
                return "You don't have permission to perform this action."
            case .notFound:
                return "This book doesn't exist or isn't available."
            case .badRequest:
                return abort.reason.isEmpty ? "Please check your input and try again." : abort.reason
            default:
                break
            }
        }
        if error is ValidationsError {
            return "Title and author are required."
        }
        return "Something went wrong. Please try again."
    }
}
