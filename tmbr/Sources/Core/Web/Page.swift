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
    
    func response(for request: Request) async throws -> AsyncResponseEncodable {
        try await assembler(request)
    }
    
    public static func redirect(
        to location: String = "/",
        type: Redirect = .normal
    ) -> Page {
        Page { $0.redirect(to: location, redirectType: type) }
    }
}
