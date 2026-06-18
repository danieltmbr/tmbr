import Foundation

/// A thin wrapper around a single `load(from:)` closure that turns a request's `Input` into its `Response`.
///
/// The loader holds no coding state — a `Request` owns that. Build one from a `Request` with the
/// convenience inits below (auth-refreshing or plain), or hand it any closure for tests/composition.
public struct RequestLoader<R: Request>: Sendable {

    private let _load: @Sendable (R.Input) async throws -> R.Response

    public init(_ load: @escaping @Sendable (R.Input) async throws -> R.Response) {
        self._load = load
    }

    public func load(from input: R.Input) async throws -> R.Response {
        try await _load(input)
    }
}

public extension RequestLoader where R.Input == Void {

    func load() async throws -> R.Response {
        try await load(from: ())
    }
}

// MARK: - Building from a Request

public extension RequestLoader {

    /// Loads `request` without authentication.
    init(request: R, session: URLSession = .shared) {
        self.init { input in
            try await Self.send(request, input, token: nil, session: session)
        }
    }

    /// Loads `request` with a bearer token from `auth`, refreshing once on a 401 and retrying.
    init(request: R, session: URLSession = .shared, auth: AuthProvider) {
        self.init { input in
            let token = await auth.value
            do {
                return try await Self.send(request, input, token: token, session: session)
            } catch let error as RequestError {
                guard case .httpError(401, _) = error else { throw error }
                let fresh = try await auth.refreshedToken()
                return try await Self.send(request, input, token: fresh, session: session)
            }
        }
    }

    private static func send(
        _ request: R,
        _ input: R.Input,
        token: String?,
        session: URLSession
    ) async throws -> R.Response {
        let urlRequest = try request.makeRequest(from: input, token: token)
        let (data, response) = try await session.data(for: urlRequest)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw RequestError.httpError(statusCode: http.statusCode, data: data)
        }
        return try request.parseResponse(data)
    }
}
