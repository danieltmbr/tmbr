import Foundation

public protocol Request: Sendable {
    associatedtype Input: Sendable
    associatedtype Response: Decodable & Sendable

    func makeRequest(from input: Input, encoder: JSONEncoder) throws -> URLRequest
    func parseResponse(_ data: Data, using decoder: JSONDecoder) throws -> Response
}

public extension Request {
    func parseResponse(_ data: Data, using decoder: JSONDecoder = JSONDecoder()) throws -> Response {
        try decoder.decode(Response.self, from: data)
    }
}
