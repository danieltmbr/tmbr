import Foundation

public struct GetRequest<Response: Decodable & Sendable>: Request {
    public typealias Input = Void

    private let url: URL

    public init(baseURL: URL, path: String) {
        self.url = baseURL.appending(path: path)
    }

    public func makeRequest(from _: Void, using encoder: JSONEncoder) throws -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = HTTPMethod.get.rawValue
        return req
    }
}

public struct BodyRequest<Body: Encodable & Sendable, Response: Decodable & Sendable>: Request {
    public typealias Input = Body

    private let url: URL

    private let method: HTTPMethod

    public init(
        baseURL: URL,
        path: String,
        method: HTTPMethod = .post
    ) {
        self.url = baseURL.appending(path: path)
        self.method = method
    }

    public func makeRequest(from body: Body, using encoder: JSONEncoder) throws -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.addHeader(.contentType.json)
        req.httpBody = try encoder.encode(body)
        return req
    }
}
