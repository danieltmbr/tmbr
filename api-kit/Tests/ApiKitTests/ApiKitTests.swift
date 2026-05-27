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

// MARK: - GetRequest

@Suite("GetRequest")
struct GetRequestTests {
    @Test func buildsURL() throws {
        let req = GetRequest<Echo>(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: (), using: JSONEncoder())
        #expect(urlRequest.url?.absoluteString == "https://test.example.com/api/things")
        #expect(urlRequest.httpMethod == "GET")
        #expect(urlRequest.httpBody == nil)
    }

    @Test func parsesResponse() throws {
        let req = GetRequest<Echo>(baseURL: base, path: "/api/things")
        let result = try req.parseResponse(Data(#"{"value":"hello"}"#.utf8))
        #expect(result.value == "hello")
    }
}

// MARK: - BodyRequest

@Suite("BodyRequest")
struct BodyRequestTests {
    private struct Payload: Codable, Sendable { let name: String }

    @Test func buildsURLAndMethod() throws {
        let req = BodyRequest<Payload, Echo>(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: Payload(name: "x"), using: JSONEncoder())
        #expect(urlRequest.url?.absoluteString == "https://test.example.com/api/things")
        #expect(urlRequest.httpMethod == "POST")
    }

    @Test func encodesBodyAsJSON() throws {
        let req = BodyRequest<Payload, Echo>(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: Payload(name: "hello"), using: JSONEncoder())
        let decoded = try JSONDecoder().decode(Payload.self, from: urlRequest.httpBody!)
        #expect(decoded.name == "hello")
    }

    @Test func setsContentTypeHeader() throws {
        let req = BodyRequest<Payload, Echo>(baseURL: base, path: "/api/things")
        let urlRequest = try req.makeRequest(from: Payload(name: "x"), using: JSONEncoder())
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func respectsCustomMethod() throws {
        let req = BodyRequest<Payload, Echo>(baseURL: base, path: "/api/things", method: .put)
        let urlRequest = try req.makeRequest(from: Payload(name: "x"), using: JSONEncoder())
        #expect(urlRequest.httpMethod == "PUT")
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
            request: GetRequest<Echo>(baseURL: base, path: "/api/things"),
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
            request: GetRequest<Echo>(baseURL: base, path: "/api/things"),
            session: session,
            auth: auth
        )
        _ = try await loader.load()
    }

    @Test func picksUpRefreshedToken() async throws {
        let auth = AuthToken(value: "first-token")
        let loader = RequestLoader(
            request: GetRequest<Echo>(baseURL: base, path: "/api/things"),
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

    @Test func throwsRequestErrorOnHTTPFailure() async throws {
        MockURLProtocol.handler = { req in
            (HTTPURLResponse(url: req.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!, Data())
        }
        let loader = RequestLoader(
            request: GetRequest<Echo>(baseURL: base, path: "/api/things"),
            session: session
        )
        await #expect(throws: RequestError.self) {
            _ = try await loader.load()
        }
    }

    @Test func includesStatusCodeInError() async throws {
        MockURLProtocol.handler = { req in
            (HTTPURLResponse(url: req.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!, Data())
        }
        let loader = RequestLoader(
            request: GetRequest<Echo>(baseURL: base, path: "/api/things"),
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
