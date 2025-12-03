import Foundation

struct PlatformParser: Sendable {
    
    enum ParseError: Error {
        case unsupportedURL(URL)
    }
    
    private let parser: @Sendable (URL) throws(ParseError) -> String?
    
    init(parse: @escaping @Sendable (URL) throws(ParseError) -> String?) {
        self.parser = parse
    }
    
    func extractID(from url: URL) throws(ParseError) -> String? {
        try parser(url)
    }
}

extension URL {
    func queryItem(name: String) -> String? {
        let components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems
        let item = queryItems?.first(where: { $0.name == name })
        return item?.value
    }
}
