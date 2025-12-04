import Vapor
import Fluent
import AuthKit

struct NotesController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let notes = routes.grouped("notes")
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
    private func edit(request: Request) async throws -> Note {
        guard let noteID = request.parameters.get("noteID", as: NoteID.self) else {
            throw Abort(.badRequest, reason: "Missing note ID")
        }
        let payload = try request.content.decode(NotePayload.self)
        return try await request.commands.notes.edit(noteID, with: payload)
    }
}
