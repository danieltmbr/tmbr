import Foundation

extension PlatformParser {
    
    static let youtube = PlatformParser { url throws(ParseError) in
        guard let host = url.host?.lowercased(),
              host.contains("youtube.") || host.contains("youtu.be") else {
            throw ParseError.unsupportedURL(url)
        }
        if host.contains("youtu.be") {
            return url.pathComponents.last
        } else {
            // youtube.com/watch?v=VIDEO_ID
            return url.queryItem(name: "v")
        }
    }
}
