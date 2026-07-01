import Foundation
import Vapor

public struct Page: Sendable {
    
    public typealias Assembler = @Sendable (Request) async throws -> AsyncResponseEncodable

    private let assembler: Assembler
    
    public init(assembler: @escaping Assembler) {
        self.assembler = assembler
    }
    
    public init<Model: Encodable & Sendable>(
        parser parse: @escaping @Sendable (Request) async throws -> Model,
        renderer render: @escaping @Sendable (Model, ViewRenderer) async throws -> View
    ) {
        self.init { request in
            try await render(parse(request), request.view)
        }
    }
    
    public init<Model: Encodable & Sendable>(
        template: Template<Model>,
        parser: @escaping @Sendable (Request) async throws -> Model
    ) {
        self.init(parser: parser) { model, renderer in
            try await template.render(model, with: renderer)
        }
    }
    
    public init(template: Template<Never>) {
        self.init { request in
            try await template.render(with: request.view)
        }
    }
    
    public func recover(_ recover: Recover) -> Page {
        Page { request in
            do {
                return try await assembler(request)
            } catch {
                return try await recover(error, request)
            }
        }
    }

    /// Adds `Cache-Control: no-store` to the response, preventing bfcache.
    /// Required on all editor pages so that pressing Back triggers a fresh load
    /// and `clearIfPending` can clear the localStorage draft.
    public func noStore() -> Page {
        Page { request in
            let encodable = try await self.assembler(request)
            let response = try await encodable.encodeResponse(for: request)
            response.headers.replaceOrAdd(name: .cacheControl, value: "no-store")
            return response
        }
    }

    func response(for request: Request) async throws -> AsyncResponseEncodable {
        try await assembler(request)
    }
}