import Foundation
import OSLog

/// A thin wrapper around a single `load(from:)` closure that turns `Input` into `Response`.
///
/// The loader holds no coding state — a `Request` owns that. Build one from a `Request` with the
/// convenience inits (auth-refreshing or plain), or supply any closure directly for tests/composition.
/// Chain `.logged()` to attach request/response logging at debug level.
public struct RequestLoader<Input: Sendable, Response: Decodable & Sendable>: Sendable {

    private let _load: @Sendable (Input) async throws -> Response

    public init(_ load: @escaping @Sendable (Input) async throws -> Response) {
        self._load = load
    }

    public func load(from input: Input) async throws -> Response {
        try await _load(input)
    }
}

public extension RequestLoader where Input == Void {

    func load() async throws -> Response {
        try await load(from: ())
    }
}

// MARK: - Building from a Request

public extension RequestLoader {

    /// Loads `request` without authentication.
    init<R: Request>(request: R, session: URLSession = .shared) where R.Input == Input, R.Response == Response {
        self.init { input in
            try await Self.send(request, input, token: nil, session: session)
        }
    }

    /// Loads `request` with a bearer token from `auth`, refreshing once on a 401 and retrying.
    init<R: Request>(request: R, session: URLSession = .shared, auth: AuthProvider) where R.Input == Input, R.Response == Response {
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

    private static func send<R: Request>(
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

// MARK: - Logging

public extension RequestLoader {

    /// Returns a loader that logs the outgoing request type and decoded response at `.debug` level.
    func logged(by logger: Logger = .networking) -> RequestLoader<Input, Response> {
        RequestLoader { input in
            logger.debug("→ \(String(describing: Response.self))")
            do {
                let response = try await self.load(from: input)
                logger.debug("← \(String(describing: response))")
                return response
            } catch {
                logger.error("✗ \(String(describing: Response.self)): \(error)")
                throw error
            }
        }
    }
}

public extension Logger {
    static let networking = Logger(subsystem: "me.tmbr", category: "networking")
}
