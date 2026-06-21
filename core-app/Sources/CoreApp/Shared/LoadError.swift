import Foundation

/// Typed failure cause for a background refresh. Carried by `LoadPhase.failed` so views can vary
/// their icon and copy per cause rather than showing a generic error string.
public enum LoadError: Error, Equatable, Sendable {
    case offline
    case server(status: Int?)
    case decoding
    case unknown(String)

    // MARK: - Mapping from raw errors

    /// Maps any error into a typed `LoadError`. An existing `LoadError` passes through unchanged.
    public init(_ error: Error) {
        if let existing = error as? LoadError {
            self = existing
            return
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut,
                 .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
                self = .offline
            default:
                self = .unknown(urlError.localizedDescription)
            }
            return
        }
        if error is DecodingError {
            self = .decoding
            return
        }
        self = .unknown(error.localizedDescription)
    }

    // MARK: - Display

    public var title: String {
        switch self {
        case .offline:  return "No Connection"
        case .server:   return "Server Error"
        case .decoding: return "Couldn't Load"
        case .unknown:  return "Something Went Wrong"
        }
    }

    public var message: String {
        switch self {
        case .offline:
            return "Check your connection and try again."
        case .server(let status):
            if let status { return "The server returned an error (\(status))." }
            return "The server returned an error."
        case .decoding:
            return "The app received unexpected data. Try updating the app."
        case .unknown(let description):
            return description
        }
    }

    public var systemImage: String {
        switch self {
        case .offline:   return "wifi.slash"
        case .server:    return "exclamationmark.triangle"
        case .decoding:  return "exclamationmark.triangle"
        case .unknown:   return "exclamationmark.circle"
        }
    }
}
