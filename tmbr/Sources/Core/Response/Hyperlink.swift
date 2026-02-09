import Foundation

public struct Hyperlink: Codable, Sendable {
    
    public let label: String
    
    public let url: URL
    
    public init(label: String, url: URL) {
        self.label = label
        self.url = url
    }
}
