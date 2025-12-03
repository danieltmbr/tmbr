import Foundation

extension PlatformParser {
    
    static let applePodcasts = PlatformParser { url throws(ParseError) in
        guard let host = url.host?.lowercased(),
              host.contains("podcasts.apple.") || host.contains("podcasts.apple.com") else {
            throw ParseError.unsupportedURL(url)
        }
        return url.queryItem(name: "i")
    }
}
