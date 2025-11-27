import Vapor
import Fluent
import AuthKit

struct NotePayload: Content {
    var body: String
    var state: Note.State?
    var kind: Note.Kind?
    var attachmentType: String
    var attachmentID: Int
}

struct NoteUpdatePayload: Content {
    var body: String?
    var state: Note.State?
    var kind: Note.Kind?
}

struct NotesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let notes = routes.grouped("notes")
        notes.post(use: create)
        notes.get(":noteID", use: get)
        notes.put(":noteID", use: update)
        notes.delete(":noteID", use: delete)
    }

    func create(req: Request) async throws -> Note {
        let user = try req.auth.require(User.self)
        let payload = try req.content.decode(NotePayload.self)

        let note = Note(
            attachmentID: payload.attachmentID,
            authorID: try user.requireID(),
            body: payload.body,
            state: payload.state ?? .draft,
            kind: payload.kind
        )
        try await note.save(on: req.db)
        return note
    }

    func get(req: Request) async throws -> Note {
        guard
            let noteIDString = req.parameters.get("noteID"),
            let noteID = Int(noteIDString),
            let note = try await Note.find(noteID, on: req.db)
        else {
            throw Abort(.notFound)
        }
        return note
    }

    func update(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)

        guard
            let noteIDString = req.parameters.get("noteID"),
            let noteID = Int(noteIDString),
            let note = try await Note.find(noteID, on: req.db)
        else {
            throw Abort(.notFound)
        }

        if note.$author.id != user.id || user.role != .admin {
            throw Abort(.forbidden)
        }

        let payload = try req.content.decode(NoteUpdatePayload.self)

        if let body = payload.body {
            note.body = body
        }
        if let state = payload.state {
            note.state = state
        }
        if let kind = payload.kind {
            note.kind = kind
        }

        try await note.save(on: req.db)
        return .ok
    }

    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)

        guard
            let noteIDString = req.parameters.get("noteID"),
            let noteID = Int(noteIDString),
            let note = try await Note.find(noteID, on: req.db)
        else {
            throw Abort(.notFound)
        }

        if note.$author.id != user.id || user.role != .admin {
            throw Abort(.forbidden)
        }

        try await note.delete(on: req.db)
        return .noContent
    }
}
