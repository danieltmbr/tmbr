import Foundation

public final class RequestLoader<R: Request>: Sendable {
    private let request: R
    private let session: URLSession
    private let auth: AuthToken?
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        request: R,
        session: URLSession = .shared,
        auth: AuthToken? = nil,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.request = request
        self.session = session
        self.auth = auth
        self.decoder = decoder
        self.encoder = encoder
    }

    public func load(from input: R.Input) async throws -> R.Response {
        let token = await auth?.value
        var urlRequest = try request.makeRequest(from: input, encoder: encoder)
        if let token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
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
