import Vapor
import Fluent
import Foundation

struct PreviewResolver: Sendable {
    
    typealias Resolve = @Sendable (_ type: String, _ id: Int) async throws -> Preview?
        
    private let resolve: Resolve
    
    init(resolve: @escaping Resolve) {
        self.resolve = resolve
    }
    
    init(request: Request) {
        self.init { type, id in
            try await request.application.previewService.preview(
                for: type,
                id: id,
                on: request
            )
        }
    }
    
    func callAsFunction(for type: String, id: Int) async throws -> Preview? {
        try await resolve(type, id)
    }
}

extension Request {
    
    var previews: PreviewResolver {
        PreviewResolver(request: self)
    }
}
