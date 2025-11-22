import Core

struct GalleryViewModel: Encodable, Sendable {

    private let title: String = "Gallery"
    
    private let images: [ImageViewModel]
    
    init(images: [Image], baseURL: String) {
        self.images = images.compactMap { image in
            ImageViewModel(image: image, baseURL: baseURL)
        }
    }
}

extension Template where Model == GalleryViewModel {
    
    static let gallery = Template(name: "Gallery/gallery")
    
    static let embeddedGallery = Template(name: "Gallery/gallery-embedded")
    
    static func gallery(embedded: Bool) -> Self {
        embedded ? .embeddedGallery : .gallery
    }
}

extension Page {
    static var gallery: Page {
        Page { request in
            let images = try await request.commands.gallery.list()
            let model = GalleryViewModel(images: images, baseURL: request.baseURL)
            let template: Template = .gallery(embedded: request.query["embedded"] ?? false)
            return try await template.render(model, with: request.view)
        }
    }
}

