import Foundation
import ApiKit

struct APIConfig: Sendable {
    let baseURL: URL
    let session: URLSession
    let auth: AuthToken

    func loader<R: Request>(for request: R) -> RequestLoader<R> {
        RequestLoader(request: request, session: session, auth: auth)
    }
}

extension APIConfig {
    static func fromInfoPlist(session: URLSession = .shared) -> APIConfig {
        let raw = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String ?? ""
        guard let url = URL(string: raw), !raw.isEmpty else {
            fatalError("APIBaseURL missing or invalid in Info.plist — check the API_BASE_URL build setting")
        }
        return APIConfig(baseURL: url, session: session, auth: AuthToken())
    }
}
