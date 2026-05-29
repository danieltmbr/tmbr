# Native App — Networking Architecture

## Inspiration

WWDC 2018 "Testing Tips & Tricks" (Session 417). The key pattern:

```
Prepare URLRequest → Create URLSession Task → Parse Response → Update View
```

Split into two independently testable responsibilities on a plain struct:
- `makeRequest(from:)` — builds the `URLRequest`
- `parseResponse(_:using:)` — decodes the `Data`

The `RequestLoader` class wraps the struct + a `URLSession` and executes the call. The session is injectable, which enables testing via `MockURLProtocol` without hitting the network.

---

## The Core Pattern: Loader-Per-Endpoint

We committed to a single pattern: **each endpoint is a typed `RequestLoader<R>`**, created once (usually in a view model or feature container), reused across multiple calls with different inputs.

```swift
// The loader knows HOW to reach one endpoint
let songLoader = RequestLoader(request: GetSongRequest(baseURL: base), session: session, auth: auth)

// The caller provides WHAT to fetch each time
let song1 = try await songLoader.load(from: 42)
let song2 = try await songLoader.load(from: 99)  // same loader, new input
```

This separates "what can I fetch" (the loader type, stored as a dependency) from "what specifically" (the input, provided at call time).

### Why not a generic `client.send(request)` pattern?

We considered a generic `APIClient` that accepts any request value with parameters bundled in:

```swift
// Alternative: input bundled into the request struct
client.send(GetSongRequest(id: 42))
client.send(GetSongRequest(id: 99))   // new request object each time
```

Trade-offs of the generic client approach:
- Simpler for one-off commands (sign in, create post)
- The client handles all endpoints — less to inject
- BUT: a component that only needs songs still gets access to everything
- BUT: `GetSongRequest(id:)` creates a new value each call; the "reusable loader" concept is lost
- BUT: two similar patterns in the same codebase creates "which do I use?" friction

**Decision**: Commit to loader-per-endpoint only. For one-off commands (auth, create), you still create a typed loader — you just call it once and let it go out of scope. The ceremony is minimal and the pattern stays consistent.

---

## The Two Structural Shapes Compared

The fundamental difference from a generic client is where the endpoint-specific input lives:

| | Loader-per-endpoint (our approach) | Generic client |
|---|---|---|
| **Input to `makeRequest`** | Associated type, passed at call time | Stored in the request struct's init |
| **Loader is reusable** | Yes — same loader, different inputs | No — new request value per call |
| **Dependency injection** | Inject exact capability: `RequestLoader<SearchSongsRequest>` | Inject everything: `APIClient` |
| **Type-visible contract** | A component holding `RequestLoader<GetSongRequest>` can only fetch songs | `APIClient` gives access to all endpoints |
| **One-off commands** | Slightly ceremonious — create loader, call once, discard | Natural — bundle params in request struct |
| **Repeated calls with different inputs** | Natural — `loader.load(from: query)` as user types | Awkward — new struct per keystroke |
| **Testing a component** | Inject mock loader (mock one `load(from:)`) | Inject mock client backed by `MockURLProtocol` |

For tmbr's planned features (browse catalogue, search, MusicKit now-playing sync, share extension), the loader pattern dominates. Auth and write commands are less frequent and the slight ceremony is worth the consistency.

---

## Types

### `Request` protocol — the pure descriptor

Lives in `ApiKit` package. Implemented by endpoint-specific structs in feature modules.

```swift
public protocol Request: Sendable {
    associatedtype Input: Sendable
    associatedtype Response: Decodable & Sendable

    func makeRequest(from input: Input, encoder: JSONEncoder) throws -> URLRequest
    func parseResponse(_ data: Data, using decoder: JSONDecoder) throws -> Response
}
```

**Design notes:**
- `Input` is an associated type. It is the endpoint-specific parameter (a `SongID`, a search query struct, a `Void` for parameterless GETs). It is NOT stored in the request struct — it arrives at call time via `makeRequest(from:)`.
- `baseURL` is stored in the request struct at init. The struct is environment-aware; it doesn't need to receive the base URL at call time.
- Both methods are **synchronous**. `makeRequest` is pure computation. `parseResponse` is JSON decoding — fast, sync, and can be unit-tested without `await`. The async boundary is the network call in `RequestLoader.load(from:)`.
- Default parameter values allow direct calls in tests without ceremony:

```swift
// Default parseResponse — no override needed for standard JSON
public extension Request {
    func parseResponse(_ data: Data, using decoder: JSONDecoder = JSONDecoder()) throws -> Response {
        try decoder.decode(Response.self, from: data)
    }
}
```

- The encoder default is on `RequestLoader.load(from:)`, not on `makeRequest`. Requests that need an encoder receive the loader's shared instance; test code can call `makeRequest(from:encoder:)` with `JSONEncoder()` directly.

### `RequestLoader<R: Request>` — the ephemeral executor

Lives in `ApiKit`.

```swift
public final class RequestLoader<R: Request>: Sendable {
    private let request: R
    private let session: URLSession     // injectable for testing
    private let auth: AuthToken?        // nil for unauthenticated endpoints
    private let decoder: JSONDecoder    // shared, configured once
    private let encoder: JSONEncoder    // shared, configured once

    public init(
        request: R,
        session: URLSession = .shared,
        auth: AuthToken? = nil,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    )

    public func load(from input: R.Input) async throws -> R.Response
}

extension RequestLoader where R.Input == Void {
    public func load() async throws -> R.Response { try await load(from: ()) }
}
```

**Design notes:**
- `final class` (not actor, not struct). Immutable after init — all stored properties are `let`. `Sendable` by analysis: `URLSession`, `JSONDecoder`, `JSONEncoder` are `@unchecked Sendable`; `AuthToken` is an actor. No mutable state on the loader itself.
- `auth: AuthToken?` is read inside `load(from:)` at call time, not at init. This means a long-lived loader stored in a view model picks up the current token on every call — including after a token refresh.
- `session` is injectable: swap in `URLSession(configuration: .ephemeral)` with `MockURLProtocol` registered to intercept requests in tests.
- The loader is "ephemeral" in the WWDC sense: created once for an endpoint, reused for many inputs, discarded when the owning component is deallocated.

**`load(from:)` execution:**
```
1. await auth?.value                    — brief actor hop, gets current token
2. request.makeRequest(from:encoder:)   — sync, builds URLRequest
3. inject Authorization header if token — sync
4. session.data(for:)                   — async, suspends here; other loaders run concurrently
5. validate HTTP status                 — sync
6. request.parseResponse(_:using:)      — sync, decodes JSON
```

Steps 4–6 run on the Swift cooperative thread pool. Multiple loaders call them fully concurrently — no serialisation.

### `AuthToken` actor — mutable auth state

Lives in `ApiKit`.

```swift
public actor AuthToken {
    public private(set) var value: String?

    public init(value: String? = nil) { self.value = value }

    public func set(_ value: String?) { self.value = value }
}
```

One `AuthToken` instance per app session, created at app startup. Injected into loaders that need auth. Loaders hold a reference; they don't copy the token at init time — they read it at each `load(from:)` call.

### `APIConfig` — app-level execution context

Lives in `tmbr-app` (not in `ApiKit` — it's app-specific wiring).

```swift
struct APIConfig: Sendable {
    let baseURL: URL
    let session: URLSession
    let auth: AuthToken

    func loader<R: Request>(for request: R) -> RequestLoader<R> {
        RequestLoader(request: request, session: session, auth: auth)
    }
}
```

`APIConfig` is passed to features at construction time. Features use it to create their typed loaders. The config itself is a lightweight `Sendable` value — passing it around is safe across actor boundaries.

---

## Endpoint Types

Endpoint request structs live in feature modules, not in `ApiKit`. `ApiKit` is general-purpose infrastructure.

**Anatomy of an endpoint:**

```swift
// In tmbr-app or a feature module
struct GetSongRequest: Request {
    typealias Input = SongID
    typealias Response = SongResponse

    private let baseURL: URL

    init(baseURL: URL) { self.baseURL = baseURL }

    func makeRequest(from id: SongID, encoder: JSONEncoder) throws -> URLRequest {
        URLRequest(url: baseURL.appending(path: "/api/songs/\(id)"))
    }
    // parseResponse uses the default
}
```

**For POST endpoints with a body:**

```swift
struct CreateNoteRequest: Request {
    struct Input: Encodable, Sendable {
        let body: String
        let access: Access
        let attachmentID: Int
    }
    typealias Response = NoteResponse

    private let baseURL: URL
    init(baseURL: URL) { self.baseURL = baseURL }

    func makeRequest(from input: Input, encoder: JSONEncoder) throws -> URLRequest {
        var req = URLRequest(url: baseURL.appending(path: "/api/notes"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(input)
        return req
    }
}
```

**Ergonomic static factories (instead of namespace enums):**

```swift
extension GetSongRequest {
    static func make(baseURL: URL) -> Self { Self(baseURL: baseURL) }
}

// Call site in a view model init:
songLoader = config.loader(for: .make(baseURL: config.baseURL))
```

---

## `BasicRequest` Convenience Types (in ApiKit)

For endpoints that don't have unusual encoding or decoding needs, `ApiKit` provides concrete generic types:

```swift
// GET endpoint, no body
public struct GetRequest<Response: Decodable & Sendable>: Request {
    public typealias Input = Void
    private let url: URL

    public init(baseURL: URL, path: String) {
        self.url = baseURL.appending(path: path)
    }

    public func makeRequest(from _: Void, encoder: JSONEncoder) throws -> URLRequest {
        URLRequest(url: url)
    }
}

// POST/PUT endpoint with an Encodable body
public struct BodyRequest<Body: Encodable & Sendable, Response: Decodable & Sendable>: Request {
    public typealias Input = Body
    private let url: URL
    private let method: String

    public init(baseURL: URL, path: String, method: String = "POST") {
        self.url = baseURL.appending(path: path)
        self.method = method
    }

    public func makeRequest(from body: Body, encoder: JSONEncoder) throws -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(body)
        return req
    }
}
```

Use `BasicRequest` types for endpoints with standard JSON in/out and no quirks. Use custom request structs for endpoints with non-standard keys (like `id_token`), custom status code handling, or complex URL building.

---

## Testing

**Unit test — `makeRequest` in isolation (sync, no network):**

```swift
@Test func getsSongBuildssCorrectURL() throws {
    let req = GetSongRequest(baseURL: URL(string: "https://x.com")!)
    let urlRequest = try req.makeRequest(from: 42, encoder: JSONEncoder())
    #expect(urlRequest.url?.path == "/api/songs/42")
    #expect(urlRequest.httpMethod == "GET")
}
```

**Unit test — `parseResponse` in isolation (sync, no network):**

```swift
@Test func parsesSongResponse() throws {
    let json = #"{"id":1,"title":"Blue in Green",...}"#.data(using: .utf8)!
    let req = GetSongRequest(baseURL: URL(string: "https://x.com")!)
    let song = try req.parseResponse(json, using: JSONDecoder())
    #expect(song.title == "Blue in Green")
}
```

**Integration test — `RequestLoader` with `MockURLProtocol`:**

```swift
final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let handler = Self.handler else { return }
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

@Test func loaderInjectsTokenOnEveryCall() async throws {
    let auth = AuthToken()
    let loader = RequestLoader(
        request: GetSongRequest(baseURL: URL(string: "https://x.com")!),
        session: makeMockSession(),
        auth: auth
    )

    await auth.set("first-token")
    MockURLProtocol.handler = { req in
        #expect(req.value(forHTTPHeaderField: "Authorization") == "Bearer first-token")
        return (HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data())
    }

    await auth.set("refreshed-token")
    MockURLProtocol.handler = { req in
        #expect(req.value(forHTTPHeaderField: "Authorization") == "Bearer refreshed-token")
        return (HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data())
    }
}
```

---

## Package Layout

```
tmbr/
└── api-kit/
    ├── Package.swift                  ← swiftLanguageModes: [.v6]; no external deps (no TmbrCore dep needed)
    └── Sources/ApiKit/
        ├── Request.swift
        ├── RequestLoader.swift
        ├── AuthToken.swift
        ├── RequestError.swift
        └── BasicRequest.swift
```

`ApiKit` has no dependency on `TmbrCore`. Response types (`SongResponse`, `AuthResponse`, etc.) are imported by the endpoint structs in the feature modules that use them.

---

## What's Out of Scope (Explicit)

These were considered and deferred until there is a concrete need:

- **Retry / back-off** — add a `RetryingRequestLoader<R>` decorator when the first retry scenario appears
- **Logging** — add a `LoggingRequest<R>` wrapper when debugging warrants it (not upfront)
- **Pagination** — add a `PaginatedLoader<R>` or cursor-based request protocol when the first paginated endpoint appears
- **Multipart upload** — gallery upload is web-only for now
- **Request cancellation API** — SwiftUI `.task { }` and structured concurrency handle this; no additional surface needed
- **Rate limiting** — the backend has none
- **Certificate pinning** — not a current requirement
