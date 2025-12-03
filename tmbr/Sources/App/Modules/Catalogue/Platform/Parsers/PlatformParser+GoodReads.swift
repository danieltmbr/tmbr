import Foundation

extension PlatformParser {

    static let goodreads = PlatformParser { url throws(ParseError) in
        guard let host = url.host?.lowercased(), host.contains("goodreads.") else {
            throw ParseError.unsupportedURL(url)
        }
        // Expect /book/show/<id>-<slug>
        let comps = url.pathComponents.filter { $0 != "/" }
        guard let idx = comps.firstIndex(of: "show"),
              comps.indices.contains(comps.index(after: idx)) else {
            return nil
        }
        let part = comps[comps.index(after: idx)]
        // Extract numeric prefix before '-' if present
        if let dash = part.firstIndex(of: "-") {
            let prefix = String(part[..<dash])
            return prefix.isEmpty ? nil : prefix
        }
        return part.isEmpty ? nil : part
    }
}
