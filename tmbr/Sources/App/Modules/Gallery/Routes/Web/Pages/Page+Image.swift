import Core
import Vapor

struct ImageViewModel: Encodable, Sendable {
    
    private let id: ImageID
    
    private let key: String
    
    private let thumbnailKey: String
        
    private let alt: String
    
    private let url: String
    
    private let thumbnailURL: String
    
    private let width: Int
    
    private let height: Int
    
    private let uploadedAt: String
    
    init(
        id: ImageID,
        key: String,
        thumbnailKey: String,
        alt: String,
        url: String,
        thumbnailURL: String,
        width: Int,
        height: Int,
        uploadedAt: String
    ) {
        self.id = id
        self.key = key
        self.thumbnailKey = thumbnailKey
        self.alt = alt
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.width = width
        self.height = height
        self.uploadedAt = uploadedAt
    }
    
    init(
        id: ImageID,
        key: String,
        thumbnailKey: String,
        alt: String,
        size: CGSize,
        uploadedAt: String,
        baseURL: String
    ) {
        self.init(
            id: id,
            key: key,
            thumbnailKey: thumbnailKey,
            alt: alt,
            url: "\(baseURL)/gallery/data/\(key)",
            thumbnailURL: "\(baseURL)/gallery/data/\(thumbnailKey)",
            width: Int(size.width),
            height: Int(size.height),
            uploadedAt: uploadedAt
        )
    }
    
    init(
        imageID: ImageID,
        image: Image,
        baseURL: String
    ) {
        self.init(
            id: imageID,
            key: image.key,
            thumbnailKey: image.thumbnailKey,
            alt: image.alt ?? image.key,
            size: CGSize(
                width: image.size.width,
                height: image.size.height
            ),
            uploadedAt: (image.uploadedAt ?? .now).formatted(.publishDate),
            baseURL: baseURL
        )
    }
    
    init?(image: Image, baseURL: String) {
        guard let imageID = image.id else { return nil }
        self.init(imageID: imageID, image: image, baseURL: baseURL)
    }
}

extension Template where Model == ImageViewModel {
    
    static let image = Template(name: "Gallery/image")
}

extension Page {
    static var image: Page {
        Page(template: .image) { request in
            guard let imageID = request.parameters.get("imageID", as: ImageID.self) else {
                throw Abort(.badRequest, reason: "Image ID is incorrect or missing.")
            }
            let image = try await request.commands.gallery.fetch(imageID, for: .read)
            return ImageViewModel(
                imageID: imageID,
                image: image,
                baseURL: request.baseURL
            )
        }
    }
}
