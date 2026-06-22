import Foundation
import CoreTmbr

/// The default `Request`: a URL plus two closures — one that builds the `URLRequest`, one that decodes
/// the `Output`. Both own their coding (a `JSONEncoder`/`JSONDecoder` or `QueryItemEncoder` created
/// inside the closure), so the request stays `Sendable` without storing a non-`Sendable` coder.
public struct BasicRequest<Input: Sendable, Response: Decodable & Sendable>: Request {

    private let url: URL

    private let build: @Sendable (_ url: URL, _ input: Input, _ token: String?) throws -> URLRequest

    private let decode: @Sendable (_ data: Data) throws -> Response

    public init(
        url: URL,
        build: @escaping @Sendable (_ url: URL, _ input: Input, _ token: String?) throws -> URLRequest,
        decode: @escaping @Sendable (_ data: Data) throws -> Response = { try JSONDecoder.tmbr().decode(Response.self, from: $0) }
    ) {
        self.url = url
        self.build = build
        self.decode = decode
    }

    public func makeRequest(from input: Input, token: String?) throws -> URLRequest {
        try build(url, input, token)
    }

    public func parseResponse(_ data: Data) throws -> Response {
        try decode(data)
    }
}

// MARK: - No-body factories

public extension BasicRequest where Input == Void {

    static func get(baseURL: URL, path: String) -> Self {
        BasicRequest(url: baseURL.appending(path: path)) { url, _, token in
            var req = URLRequest(url: url)
            req.httpMethod = HTTPMethod.get.rawValue
            if let token { req.addHeader(.authorization.bearer(token)) }
            return req
        }
    }

    static func delete(baseURL: URL, path: String) -> Self {
        BasicRequest(url: baseURL.appending(path: path)) { url, _, token in
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
        body(baseURL: baseURL, path: path, method: .post)
    }

    static func put(baseURL: URL, path: String) -> Self {
        body(baseURL: baseURL, path: path, method: .put)
    }

    static func patch(baseURL: URL, path: String) -> Self {
        body(baseURL: baseURL, path: path, method: .patch)
    }

    static func query(baseURL: URL, path: String) -> Self {
        BasicRequest(url: baseURL.appending(path: path)) { url, params, token in
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

    private static func body(baseURL: URL, path: String, method: HTTPMethod) -> Self {
        BasicRequest(url: baseURL.appending(path: path)) { url, body, token in
            var req = URLRequest(url: url)
            req.httpMethod = method.rawValue
            req.addHeader(.contentType.json)
            req.httpBody = try JSONEncoder().encode(body)
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
