import Foundation

public enum RequestError: Error, LocalizedError {
    case httpError(statusCode: Int, data: Data)

    public var errorDescription: String? {
        switch self {
        case .httpError(let statusCode, let data):
            let body = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
            return "HTTP \(statusCode): \(body)"
        }
    }
}
