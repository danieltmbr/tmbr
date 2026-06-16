import Foundation

public protocol Request: Sendable {

    associatedtype Input: Sendable

    associatedtype Response: Decodable & Sendable

    func makeRequest(from input: Input, token: String?, using encoder: JSONEncoder) throws -> URLRequest

    func parseResponse(_ data: Data, using decoder: JSONDecoder) throws -> Response
}

public extension Request {

    func makeRequest(from input: Input, using encoder: JSONEncoder) throws -> URLRequest {
        try makeRequest(from: input, token: nil, using: encoder)
    }

    func parseResponse(
        _ data: Data,
        using decoder: JSONDecoder = JSONDecoder()
    ) throws -> Response {
        try decoder.decode(Response.self, from: data)
    }
}

public extension Request where Input == Void {

    func makeRequest(
        token: String? = nil,
        using encoder: JSONEncoder = JSONEncoder()
    ) throws -> URLRequest {
        try makeRequest(from: (), token: token, using: encoder)
    }
}
