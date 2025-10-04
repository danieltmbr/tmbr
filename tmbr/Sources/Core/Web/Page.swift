import Foundation
import Vapor

public struct Page<Model: Encodable & Sendable>: Sendable, AsyncResponseEncodable {
    
    public typealias Assembler = @Sendable (Request, Parser, Renderer) async throws -> AsyncResponseEncodable
    
    public typealias Parser = @Sendable (Request) async throws -> Model
    
    public typealias Renderer = @Sendable (Request, Parser) async throws -> View
    
    private let assembler: Assembler

    fileprivate let parser: Parser
    
    fileprivate let renderer: Renderer
    
    public init(
        parser: @escaping Parser,
        renderer: @escaping Renderer,
        assembler: @escaping Assembler
    ) {
        self.parser = parser
        self.renderer = renderer
        self.assembler = assembler
    }
    
    public init(
        parser: @escaping Parser,
        renderer: @escaping Renderer
    ) {
        self.init(
            parser: parser,
            renderer: renderer,
            assembler: { request, parser, render  in
                try await render(request, parser)
            }
        )
    }
    
    public init(
        template: Template<Model>,
        parser: @escaping Parser
    ) {
        self.init(parser: parser) { request, parser in
            try await template.render(
                parser(request),
                with: request.view
            )
        }
    }
    
    public init(
        template: Template<Model>,
        parse: @escaping Parser,
        configure: @escaping EncodeResponse
    ) {
        self.init(
            render: { request in
                try await template.render(parse(request), with: request.view)
            },
            response: configure
        )
    }
    
    public func encodeResponse(for request: Request) async throws -> Response {
        try await response(request, render).encodeResponse(for: request)
    }
}

extension Page {

    public func map(_ transform: @escaping @Sendable (EncodeResponse) -> EncodeResponse) -> Page {
        Page(render: render, response: transform(response))
    }


    public func mapRenderer(_ transform: @escaping @Sendable (Request, Renderer) async throws -> View) -> Page {
        Page(
            render: { try await transform($0, self.render) },
            response: response
        )
    }

//    public func choosing<Other>(_ other: Page<Other>, when predicate: @Sendable @escaping (Request) async throws -> Bool) -> Page<Never> {
//        let lhsRender = self.render
//        let rhsRender = other.render
//        let lhsResponse = self.response
//        let rhsResponse = other.response
//
//        return Page<Never>(
//            render: { request in
//                if try await predicate(request) {
//                    return try await rhsRender(request)
//                } else {
//                    return try await lhsRender(request)
//                }
//            },
//            response: { request, _ in
//                if try await predicate(request) {
//                    return try await rhsResponse(request, rhsRender)
//                } else {
//                    return try await lhsResponse(request, lhsRender)
//                }
//            }
//        )
//    }
}

extension Page where Model == Never {
    @inlinable
    public init(template: Template<Never>) {
        self.init { request in
            try await template.render(with: request.view)
        }
    }
}

extension Page where Model == Never {
    @inlinable
    public static func redirect(
        to location: String = "/",
        type: Redirect = .normal
    ) -> Page {
        Page(
            render: { _ in },
            response: { request, _ in
                request.redirect(to: location, type: type)
            }
        )
    }
}
