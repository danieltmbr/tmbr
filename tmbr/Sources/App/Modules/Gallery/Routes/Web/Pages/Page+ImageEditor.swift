import Core
import Vapor

struct ImageEditorViewModel: Encodable, Sendable {
        
    let _csrf: String?
    
    private let error: String?
    
    private let image: ImageViewModel
    
    private let submit: Form.Submit
    
    init(
        _csrf: String?,
        error: String? = nil,
        image: ImageViewModel,
        submit: Form.Submit
    ) {
        self.image = image
        self._csrf = _csrf
        self.error = error
        self.submit = submit
    }
}

extension Template where Model == ImageEditorViewModel {
    
    static let imageEditor = Template(name: "Gallery/image-editor")
}

extension Page {
    static var imageEditor: Page {
        Page(template: .imageEditor) { request in
            guard let imageID = request.parameters.get("imageID", as: ImageID.self) else {
                throw Abort(.badRequest, reason: "Image ID is incorrect or missing.")
            }
            let image = try await request.commands.gallery.fetch(imageID, for: .write)
            let model = ImageEditorViewModel(
                _csrf: UUID().uuidString,
                image: ImageViewModel(
                    imageID: imageID,
                    image: image,
                    baseURL: request.baseURL
                ),
                submit: Form.Submit(
                    action: "/gallery/\(imageID)/edit",
                    label: "Save"
                )
            )
            request.session.data["csrf.image-editor"] = model._csrf
            return model
        }
    }
}
