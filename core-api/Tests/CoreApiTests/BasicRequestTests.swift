import Testing
import Foundation
@testable import CoreApi

@Suite("BasicRequest — no body")
struct BasicRequestNoBodyTests {
    @Test func getBuildsURL() throws {
        let req = BasicRequest<Void, Echo>.get(baseURL: testBase, path: "/api/things")
        let urlRequest = try req.makeRequest(from: (), token: nil)
        #expect(urlRequest.url?.absoluteString == "https://test.example.com/api/things")
        #expect(urlRequest.httpMethod == "GET")
        #expect(urlRequest.httpBody == nil)
    }

    @Test func getOmitsAuthHeaderWhenTokenNil() throws {
        let req = BasicRequest<Void, Echo>.get(baseURL: testBase, path: "/api/things")
        let urlRequest = try req.makeRequest(from: (), token: nil)
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func getAttachesAuthHeaderWhenTokenPresent() throws {
        let req = BasicRequest<Void, Echo>.get(baseURL: testBase, path: "/api/things")
        let urlRequest = try req.makeRequest(from: (), token: "abc123")
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer abc123")
    }

    @Test func deleteBuildsURL() throws {
        let req = BasicRequest<Void, Echo>.delete(baseURL: testBase, path: "/api/things/1")
        let urlRequest = try req.makeRequest(from: (), token: nil)
        #expect(urlRequest.url?.absoluteString == "https://test.example.com/api/things/1")
        #expect(urlRequest.httpMethod == "DELETE")
    }

    @Test func parsesResponse() throws {
        let req = BasicRequest<Void, Echo>.get(baseURL: testBase, path: "/api/things")
        let result = try req.parseResponse(Data(#"{"value":"hello"}"#.utf8))
        #expect(result.value == "hello")
    }
}

@Suite("BasicRequest — JSON body")
struct BasicRequestBodyTests {
    private struct Payload: Codable, Sendable { let name: String }

    @Test func postBuildsURLAndMethod() throws {
        let req = BasicRequest<Payload, Echo>.post(baseURL: testBase, path: "/api/things")
        let urlRequest = try req.makeRequest(from: Payload(name: "x"), token: nil)
        #expect(urlRequest.url?.absoluteString == "https://test.example.com/api/things")
        #expect(urlRequest.httpMethod == "POST")
    }

    @Test func postEncodesBodyAsJSON() throws {
        let req = BasicRequest<Payload, Echo>.post(baseURL: testBase, path: "/api/things")
        let urlRequest = try req.makeRequest(from: Payload(name: "hello"), token: nil)
        let decoded = try JSONDecoder().decode(Payload.self, from: urlRequest.httpBody!)
        #expect(decoded.name == "hello")
    }

    @Test func postSetsContentTypeHeader() throws {
        let req = BasicRequest<Payload, Echo>.post(baseURL: testBase, path: "/api/things")
        let urlRequest = try req.makeRequest(from: Payload(name: "x"), token: nil)
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func putUsesCorrectMethod() throws {
        let req = BasicRequest<Payload, Echo>.put(baseURL: testBase, path: "/api/things/1")
        let urlRequest = try req.makeRequest(from: Payload(name: "x"), token: nil)
        #expect(urlRequest.httpMethod == "PUT")
    }

    @Test func patchUsesCorrectMethod() throws {
        let req = BasicRequest<Payload, Echo>.patch(baseURL: testBase, path: "/api/things/1")
        let urlRequest = try req.makeRequest(from: Payload(name: "x"), token: nil)
        #expect(urlRequest.httpMethod == "PATCH")
    }

    @Test func bodyOmitsAuthHeaderWhenTokenNil() throws {
        let req = BasicRequest<Payload, Echo>.post(baseURL: testBase, path: "/api/things")
        let urlRequest = try req.makeRequest(from: Payload(name: "x"), token: nil)
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func bodyAttachesAuthHeaderWhenTokenPresent() throws {
        let req = BasicRequest<Payload, Echo>.post(baseURL: testBase, path: "/api/things")
        let urlRequest = try req.makeRequest(from: Payload(name: "x"), token: "tok")
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer tok")
    }
}

@Suite("BasicRequest — query parameters")
struct BasicRequestQueryTests {
    private struct SearchParams: Encodable, Sendable {
        let q: String
        let page: Int
    }

    @Test func encodesQueryParams() throws {
        let req = BasicRequest<SearchParams, Echo>.query(baseURL: testBase, path: "/api/things")
        let urlRequest = try req.makeRequest(from: SearchParams(q: "hello", page: 2), token: nil)
        let components = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "q", value: "hello")))
        #expect(items.contains(URLQueryItem(name: "page", value: "2")))
    }

    @Test func queryUsesGetMethod() throws {
        let req = BasicRequest<SearchParams, Echo>.query(baseURL: testBase, path: "/api/things")
        let urlRequest = try req.makeRequest(from: SearchParams(q: "x", page: 1), token: nil)
        #expect(urlRequest.httpMethod == "GET")
    }

    @Test func queryHasNoBody() throws {
        let req = BasicRequest<SearchParams, Echo>.query(baseURL: testBase, path: "/api/things")
        let urlRequest = try req.makeRequest(from: SearchParams(q: "x", page: 1), token: nil)
        #expect(urlRequest.httpBody == nil)
    }

    @Test func queryAttachesAuthHeaderWhenTokenPresent() throws {
        let req = BasicRequest<SearchParams, Echo>.query(baseURL: testBase, path: "/api/things")
        let urlRequest = try req.makeRequest(from: SearchParams(q: "x", page: 1), token: "tok")
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer tok")
    }
}
