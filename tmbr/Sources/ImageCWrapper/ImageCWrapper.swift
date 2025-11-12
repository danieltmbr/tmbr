import Foundation
#if os(Linux)
import Glibc
#endif

public struct ImageRGBA {
    public let width: Int
    public let height: Int
    public var data: Data
}

@_silgen_name("decode_to_rgba")
private func c_decode_to_rgba(_ bytes: UnsafePointer<UInt8>, _ length: Int32, _ outW: UnsafeMutablePointer<Int32>, _ outH: UnsafeMutablePointer<Int32>) -> UnsafeMutablePointer<UInt8>?

@_silgen_name("resize_rgba")
private func c_resize_rgba(_ src: UnsafePointer<UInt8>, _ srcW: Int32, _ srcH: Int32, _ newW: Int32, _ newH: Int32) -> UnsafeMutablePointer<UInt8>?

@_silgen_name("encode_png")
private func c_encode_png(_ rgba: UnsafePointer<UInt8>, _ w: Int32, _ h: Int32, _ outLen: UnsafeMutablePointer<Int32>) -> UnsafeMutablePointer<UInt8>?

public enum ImageC {
    public static func decodeToRGBA(_ data: Data) -> ImageRGBA? {
        return data.withUnsafeBytes { raw in
            guard let base = raw.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return nil }
            var w: Int32 = 0
            var h: Int32 = 0
            guard let ptr = c_decode_to_rgba(base, Int32(data.count), &w, &h) else { return nil }
            defer { free(ptr) }
            let count = Int(w) * Int(h) * 4
            let buffer = Data(bytes: ptr, count: count)
            return ImageRGBA(width: Int(w), height: Int(h), data: buffer)
        }
    }
    
    public static func resizeRGBA(_ image: ImageRGBA, to newW: Int, _ newH: Int) -> ImageRGBA? {
        return image.data.withUnsafeBytes { raw in
            guard let base = raw.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return nil }
            guard let ptr = c_resize_rgba(base, Int32(image.width), Int32(image.height), Int32(newW), Int32(newH)) else { return nil }
            defer { free(ptr) }
            let count = newW * newH * 4
            let buffer = Data(bytes: ptr, count: count)
            return ImageRGBA(width: newW, height: newH, data: buffer)
        }
    }
    
    public static func encodePNG(_ image: ImageRGBA) -> Data? {
        return image.data.withUnsafeBytes { raw in
            guard let base = raw.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return nil }
            var len: Int32 = 0
            guard let ptr = c_encode_png(base, Int32(image.width), Int32(image.height), &len) else { return nil }
            defer { free(ptr) }
            return Data(bytes: ptr, count: Int(len))
        }
    }
}
