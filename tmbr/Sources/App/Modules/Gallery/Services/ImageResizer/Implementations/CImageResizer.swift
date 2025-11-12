import Foundation
import ImageCWrapper

struct CImageResizer: ImageResizer {
    
    // Public API expected by your protocol
    func dimensions(of data: Data) -> CGSize {
        switch sniffFormat(data) {
        case .png:
            if let (w, h) = pngHeaderSize(data) {
                return CGSize(width: w, height: h)
            }
        case .jpeg:
            if let (w, h) = jpegHeaderSize(data) {
                return CGSize(width: w, height: h)
            }
        case .gif, .webp, .unknown:
            break
        }
        if let src = ImageC.decodeToRGBA(data) {
            return CGSize(width: src.width, height: src.height)
        }
        return .zero
    }
    
    func resize(_ data: Data, to size: CGSize) -> Data? {
        guard size.width > 0, size.height > 0 else { return nil }
        
        guard let src = ImageC.decodeToRGBA(data) else { return nil }
        
        let target = fittedSize(source: CGSize(width: src.width, height: src.height), max: size)
        
        guard let dst = ImageC.resizeRGBA(src, to: Int(target.width), Int(target.height)) else { return nil }
        
        return ImageC.encodePNG(dst)
    }
}

// MARK: - Format detection
private enum ImageFormat { case png, jpeg, gif, webp, unknown }

private func sniffFormat(_ data: Data) -> ImageFormat {
    if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return .png } // "\x89PNG"
    if data.starts(with: [0xFF, 0xD8, 0xFF]) { return .jpeg }      // JPEG SOI
    if data.starts(with: [0x47, 0x49, 0x46, 0x38]) { return .gif } // "GIF8"
    if data.starts(with: [0x52, 0x49, 0x46, 0x46]) && data.count >= 12 {
        // RIFF....WEBP
        let fourcc = data[8..<12]
        if String(bytes: fourcc, encoding: .ascii) == "WEBP" { return .webp }
    }
    return .unknown
}

// MARK: - Header-only size reads (fast path)
private func pngHeaderSize(_ data: Data) -> (Int, Int)? {
    // PNG IHDR is at fixed offset after 8-byte signature: 8(sig) + 4(len) + 4(\"IHDR\")
    // Then IHDR payload: width(4), height(4)
    guard data.count >= 24 else { return nil }
    // Validate signature
    let sig: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    guard data.starts(with: sig) else { return nil }
    // IHDR chunk follows
    // width: bytes 16..19, height: 20..23 (big-endian)
    let w = data[16...19].reduce(0) { ($0 << 8) | Int($1) }
    let h = data[20...23].reduce(0) { ($0 << 8) | Int($1) }
    guard w > 0 && h > 0 else { return nil }
    return (w, h)
}

private func jpegHeaderSize(_ data: Data) -> (Int, Int)? {
    // Parse JPEG markers until SOF0/SOF2 to get size
    // Minimal parser for size only
    guard data.count > 4, data[0] == 0xFF, data[1] == 0xD8 else { return nil }
    var i = 2
    while i + 9 < data.count {
        if data[i] != 0xFF { i += 1; continue }
        var marker = data[i + 1]
        i += 2
        while marker == 0xFF, i < data.count {
            marker = data[i]
            i += 1
        }
        if marker == 0xD9 || marker == 0xDA { break } // EOI or SOS
        if i + 1 >= data.count { break }
        let length = Int(data[i]) << 8 | Int(data[i + 1])
        if length < 2 || i + length > data.count { break }
        // SOF0(0xC0) or SOF2(0xC2) carry size
        if marker == 0xC0 || marker == 0xC2 {
            if i + 7 <= data.count {
                let height = Int(data[i + 3]) << 8 | Int(data[i + 4])
                let width  = Int(data[i + 5]) << 8 | Int(data[i + 6])
                return (width, height)
            }
            break
        }
        i += length
    }
    return nil
}

// MARK: - Resize helpers
private func fittedSize(source: CGSize, max maxSize: CGSize) -> CGSize {
    let sw = source.width, sh = source.height
    let mw = maxSize.width, mh = maxSize.height
    guard sw > 0, sh > 0, mw > 0, mh > 0 else { return .zero }
    let scale = min(mw / sw, mh / sh)
    return CGSize(
        width: max(1, floor(sw * scale)),
        height: max(1, floor(sh * scale))
    )
}
