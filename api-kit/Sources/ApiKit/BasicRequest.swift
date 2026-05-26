import Foundation

public struct GetRequest<Response: Decodable & Sendable>: Request {
    public typealias Input = Void

    private let url: URL

    public init(baseURL: URL, path: String) {
        self.url = baseURL.appending(path: path)
    }

    public func makeRequest(from _: Void, encoder: JSONEncoder) throws -> URLRequest {
        URLRequest(url: url)
    }
}

public struct BodyRequest<Body: Encodable & Sendable, Response: Decodable & Sendable>: Request {
    public typealias Input = Body

    private let url: URL
    private let method: String

    public init(baseURL: URL, path: String, method: String = "POST") {
        self.url = baseURL.appending(path: path)
        self.method = method
    }

    public func makeRequest(from body: Body, encoder: JSONEncoder) throws -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(body)
        return req
    }
}
