import Foundation

public struct HTTPHeader: Sendable {
    public let field: String
    public let value: String

    public init(field: String, value: String) {
        self.field = field
        self.value = value
    }
}

extension HTTPHeader {

    public struct ContentType: Sendable {
        private static let key = "Content-Type"
        public let json        = HTTPHeader(field: Self.key, value: "application/json")
        public let formEncoded = HTTPHeader(field: Self.key, value: "application/x-www-form-urlencoded")
    }

    public static let contentType = ContentType()

    public struct Authorization: Sendable {
        private static let key = "Authorization"
        public func bearer(_ token: String) -> HTTPHeader {
            HTTPHeader(field: Self.key, value: "Bearer \(token)")
        }
        public func basic(_ credentials: String) -> HTTPHeader {
            HTTPHeader(field: Self.key, value: "Basic \(credentials)")
        }
    }

    public static let authorization = Authorization()
}

public extension URLRequest {
    mutating func addHeader(_ header: HTTPHeader) {
        setValue(header.value, forHTTPHeaderField: header.field)
    }

    mutating func addHeaders(_ headers: HTTPHeader...) {
        headers.forEach { addHeader($0) }
    }
}
