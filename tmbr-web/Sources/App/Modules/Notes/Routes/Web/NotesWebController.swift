import Vapor
import Fluent
import AuthKit
import Core
import TmbrCore

struct NotesWebController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let notes = routes.grouped("notes")
        notes.put(":noteID", use: edit)
    }

    @Sendable
    private func edit(request: Request) async throws -> Response {
        guard let noteID = request.parameters.get("noteID", as: NoteID.self) else {
            return Response(status: .badRequest)
        }
        guard let payload = try? request.content.decode(NotePayload.self) else {
            return Response(status: .badRequest)
        }
        do {
            let note = try await request.commands.notes.edit(noteID, with: payload)
            let model = try NoteViewModel(note: note, isEditable: true)
            let view = try await Template.noteItem.render(NoteItemContext(note: model), with: request.view)
            return try await view.encodeResponse(for: request)
        } catch {
            let errorMessage = noteErrorMessage(for: error, on: request)
            let model = NoteViewModel(
                id: noteID,
                body: "",
                created: "",
                editDetails: NoteViewModel.EditDetails(
                    rawBody: payload.body,
                    access: payload.access.rawValue,
                    language: (payload.language ?? .en).rawValue
                ),
                error: errorMessage
            )
            let view = try await Template.noteItem.render(NoteItemContext(note: model), with: request.view)
            let response = try await view.encodeResponse(for: request)
            response.status = .unprocessableEntity
            return response
        }
    }

    private func noteErrorMessage(for error: Error, on request: Request) -> String {
        if let abort = error as? AbortError {
            switch abort.status {
            case .unauthorized:
                return "Please sign in to edit notes."
            case .forbidden:
                return "You don't have permission to edit this note."
            case .notFound:
                return "This note no longer exists."
            case .badRequest:
                return abort.reason.isEmpty ? "Please check your input and try again." : abort.reason
            default:
                break
            }
        }
        return "Something went wrong. Please try again."
    }
}
