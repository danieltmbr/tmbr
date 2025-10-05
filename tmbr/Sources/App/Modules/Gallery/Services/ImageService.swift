import Vapor
import Foundation
import CoreGraphics
import ImageIO
import NIOFoundationCompat
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

struct ImageMetadata: Sendable {
    let path: String
    let thumbnailPath: String
    let size: CGSize
}

actor ImageService {
    
    struct MediaType: Equatable {
        let httpType: HTTPMediaType
        
        let fileExtension: String
        
        static let png = MediaType(httpType: .png, fileExtension: "png")
        
        static let jpeg = MediaType(httpType: .jpeg, fileExtension: "jpg")
        
        static let webp = MediaType(
            httpType: HTTPMediaType(type: "image", subType: "webp"),
            fileExtension: "webp"
        )
        
        static let gif = MediaType(httpType: .gif, fileExtension: "gif")
        
        static let svg = MediaType(
            httpType: HTTPMediaType(type: "image", subType: "svg+xml"),
            fileExtension: "svg"
        )
    }
    
    private let allowedMediaTypes: [MediaType]
    
    private let absoluteFolderPath: String
    
    private let relativeFolderPath: String

    init(
        allowedMediaTypes: [MediaType] = [.png, .jpeg, .webp, .gif, .svg],
        relativeFolderPath: String = "uploads/images",
        publicDirectory: String
    ) {
        self.allowedMediaTypes = allowedMediaTypes
        self.absoluteFolderPath = publicDirectory.appending(relativeFolderPath)
        self.relativeFolderPath = relativeFolderPath
    }

    func storeImage(file: File) async throws -> ImageMetadata {
        let mediaType = try validateAndResolveMediaType(for: file)
        let uuid = UUID().uuidString
        let filename = "\(uuid).\(mediaType.fileExtension)"
        let relativePath = "/\(relativeFolderPath)/\(filename)"
        let absolutePath = "\(absoluteFolderPath)/\(filename)"

        try FileManager.default.createDirectory(
            atPath: absoluteFolderPath,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let imageData = Data(buffer: file.data)
        try write(data: imageData, to: absolutePath)

        let thumbnailRelativePath: String
        if mediaType != .svg, let thumbnailData = makeThumbnail(from: imageData) {
            let thumbnailFilename = "\(uuid)-thumbnail.\(mediaType.fileExtension)"
            let thumbnailAbsolutePath = "\(absoluteFolderPath)/\(thumbnailFilename)"
            
            try write(data: thumbnailData, to: thumbnailAbsolutePath)
            thumbnailRelativePath = "/\(relativeFolderPath)/\(thumbnailFilename)"
        } else {
            thumbnailRelativePath = relativePath
        }

        return ImageMetadata(
            path: relativePath,
            thumbnailPath: thumbnailRelativePath,
            size: dimensions(of: imageData)
        )
    }

    // MARK: - Helpers

    private func validateAndResolveMediaType(for file: File) throws -> MediaType {
        guard let contentType = file.contentType else {
            throw Abort(.unsupportedMediaType, reason: "Missing content type")
        }
        guard let mediaType = allowedMediaTypes.first(where: { $0.httpType == contentType }) else {
            throw Abort(.unsupportedMediaType, reason: "Unsupported image content type")
        }
        return mediaType
    }

    private func write(data: Data, to absolutePath: String) throws {
        let url = URL(fileURLWithPath: absolutePath)
        try data.write(to: url, options: .atomic)
    }

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
}
