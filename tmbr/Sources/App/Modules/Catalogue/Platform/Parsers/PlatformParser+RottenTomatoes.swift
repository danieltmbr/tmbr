import Foundation

extension PlatformParser {
    
    static let rottenTomatoes = PlatformParser { url throws(ParseError) in
        guard let host = url.host?.lowercased(), host.contains("rottentomatoes.") else {
            throw ParseError.unsupportedURL(url)
        }
        // m/movie_name, tv/tv_show_name
        let entitites = ["m", "tv"]
        let components = url.pathComponents.filter { $0 != "/" }.suffix(2)
        guard components.count == 2 else { return nil }
        guard entitites.contains(components.first) else { return nil }
        return components.last
    }
}

extension Sequence {
    func contains(_ element: Element?) -> Bool {
        guard let element else { return false }
        return self.contains(element)
    }
}
