import Testing
import Foundation
@testable import ApiKit

private final class MockTokenProvider: TokenProvider, @unchecked Sendable {
    let token: String
    private(set) var fetchCount = 0

    init(token: String) { self.token = token }

    func fetchToken() async throws -> String {
        fetchCount += 1
        return token
    }
}

@Suite("RequestLoader", .serialized)
struct RequestLoaderTests {
    private let session = makeMockSession()

    @Test func makesUnauthenticatedRequest() async throws {
        MockURLProtocol.handler = { req in
            #expect(req.value(forHTTPHeaderField: "Authorization") == nil)
            return ok(req, body: #"{"value":"ok"}"#)
        }
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: testBase, path: "/api/things"),
            session: session
        )
        let result = try await loader.load()
        #expect(result.value == "ok")
    }

    @Test func injectsAuthToken() async throws {
        let auth = AuthToken(value: "my-token")
        MockURLProtocol.handler = { req in
            #expect(req.value(forHTTPHeaderField: "Authorization") == "Bearer my-token")
            return ok(req, body: #"{"value":"ok"}"#)
        }
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: testBase, path: "/api/things"),
            session: session,
            auth: auth
        )
        _ = try await loader.load()
    }

    @Test func picksUpRefreshedToken() async throws {
        let auth = AuthToken(value: "first-token")
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: testBase, path: "/api/things"),
            session: session,
            auth: auth
        )

        MockURLProtocol.handler = { req in
            #expect(req.value(forHTTPHeaderField: "Authorization") == "Bearer first-token")
            return ok(req, body: #"{"value":"ok"}"#)
        }
        _ = try await loader.load()

        await auth.set("refreshed-token")
        MockURLProtocol.handler = { req in
            #expect(req.value(forHTTPHeaderField: "Authorization") == "Bearer refreshed-token")
            return ok(req, body: #"{"value":"ok"}"#)
        }
        _ = try await loader.load()
    }

    @Test func propagates401WithoutTokenProvider() async throws {
        MockURLProtocol.handler = { req in httpResponse(req, status: 401) }
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: testBase, path: "/api/things"),
            session: session
        )
        await #expect(throws: RequestError.self) {
            _ = try await loader.load()
        }
    }

    @Test func propagates404EvenWithTokenProvider() async throws {
        var callCount = 0
        MockURLProtocol.handler = { req in
            callCount += 1
            return httpResponse(req, status: 404)
        }
        let provider = MockTokenProvider(token: "new-token")
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: testBase, path: "/api/things"),
            session: session,
            tokenProvider: provider
        )
        do {
            _ = try await loader.load()
            Issue.record("Expected error to be thrown")
        } catch let error as RequestError {
            guard case .httpError(let statusCode, _) = error else {
                Issue.record("Wrong RequestError case: \(error)")
                return
            }
            #expect(statusCode == 404)
        }
        #expect(callCount == 1)
        #expect(provider.fetchCount == 0)
    }

    @Test func retries401OnceWithTokenProvider() async throws {
        var callCount = 0
        MockURLProtocol.handler = { req in
            callCount += 1
            if callCount == 1 {
                return httpResponse(req, status: 401)
            }
            return ok(req, body: #"{"value":"retried"}"#)
        }
        let auth = AuthToken()
        let provider = MockTokenProvider(token: "fresh-token")
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: testBase, path: "/api/things"),
            session: session,
            auth: auth,
            tokenProvider: provider
        )
        let result = try await loader.load()
        #expect(result.value == "retried")
        #expect(callCount == 2)
        #expect(provider.fetchCount == 1)
        #expect(await auth.value == "fresh-token")
    }

    @Test func includesStatusCodeInError() async throws {
        MockURLProtocol.handler = { req in httpResponse(req, status: 404) }
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: testBase, path: "/api/things"),
            session: session
        )
        do {
            _ = try await loader.load()
            Issue.record("Expected RequestError to be thrown")
        } catch let error as RequestError {
            guard case .httpError(let statusCode, _) = error else {
                Issue.record("Wrong RequestError case: \(error)")
                return
            }
            #expect(statusCode == 404)
        }
    }
}
