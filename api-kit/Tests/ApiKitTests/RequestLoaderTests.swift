import Testing
import Foundation
@testable import ApiKit

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
        let auth = AuthProvider(token: "my-token") { "refreshed" }
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
        let auth = AuthProvider(token: "first-token") { "refreshed" }
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

    @Test func propagates401WithoutAuthProvider() async throws {
        MockURLProtocol.handler = { req in httpResponse(req, status: 401) }
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: testBase, path: "/api/things"),
            session: session
        )
        await #expect(throws: RequestError.self) {
            _ = try await loader.load()
        }
    }

    @Test func propagates404EvenWithAuthProvider() async throws {
        var callCount = 0
        MockURLProtocol.handler = { req in
            callCount += 1
            return httpResponse(req, status: 404)
        }
        let counter = CallCounter()
        let auth = AuthProvider {
            await counter.increment()
            return "new-token"
        }
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: testBase, path: "/api/things"),
            session: session,
            auth: auth
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
        #expect(await counter.count == 0)
    }

    @Test func retries401OnceWithAuthProvider() async throws {
        var callCount = 0
        MockURLProtocol.handler = { req in
            callCount += 1
            if callCount == 1 {
                return httpResponse(req, status: 401)
            }
            return ok(req, body: #"{"value":"retried"}"#)
        }
        let counter = CallCounter()
        let auth = AuthProvider {
            await counter.increment()
            return "fresh-token"
        }
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: testBase, path: "/api/things"),
            session: session,
            auth: auth
        )
        let result = try await loader.load()
        #expect(result.value == "retried")
        #expect(callCount == 2)
        #expect(await counter.count == 1)
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
