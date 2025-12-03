import Foundation

extension PlatformParser {
    
    static let imdb = PlatformParser { url throws(ParseError) in
        guard let host = url.host?.lowercased(), host.contains("imdb.") else {
            throw ParseError.unsupportedURL(url)
        }
        // Expect paths like /title/tt1234567 or /name/nm1234567
        let comps = url.pathComponents.filter { $0 != "/" }
        guard comps.count >= 2 else { return nil }
        return comps.first(where: { $0.hasPrefix("tt") || $0.hasPrefix("nm") })
    }
}
