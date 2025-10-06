import Vapor
import Foundation
import CoreGraphics
import ImageIO
import NIOFoundationCompat
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

actor DefaultImageService: ImageService {
    
    private let allowedMediaTypes: [MediaContentType]
    
    private let storage: FileStorage
    
    init(
        allowedMediaTypes: [MediaContentType] = [.png, .jpeg, .webp, .gif, .svg],
        storage: FileStorage
    ) {
        self.allowedMediaTypes = allowedMediaTypes
        self.storage = storage
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
        if mediaType != .svg, let thumbnailData = makeThumbnail(from: imageData) {
            thumbnailFileName = "\(uuid)-thumbnail.\(mediaType.fileExtension)"
            try await storage.store(
                data: thumbnailData,
                contentType: mediaType.contentType,
                name: thumbnailFileName
            )
        } else {
            thumbnailFileName = fileName
        }
        
        return ImageMetadata(
            key: fileName,
            thumbnailKey: thumbnailFileName,
            size: dimensions(of: imageData)
        )
    }
    
    // MARK: - Helpers
    
    private func dimensions(of data: Data) -> CGSize {
        var size: CGSize = .zero
        if let src = CGImageSourceCreateWithData(data as CFData, nil),
           let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any] {
            if let w = props[kCGImagePropertyPixelWidth] as? NSNumber { size.width = w.doubleValue }
            if let h = props[kCGImagePropertyPixelHeight] as? NSNumber { size.height = h.doubleValue }
        }
        return size
    }
    
    private func makeThumbnail(from data: Data, maxPixel: Int = 200) -> Data? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let thumb = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary) else { return nil }
        let mutableData = CFDataCreateMutable(nil, 0)!
        let type: CFString
#if canImport(UniformTypeIdentifiers)
        type = UTType.jpeg.identifier as CFString
#else
        type = "public.jpeg" as CFString
#endif
        guard let dest = CGImageDestinationCreateWithData(mutableData, type, 1, nil) else { return nil }
        let destOptions: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.85]
        CGImageDestinationAddImage(dest, thumb, destOptions as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return mutableData as Data
    }
    
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
