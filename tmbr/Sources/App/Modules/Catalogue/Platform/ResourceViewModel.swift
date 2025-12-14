import Foundation

struct ResourceViewModel: Encodable, Sendable {
    
    private let platform: String
    
    private let url: String
    
    init(platform: String, url: String) {
        self.platform = platform
        self.url = url
    }
    
    init(resource: Resource) {
        self.init(
            platform: resource.platform,
            url: resource.url.absoluteString
        )
    }
}
