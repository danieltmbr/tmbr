import Foundation
import Vapor

public struct Page<Model: Encodable & Sendable>: Sendable {
    
    private let render: @Sendable (Request) async throws -> View

    public init(render: @Sendable @escaping (Request) async throws -> View) {
        self.render = render
    }
    
    public init(
        template: Template<Model>,
        parse: @Sendable @escaping (Request) async throws -> Model
    ) {
        self.init { request in
            try await template.render(parse(request), with: request.view)
        }
    }
    
    @Sendable
    public func render(on req: Request) async throws -> View {
        try await render(req)
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
