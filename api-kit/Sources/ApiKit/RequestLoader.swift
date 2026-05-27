import Foundation

public final class RequestLoader<R: Request>: Sendable {
    private let request: R
    private let session: URLSession
    private let auth: AuthToken?
    private let tokenProvider: (any TokenProvider)?
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        request: R,
        session: URLSession = .shared,
        auth: AuthToken? = nil,
        tokenProvider: (any TokenProvider)? = nil,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.request = request
        self.session = session
        self.auth = auth
        self.tokenProvider = tokenProvider
        self.decoder = decoder
        self.encoder = encoder
    }

    public func load(from input: R.Input) async throws -> R.Response {
        let token = await auth?.value
        let urlRequest = try request.makeRequest(from: input, token: token, using: encoder)
        do {
            return try await execute(urlRequest)
        } catch {
            if let reqError = error as? RequestError,
               case .httpError(let statusCode, _) = reqError,
               statusCode == 401,
               let tokenProvider {
                let fresh = try await tokenProvider.fetchToken()
                await auth?.set(fresh)
                let retryRequest = try request.makeRequest(from: input, token: fresh, using: encoder)
                return try await execute(retryRequest)
            }
            throw error
        }
    }

    private func execute(_ urlRequest: URLRequest) async throws -> R.Response {
        let (data, response) = try await session.data(for: urlRequest)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw RequestError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        return try request.parseResponse(data, using: decoder)
    }
}

extension RequestLoader where R.Input == Void {
    public func load() async throws -> R.Response {
        try await load(from: ())
    }
}
