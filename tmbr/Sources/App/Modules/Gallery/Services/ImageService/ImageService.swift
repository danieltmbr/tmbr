import Vapor
import Foundation
import CoreGraphics
import ImageIO
import NIOFoundationCompat
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

struct ImageMetadata: Sendable {
    let key: String

    let thumbnailKey: String
    
    let size: CGSize
}

protocol ImageService: Sendable {
    
    func contentType(for key: String) async throws -> MediaContentType
    
    func delete(_ key: String) async throws
    
    func image(for key: String) async throws -> Data
    
    func store(image: File) async throws -> ImageMetadata
}
