import Foundation
import ApiKit
import TmbrCore

struct AppleSignInRequest: Request {
    struct Input: Sendable {
        let identityToken: String
        let authCode: String
        let nonce: String
        let userPayload: String?
    }

    typealias Response = AuthResponse

    private let baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func makeRequest(from input: Input, token _: String?, using encoder: JSONEncoder) throws -> URLRequest {
        struct Body: Encodable {
            let code: String
            let id_token: String
            let nonce: String
            let user: String?
        }
        var req = URLRequest(url: baseURL.appending(path: "/api/apple/auth"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(Body(
            code: input.authCode,
            id_token: input.identityToken,
            nonce: input.nonce,
            user: input.userPayload
        ))
        return req
    }
}
