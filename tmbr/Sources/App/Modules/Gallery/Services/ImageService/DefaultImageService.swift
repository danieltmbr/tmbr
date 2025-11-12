import Vapor
import Foundation
import NIOFoundationCompat

actor DefaultImageService: ImageService {
    
    private let allowedMediaTypes: [MediaContentType]
    
    private let resizer: ImageResizer
    
    private let storage: FileStorage
    
    init(
        allowedMediaTypes: [MediaContentType],
        resizer: ImageResizer,
        storage: FileStorage
    ) {
        self.allowedMediaTypes = allowedMediaTypes
        self.resizer = resizer
        self.storage = storage
    }
    
    init(
        allowedMediaTypes: [MediaContentType] = [.png, .jpeg, .webp, .gif, .svg],
        storage: FileStorage
    ) {
        #if os(Linux)
        self.init(
            allowedMediaTypes: allowedMediaTypes,
            resizer: CImageResizer(),
            storage: storage
        )
        #else
        self.init(
            allowedMediaTypes: allowedMediaTypes,
            resizer: CGImageResizer(),
            storage: storage
        )
        #endif
    }
    
    func contentType(for name: String) async throws -> MediaContentType {
        guard let fileExtension = name.split(separator: ".").last,
              let contentType = allowedMediaTypes.first(where: { $0.fileExtension == fileExtension }) else {
            throw Abort(.unsupportedMediaType, reason: "Unsupported image content type")
        }
        return contentType
    }
    
    func delete(_ name: String) async throws {
        try await storage.delete(name: name)
    }
    
    func image(for name: String) async throws -> Data {
        try await storage.file(named: name)
    }
    
    func store(image file: File) async throws -> ImageMetadata {
        let mediaType = try validateAndResolveMediaType(for: file)
        let uuid = UUID().uuidString
        let fileName = "\(uuid).\(mediaType.fileExtension)"
        let imageData = Data(buffer: file.data)
        
        try await storage.store(
            data: imageData,
            contentType: mediaType.contentType,
            name: fileName
        )
        
        let thumbnailFileName: String
        if (mediaType == .jpeg || mediaType == .png), let thumbnailData = resizer.resize(imageData) {
            thumbnailFileName = "\(uuid)-thumbnail.png"
            try await storage.store(
                data: thumbnailData,
                contentType: HTTPMediaType.png.serialize(),
                name: thumbnailFileName
            )
        } else {
            thumbnailFileName = fileName
        }
        
        return ImageMetadata(
            key: fileName,
            thumbnailKey: thumbnailFileName,
            size: resizer.dimensions(of: imageData)
        )
    }
    
    // MARK: - Helpers
    
    private func validateAndResolveMediaType(for file: File) throws -> MediaContentType {
        guard let contentType = file.contentType else {
            throw Abort(.unsupportedMediaType, reason: "Missing content type")
        }
        guard let mediaType = allowedMediaTypes.first(where: { $0.httpType == contentType }) else {
            throw Abort(.unsupportedMediaType, reason: "Unsupported image content type")
        }
        return mediaType
    }
}
