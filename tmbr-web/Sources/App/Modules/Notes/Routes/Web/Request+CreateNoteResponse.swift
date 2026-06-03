import Vapor
import Core
import TmbrCore

extension Request {
    func createNoteResponse(attachmentID: UUID) async throws -> Response {
        guard let payload = try? content.decode(NotePayload.self) else {
            return Response(status: .badRequest)
        }
        let input = CreateNoteInput(body: payload.body, access: payload.access, attachmentID: attachmentID)
        let note = try await commands.notes.create(input)
        let model = try NoteViewModel(note: note, isEditable: true)
        let view = try await Template.noteItem.render(NoteItemContext(note: model), with: self.view)
        return try await view.encodeResponse(for: self)
    }
}
