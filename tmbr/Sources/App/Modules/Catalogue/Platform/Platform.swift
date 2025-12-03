import Foundation

struct Platform<MediaItem>: Sendable {
    
    private let extract: @Sendable (URL) -> Resource?
    
    init(extract: @escaping @Sendable (URL) -> Resource?) {
        self.extract = extract
    }
    
    init(
        displayName: String,
        parser: PlatformParser
    ) {
        self.init { url in
            do {
                let externalID = try parser.extractID(from: url)
                return Resource(
                    platform: displayName,
                    url: url,
                    externalID: externalID
                )
            } catch {
                return nil
            }
        }
    }
    
    init(platforms: [Platform]) {
        self.init { url in
            for platform in platforms {
                if let resource = platform.resource(from: url) {
                    return resource
                }
            }
            return nil
        }
    }
    
    func resource(from url: URL) -> Resource? {
        extract(url)
    }
    
    func resource(from urlString: String) -> Resource? {
        guard let url = URL(string: urlString) else {
            return nil
        }
        return resource(from: url)
    }
}
