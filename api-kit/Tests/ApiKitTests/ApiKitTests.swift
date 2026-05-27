import Testing
import Foundation
@testable import ApiKit

// MARK: - MockURLProtocol

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

// MARK: - Shared fixtures

private let base = URL(string: "https://test.example.com")!
private struct Echo: Codable, Sendable { let value: String }

private func ok(_ req: URLRequest, body: String) -> (HTTPURLResponse, Data) {
    (HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data(body.utf8))
}

private func response(_ req: URLRequest, status: Int) -> (HTTPURLResponse, Data) {
    (HTTPURLResponse(url: req.url!, statusCode: status, httpVersion: nil, headerFields: nil)!, Data())
}

// MARK: - BasicRequest (no body)

@Suite("BasicRequest — no body")
struct BasicRequestNoBodyTests {
    @Test func getBuildsURL() throws {
        let req = BasicRequest<Void, Echo>.get(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: (), token: nil, using: JSONEncoder())
        #expect(urlRequest.url?.absoluteString == "https://test.example.com/api/things")
        #expect(urlRequest.httpMethod == "GET")
        #expect(urlRequest.httpBody == nil)
    }

    @Test func getOmitsAuthHeaderWhenTokenNil() throws {
        let req = BasicRequest<Void, Echo>.get(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: (), token: nil, using: JSONEncoder())
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func getAttachesAuthHeaderWhenTokenPresent() throws {
        let req = BasicRequest<Void, Echo>.get(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: (), token: "abc123", using: JSONEncoder())
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer abc123")
    }

    @Test func deleteBuildsURL() throws {
        let req = BasicRequest<Void, Echo>.delete(baseURL: base, path: "/api/things/1")
        let urlRequest = try req.makeRequest(from: (), token: nil, using: JSONEncoder())
        #expect(urlRequest.url?.absoluteString == "https://test.example.com/api/things/1")
        #expect(urlRequest.httpMethod == "DELETE")
    }

    @Test func parsesResponse() throws {
        let req = BasicRequest<Void, Echo>.get(baseURL: base, path: "/api/things")
        let result = try req.parseResponse(Data(#"{"value":"hello"}"#.utf8))
        #expect(result.value == "hello")
    }
}

// MARK: - BasicRequest (JSON body)

@Suite("BasicRequest — JSON body")
struct BasicRequestBodyTests {
    private struct Payload: Codable, Sendable { let name: String }

    @Test func postBuildsURLAndMethod() throws {
        let req = BasicRequest<Payload, Echo>.post(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: Payload(name: "x"), token: nil, using: JSONEncoder())
        #expect(urlRequest.url?.absoluteString == "https://test.example.com/api/things")
        #expect(urlRequest.httpMethod == "POST")
    }

    @Test func postEncodesBodyAsJSON() throws {
        let req = BasicRequest<Payload, Echo>.post(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: Payload(name: "hello"), token: nil, using: JSONEncoder())
        let decoded = try JSONDecoder().decode(Payload.self, from: urlRequest.httpBody!)
        #expect(decoded.name == "hello")
    }

    @Test func postSetsContentTypeHeader() throws {
        let req = BasicRequest<Payload, Echo>.post(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: Payload(name: "x"), token: nil, using: JSONEncoder())
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func putUsesCorrectMethod() throws {
        let req = BasicRequest<Payload, Echo>.put(baseURL: base, path: "/api/things/1")
        let urlRequest = try req.makeRequest(from: Payload(name: "x"), token: nil, using: JSONEncoder())
        #expect(urlRequest.httpMethod == "PUT")
    }

    @Test func patchUsesCorrectMethod() throws {
        let req = BasicRequest<Payload, Echo>.patch(baseURL: base, path: "/api/things/1")
        let urlRequest = try req.makeRequest(from: Payload(name: "x"), token: nil, using: JSONEncoder())
        #expect(urlRequest.httpMethod == "PATCH")
    }

    @Test func bodyOmitsAuthHeaderWhenTokenNil() throws {
        let req = BasicRequest<Payload, Echo>.post(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: Payload(name: "x"), token: nil, using: JSONEncoder())
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func bodyAttachesAuthHeaderWhenTokenPresent() throws {
        let req = BasicRequest<Payload, Echo>.post(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: Payload(name: "x"), token: "tok", using: JSONEncoder())
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer tok")
    }
}

// MARK: - BasicRequest (query parameters)

@Suite("BasicRequest — query parameters")
struct BasicRequestQueryTests {
    private struct SearchParams: Encodable, Sendable {
        let q: String
        let page: Int
    }

    @Test func encodesQueryParams() throws {
        let req = BasicRequest<SearchParams, Echo>.query(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: SearchParams(q: "hello", page: 2), token: nil, using: JSONEncoder())
        let components = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "q", value: "hello")))
        #expect(items.contains(URLQueryItem(name: "page", value: "2")))
    }

    @Test func queryUsesGetMethod() throws {
        let req = BasicRequest<SearchParams, Echo>.query(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: SearchParams(q: "x", page: 1), token: nil, using: JSONEncoder())
        #expect(urlRequest.httpMethod == "GET")
    }

    @Test func queryHasNoBody() throws {
        let req = BasicRequest<SearchParams, Echo>.query(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: SearchParams(q: "x", page: 1), token: nil, using: JSONEncoder())
        #expect(urlRequest.httpBody == nil)
    }

    @Test func queryAttachesAuthHeaderWhenTokenPresent() throws {
        let req = BasicRequest<SearchParams, Echo>.query(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: SearchParams(q: "x", page: 1), token: "tok", using: JSONEncoder())
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer tok")
    }
}

// MARK: - QueryItemEncoder

@Suite("QueryItemEncoder")
struct QueryItemEncoderTests {
    private struct Flat: Encodable {
        let name: String
        let count: Int
        let flag: Bool
    }

    private struct WithArray: Encodable {
        let tags: [String]
    }

    @Test func encodesFlatStruct() throws {
        let items = try QueryItemEncoder().encode(Flat(name: "hello", count: 3, flag: true))
        #expect(items.contains(URLQueryItem(name: "name", value: "hello")))
        #expect(items.contains(URLQueryItem(name: "count", value: "3")))
        #expect(items.contains(URLQueryItem(name: "flag", value: "true")))
    }

    @Test func encodesArrayWithRepeatedKey() throws {
        let items = try QueryItemEncoder().encode(WithArray(tags: ["a", "b", "c"]))
        let tagItems = items.filter { $0.name == "tags" }
        #expect(tagItems.count == 3)
        #expect(tagItems.map(\.value) == ["a", "b", "c"])
    }

    @Test func encodesBoolFalse() throws {
        let items = try QueryItemEncoder().encode(Flat(name: "x", count: 0, flag: false))
        #expect(items.contains(URLQueryItem(name: "flag", value: "false")))
    }
}

// MARK: - RequestLoader
// Serialized because tests share MockURLProtocol.handler static

@Suite("RequestLoader", .serialized)
struct RequestLoaderTests {
    private let session = makeMockSession()

    @Test func makesUnauthenticatedRequest() async throws {
        MockURLProtocol.handler = { req in
            #expect(req.value(forHTTPHeaderField: "Authorization") == nil)
            return ok(req, body: #"{"value":"ok"}"#)
        }
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: base, path: "/api/things"),
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
            request: BasicRequest<Void, Echo>.get(baseURL: base, path: "/api/things"),
            session: session,
            auth: auth
        )
        _ = try await loader.load()
    }

    @Test func picksUpRefreshedToken() async throws {
        let auth = AuthToken(value: "first-token")
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: base, path: "/api/things"),
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
        MockURLProtocol.handler = { req in response(req, status: 401) }
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: base, path: "/api/things"),
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
            return response(req, status: 404)
        }
        let provider = MockTokenProvider(token: "new-token")
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: base, path: "/api/things"),
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
                return response(req, status: 401)
            }
            return ok(req, body: #"{"value":"retried"}"#)
        }
        let auth = AuthToken()
        let provider = MockTokenProvider(token: "fresh-token")
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: base, path: "/api/things"),
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
        MockURLProtocol.handler = { req in response(req, status: 404) }
        let loader = RequestLoader(
            request: BasicRequest<Void, Echo>.get(baseURL: base, path: "/api/things"),
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

// MARK: - MockTokenProvider

private final class MockTokenProvider: TokenProvider, @unchecked Sendable {
    let token: String
    private(set) var fetchCount = 0

    init(token: String) { self.token = token }

    func fetchToken() async throws -> String {
        fetchCount += 1
        return token
    }
}

// MARK: - AuthToken

@Suite("AuthToken")
struct AuthTokenTests {
    @Test func startsNil() async {
        #expect(await AuthToken().value == nil)
    }

    @Test func storesInitialValue() async {
        #expect(await AuthToken(value: "tok").value == "tok")
    }

    @Test func updatesValue() async {
        let token = AuthToken(value: "old")
        await token.set("new")
        #expect(await token.value == "new")
    }

    @Test func clearsValue() async {
        let token = AuthToken(value: "something")
        await token.set(nil)
        #expect(await token.value == nil)
    }
}
