import Foundation

protocol ImageResizer: Sendable {
    
    func dimensions(of data: Data) -> CGSize
    
    func resize(_ data: Data, to size: CGSize) -> Data?
}

extension ImageResizer {
    func resize(_ data: Data) -> Data? {
        resize(data, to: CGSize(width: 200, height: 200))
    }
}
