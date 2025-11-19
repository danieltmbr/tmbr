import Core


struct GalleryViewModel: Encodable, Sendable {
    struct Item: Encodable, Sendable {
        
        private let id: ImageID
        
        private let key: String
        
        private let thumbnailKey: String
        
        private let alt: String
                
        private let url: String
        
        private let thumbnailURL: String
        
        init(
            id: ImageID,
            key: String,
            thumbnailKey: String,
            alt: String,
            baseURL: String
        ) {
            self.id = id
            self.key = key
            self.thumbnailKey = thumbnailKey
            self.alt = alt
            self.url = "\(baseURL)/gallery/data/\(key)"
            self.thumbnailURL = "\(baseURL)/gallery/data/\(thumbnailKey)"

        }
    }
    
    let items: [Item]
    
    init(images: [Image], baseURL: String) {
        self.items = images.compactMap { image in
            guard let imageID = image.id else { return nil }
            return Item(
                id: imageID,
                key: image.name,
                thumbnailKey: image.thumbnail,
                alt: image.alt ?? image.name,
                baseURL: baseURL
            )
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

