import Foundation

/// A single typed endpoint: how to turn an `Input` into a `URLRequest`, and how to decode its `Output`.
///
/// A request owns its own encoding/decoding — the loader is coding-agnostic. Conformers bake whatever
/// `JSONEncoder`/`JSONDecoder` (or query encoder) they need into `makeRequest`/`parseResponse`.
public protocol Request: Sendable {

    associatedtype Input: Sendable

    associatedtype Response: Decodable & Sendable

    func makeRequest(from input: Input, token: String?) throws -> URLRequest

    func parseResponse(_ data: Data) throws -> Response
}

public extension Request {

    func makeRequest(from input: Input) throws -> URLRequest {
        try makeRequest(from: input, token: nil)
    }
}

public extension Request where Input == Void {

    func makeRequest(token: String? = nil) throws -> URLRequest {
        try makeRequest(from: (), token: token)
    }
}
