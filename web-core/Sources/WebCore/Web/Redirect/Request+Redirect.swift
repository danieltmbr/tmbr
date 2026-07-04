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

    public static let clearDraftKey = "clearDraft"

    public static func clearDraft(key: String) -> Self {
        URLQueryItem(name: Self.clearDraftKey, value: key)
    }
}

extension [URLQueryItem] {
    public func item(named name: String) -> URLQueryItem? {
        first(where: { $0.name == name })
    }
}

extension String {
    /// Appends a `clearDraft` query item pointing at the client's localStorage
    /// draft key, so the next page load can clear it once success is confirmed
    /// (see `Scripts/Shared/draft-clear.js`). No-op if `key` is nil or empty.
    public func addingClearDraft(_ key: String?) -> String {
        guard let key, !key.isEmpty, var components = URLComponents(string: self) else { return self }
        var items = components.queryItems ?? []
        items.append(.clearDraft(key: key))
        components.queryItems = items
        return components.string ?? self
    }
}
