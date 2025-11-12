#if os(macOS)

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

struct CGImageResizer: ImageResizer {
    
    func dimensions(of data: Data) -> CGSize {
        var size: CGSize = .zero
        if let src = CGImageSourceCreateWithData(data as CFData, nil),
           let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any] {
            if let w = props[kCGImagePropertyPixelWidth] as? NSNumber { size.width = w.doubleValue }
            if let h = props[kCGImagePropertyPixelHeight] as? NSNumber { size.height = h.doubleValue }
        }
        return size
    }
    
    func resize(_ data: Data, to size: CGSize) -> Data? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: min(size.width, size.height),
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let thumb = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary) else { return nil }
        let mutableData = CFDataCreateMutable(nil, 0)!
        let type = UTType.png.identifier as CFString
        guard let dest = CGImageDestinationCreateWithData(mutableData, type, 1, nil) else { return nil }
        let destOptions: [CFString: Any] = [:]
        CGImageDestinationAddImage(dest, thumb, destOptions as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return mutableData as Data
    }
}

#endif
