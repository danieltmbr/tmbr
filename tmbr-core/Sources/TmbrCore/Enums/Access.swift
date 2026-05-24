import Foundation

public enum Access: String, Codable, Sendable {
    case `private`
    case `public`
}

public func && (lhs: Access, rhs: Access) -> Access {
    lhs == .public && rhs == .public ? .public : .private
}
