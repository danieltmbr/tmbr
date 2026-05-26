import Vapor
import Fluent
import AuthKit
import TmbrCore

struct NotesAPIController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let notes = routes.grouped("api", "notes")
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
