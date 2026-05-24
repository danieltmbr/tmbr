import Foundation
import Vapor

extension Request {
    public var redirectReturnDestination: String? {
        get { session.data[Page.Redirect.sessionKey] }
        set { session.data[Page.Redirect.sessionKey] = newValue }
    }
}

extension URI {
    public var queryItems: [URLQueryItem]? {
        guard let query,
              let components = URLComponents(string: "/?\(query)"),
              let items = components.queryItems else {
            return nil
        }
        return items
    }
}

extension URLQueryItem {
    public static let redirectReturnKey = "redirectReturn"
    
    public static func redirectReturn(path: String) -> Self {
        URLQueryItem(name: Self.redirectReturnKey, value: path)
    }
}

extension [URLQueryItem] {
    public func item(named name: String) -> URLQueryItem? {
        first(where: { $0.name == name })
    }
}
