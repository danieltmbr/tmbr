import Vapor
import Fluent
import AuthKit

struct NotePayload: Content {
    var body: String
    
    var access: Access

    var attachmentID: UUID
}

struct NoteUpdatePayload: Content {
    
    var body: String
    
    var access: Access
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
        let userID = try user.requireID()
        let payload = try req.content.decode(NotePayload.self)
        
        // TODO: Use Preview Command
        guard let preview = try await Preview.find(payload.attachmentID, on: req.db) else {
            throw Abort(.badRequest, reason: "There is no Attachment with the provided ID.")
        }
        guard userID == preview.parentOwner.id else {
            throw Abort(.forbidden, reason: "Only the owner can add a note.")
        }

        let note = Note(
            attachmentID: payload.attachmentID,
            authorID: userID,
            access: preview.parentAccess || payload.access,
            body: payload.body
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
        
        let payload = try request.content.decode(NoteUpdatePayload.self)
        note.body = payload.body
        note.access = note.attachment.parentAccess || payload.access
        try await note.save(on: request.db)
        
        return .ok
    }
}
