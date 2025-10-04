import Foundation
import Vapor

public struct Page<Model: Encodable & Sendable>: Sendable, AsyncResponseEncodable {
    
    public typealias Renderer = @Sendable (Request) async throws -> View
    
    private let render: Renderer
    
    private let response: @Sendable (Request, Renderer) async throws -> AsyncResponseEncodable
    
    public init(
        render: @Sendable @escaping (Request) async throws -> View,
        response: @Sendable @escaping (Request, Renderer) async throws -> AsyncResponseEncodable
    ) {
        self.render = render
        self.response = response
    }
    
    public init(render: @Sendable @escaping (Request) async throws -> View) {
        self.init(
            render: render,
            response: { request, renderer in
                try await render(request)
            }
        )
    }
    
    public init(
        template: Template<Model>,
        parse: @Sendable @escaping (Request) async throws -> Model
    ) {
        self.init { request in
            try await template.render(parse(request), with: request.view)
        }
    }
    
    public init(
        template: Template<Model>,
        parse: @Sendable @escaping (Request) async throws -> Model,
        configure: @Sendable @escaping (Request, Renderer) async throws -> AsyncResponseEncodable
    ) {
        self.init(
            render: { request in
                try await template.render(parse(request), with: request.view)
            },
            response: configure
        )
    }
    
    @Sendable
    public func render(on req: Request) async throws -> View {
        try await render(req)
    }
    
    public func encodeResponse(for request: Request) async throws -> Response {
        try await response(request, render).encodeResponse(for: request)
    }
}

extension Page where Model == Never {
    @inlinable
    public init(template: Template<Never>) {
        self.init { request in
            try await template.render(with: request.view)
        }
    }
}
