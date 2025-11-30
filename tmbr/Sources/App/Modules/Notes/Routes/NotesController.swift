import Vapor
import Fluent
import AuthKit

struct NotePayload: Content {
    var body: String
    
    var visibility: Note.Visibility

    var attachmentID: UUID
}

struct NoteUpdatePayload: Content {
    
    var body: String
    
    var visibility: Note.Visibility
}

struct NotesController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let notes = routes.grouped("notes")
        notes.post(use: create)
        notes.put(":noteID", use: edit)
        notes.delete(":noteID", use: delete)
    }
    
    /// Create can be a Note endpoint as it is domain agnostic
    /// Edit and delete as well.
    ///
    /// I don't think we need a fetch... Note's should not be fetched on their own
    ///
    /// We need a search though
    
    @Sendable
    private func create(req: Request) async throws -> Note {
        let user = try req.auth.require(User.self)
        let payload = try req.content.decode(NotePayload.self)
        // TODO: Fetch Preview and check its owner and visibility setting
        let note = Note(
            attachmentID: payload.attachmentID,
            authorID: try user.requireID(),
            body: payload.body,
            visibility: payload.visibility
        )
        try await note.save(on: req.db)
        return note
    }
    
    @Sendable
    private func delete(request: Request) async throws -> HTTPStatus {
        guard let noteID = request.parameters.get("noteID", as: NoteID.self) else {
            throw Abort(.badRequest, reason: "Missing note ID")
        }
        guard let note = try await Note.find(noteID, on: request.db) else {
            throw Abort(.notFound)
        }
        try await request.permissions.notes.delete(note)
        try await note.delete(on: request.db)
        return .noContent
    }
    
    @Sendable
    private func edit(request: Request) async throws -> HTTPStatus {
        guard let noteID = request.parameters.get("noteID", as: NoteID.self) else {
            throw Abort(.badRequest, reason: "Missing note ID")
        }
        guard let note = try await Note.find(noteID, on: request.db) else {
            throw Abort(.notFound)
        }
        try await request.permissions.notes.edit(note)
        
        // TODO: Visibility cannot be more lenient than parent's
        let payload = try request.content.decode(NoteUpdatePayload.self)
        note.body = payload.body
        note.visibility = payload.visibility
        try await note.save(on: request.db)
        
        return .ok
    }
}
