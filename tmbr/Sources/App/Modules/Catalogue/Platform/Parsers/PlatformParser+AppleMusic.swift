import Foundation

extension PlatformParser {
    static let appleMusic = PlatformParser { url throws(ParseError) in
        guard url.host?.lowercased().contains("music.apple.com") ?? false else {
            throw ParseError.unsupportedURL(url)
        }
        return url.queryItem(name: "i")
    }
}
