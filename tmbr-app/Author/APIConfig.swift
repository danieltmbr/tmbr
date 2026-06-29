import Foundation
import AppApi

struct APIConfig: Sendable {

    let baseURL: URL

    let session: URLSession

    func loader<R: Request>(for request: R) -> RequestLoader<R.Input, R.Response> {
        RequestLoader(request: request, session: session)
    }
}

extension APIConfig {
    static func fromInfoPlist(session: URLSession = .shared) -> APIConfig {
        let raw = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String ?? ""
        guard let url = URL(string: raw), !raw.isEmpty else {
            fatalError("APIBaseURL missing or invalid in Info.plist — check the API_BASE_URL build setting")
        }
        return APIConfig(baseURL: url, session: session)
    }
}
