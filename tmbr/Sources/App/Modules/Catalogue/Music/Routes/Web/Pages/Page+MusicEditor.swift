import Vapor
import Core
import Foundation

struct MusicEditorViewModel: Encodable, Sendable {

    struct NoteViewModel: Encodable, Sendable {
        let id: String?
        let body: String
        let access: String
    }

    
    let _csrf: String?
    
    let error: String? = nil
    
    let id: Int? = nil
    
    let notes: [NoteViewModel] = []
    
    let pageTitle: String
    
    let resourceURLs: [String] = []
    
    let submit: Form.Submit
}

extension Template where Model == MusicEditorViewModel {
    static let musicEditor = Template(name: "Catalogue/Music/music-editor")
}

extension Page {
    static var newMusic: Self {
        Page(template: .musicEditor) { req in
            let allowed: ComposeDefinition = req.permissions.compose(.music)
            guard !allowed.sections.isEmpty else {
                throw Abort(.unauthorized)
            }
            let csrf = UUID().uuidString
            req.session.data["csrf.editor"] = csrf
            return MusicEditorViewModel(
                _csrf: csrf,
                pageTitle: "New music",
                submit: Form.Submit(action: "/songs/new", label: "Save")
            )
        }
    }
}
