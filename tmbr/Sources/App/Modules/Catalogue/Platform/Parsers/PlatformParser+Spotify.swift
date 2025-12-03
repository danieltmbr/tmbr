import Foundation

extension PlatformParser {
    
    static let spotify = PlatformParser { url throws(ParseError) in
        guard let host = url.host?.lowercased(), host.contains("spotify.") else {
            throw ParseError.unsupportedURL(url)
        }
        // Expect paths like /track/<id>, /album/<id>, /artist/<id>, /playlist/<id>
        let entities = ["track", "album", "artist", "playlist", "show", "episode"]
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count >= 2 else { return nil }
        guard entities.contains(components.first) else { return nil }
        return components.last
    }
    
}
