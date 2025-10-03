import Foundation
import Vapor

struct Page<Model: Encodable & Sendable>: Sendable {
    
    private let render: @Sendable (Request) async throws -> View

    @inlinable
    init(render: @Sendable @escaping (Request) async throws -> View) {
        self.render = render
    }
    
    @inlinable
    init(
        template: Template<Model>,
        parse: @Sendable @escaping (Request) async throws -> Model
    ) {
        self.init { request in
            try await template.render(parse(request), with: request.view)
        }
    }
    
    @Sendable
    @inlinable
    func render(on req: Request) async throws -> View {
        try await render(req)
    }
    
    // FIXME: Manifest endpoint where this is being used shouldn't really be a Page (& View)
    // It should simply be an encodable model response
    func response(
        for request: Request,
        headers configure: @escaping (inout HTTPHeaders) -> Void = { _ in }
    ) async throws -> Response {
        let view = try await render(on: request)
        var headers = HTTPHeaders()
        configure(&headers)
        return Response(status: .ok, headers: headers, body: .init(buffer: view.data))
    }
}

extension Page where Model == Never {
    @inlinable
    init(template: Template<Never>) {
        self.init { request in
            try await template.render(with: request.view)
        }
    }
}
