import Foundation
import ImageResize

struct CImageResizer: ImageResizer {
    
    func dimensions(of data: Data) -> CGSize {
        ImageResize.dimensions(of: data)
    }
    
    func resize(_ data: Data, to size: CGSize) -> Data? {
        guard size.width > 0, size.height > 0 else { return nil }
        
        guard let src = ImageResize.decodeToRGBA(data) else { return nil }
        
        let target = fittedSize(source: CGSize(width: src.width, height: src.height), max: size)
        
        guard let dst = ImageResize.resizeRGBA(src, to: Int(target.width), Int(target.height)) else { return nil }

        return ImageResize.encodePNG(dst)
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
}
