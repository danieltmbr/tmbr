import WebAuth
import TmbrCore

struct NoteEditorViewModel: Encodable, Sendable {
    let id: String?
    let body: String
    let access: Access
    let language: Language
}
