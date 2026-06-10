import Vapor
import Fluent
import Core
import AuthKit
import TmbrCore

struct NotesAPIController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let notes = routes.grouped("api", "notes")
        let protected = notes.grouped(AppleSignInAuthenticator())

        // GET /api/notes — returns the authenticated user's notes, paginated
        protected.get { request async throws -> PageResult<NoteResponse> in
            let user = try request.auth.require(User.self)
            let userID = try user.requireID()
            let pageQuery = try request.query.decode(PageQuery.self)
            let limit = pageQuery.limit ?? 50
            let input = ListNotesInput(
                authorID: userID,
                since: pageQuery.since,
                before: pageQuery.cursorDate,
                limit: limit + 1
            )
            let notes = try await request.commands.notes.list(input)
            let baseURL = request.baseURL
            return makePage(from: notes, limit: limit, cursorDate: { $0.createdAt }) {
                $0.map { NoteResponse(note: $0, baseURL: baseURL) }
            }
        }

        notes.put(":noteID", use: edit)
        notes.delete(":noteID", use: delete)
    }

    @Sendable
    private func delete(request: Request) async throws -> HTTPStatus {
        guard let noteID = request.parameters.get("noteID", as: NoteID.self) else {
            throw Abort(.badRequest, reason: "Missing note ID")
        }
        try await request.commands.notes.delete(noteID)
        return .noContent
    }

    @Sendable
    private func edit(request: Request) async throws -> NoteResponse {
        guard let noteID = request.parameters.get("noteID", as: NoteID.self) else {
            throw Abort(.badRequest, reason: "Missing note ID")
        }
        let payload = try request.content.decode(NotePayload.self)
        let note = try await request.commands.notes.edit(noteID, with: payload)
        // attachment is loaded by EditNoteCommand; load author for the full response
        try await note.$author.load(on: request.commandDB)
        return NoteResponse(note: note, baseURL: request.baseURL)
    }
}
