import CoreApi
import Foundation
import CoreTmbr

typealias AppleSignInRequest = BasicRequest<AppleSignInData, AuthResponse>

extension Request where Self == AppleSignInRequest {
    static func signIn(baseURL: URL) -> Self {
        .post(baseURL: baseURL, path: "/api/apple/auth")
    }
}
