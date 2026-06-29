import Foundation
import Vapor

public extension AsyncResponseEncodable where Self: Encodable {
    func encodeResponse(for request: Request) async throws -> Response {
        let response = Response()
        try response.content.encode(self, as: .json)
        return response
    }
}
