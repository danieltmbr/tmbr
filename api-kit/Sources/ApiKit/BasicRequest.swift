import Foundation

public struct BasicRequest<Input: Sendable, Response: Decodable & Sendable>: Request {

    private let url: URL
    private let build: @Sendable (URL, Input, String?, JSONEncoder) throws -> URLRequest

    public init(
        url: URL,
        build: @escaping @Sendable (URL, Input, String?, JSONEncoder) throws -> URLRequest
    ) {
        self.url = url
        self.build = build
    }

    public func makeRequest(from input: Input, token: String?, using encoder: JSONEncoder) throws -> URLRequest {
        try build(url, input, token, encoder)
    }
}

// MARK: - No-body factories

public extension BasicRequest where Input == Void {

    static func get(baseURL: URL, path: String) -> Self {
        BasicRequest(url: baseURL.appending(path: path)) { url, _, token, _ in
            var req = URLRequest(url: url)
            req.httpMethod = HTTPMethod.get.rawValue
            if let token { req.addHeader(.authorization.bearer(token)) }
            return req
        }
    }

    static func delete(baseURL: URL, path: String) -> Self {
        BasicRequest(url: baseURL.appending(path: path)) { url, _, token, _ in
            var req = URLRequest(url: url)
            req.httpMethod = HTTPMethod.delete.rawValue
            if let token { req.addHeader(.authorization.bearer(token)) }
            return req
        }
    }
}

// MARK: - Body & query factories

public extension BasicRequest where Input: Encodable {

    static func post(baseURL: URL, path: String) -> Self {
        BasicRequest(url: baseURL.appending(path: path)) { url, body, token, encoder in
            var req = URLRequest(url: url)
            req.httpMethod = HTTPMethod.post.rawValue
            req.addHeader(.contentType.json)
            req.httpBody = try encoder.encode(body)
            if let token { req.addHeader(.authorization.bearer(token)) }
            return req
        }
    }

    static func put(baseURL: URL, path: String) -> Self {
        BasicRequest(url: baseURL.appending(path: path)) { url, body, token, encoder in
            var req = URLRequest(url: url)
            req.httpMethod = HTTPMethod.put.rawValue
            req.addHeader(.contentType.json)
            req.httpBody = try encoder.encode(body)
            if let token { req.addHeader(.authorization.bearer(token)) }
            return req
        }
    }

    static func patch(baseURL: URL, path: String) -> Self {
        BasicRequest(url: baseURL.appending(path: path)) { url, body, token, encoder in
            var req = URLRequest(url: url)
            req.httpMethod = HTTPMethod.patch.rawValue
            req.addHeader(.contentType.json)
            req.httpBody = try encoder.encode(body)
            if let token { req.addHeader(.authorization.bearer(token)) }
            return req
        }
    }

    static func query(baseURL: URL, path: String) -> Self {
        BasicRequest(url: baseURL.appending(path: path)) { url, params, token, _ in
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw URLBuildingError.invalidURL(url)
            }
            components.queryItems = try QueryItemEncoder().encode(params)
            guard let finalURL = components.url else {
                throw URLBuildingError.invalidComponents(components)
            }
            var req = URLRequest(url: finalURL)
            req.httpMethod = HTTPMethod.get.rawValue
            if let token { req.addHeader(.authorization.bearer(token)) }
            return req
        }
    }
}

// MARK: - Errors

enum URLBuildingError: Error {
    case invalidURL(URL)
    case invalidComponents(URLComponents)
}
