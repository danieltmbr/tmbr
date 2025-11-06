import Foundation
import Vapor

public struct ErrorViewModel: Encodable {
    
    private let title: String
    
    private let message: String
    
    private let suggestedFixes: [String]
    
    public init(
        title: String,
        message: String,
        suggestedFixes: [String] = []
    ) {
        self.title = title
        self.message = message
        self.suggestedFixes = suggestedFixes
    }
}

extension Template where Model == ErrorViewModel {
    
    static let error = Template(name: "error")
}

extension Page {
    
    public typealias ErrorHandler = @Sendable (Error, Request) async throws -> AsyncResponseEncodable
    
    public func `catch`(handler: @escaping ErrorHandler) -> Page {
        Page { request in
            do {
                return try await response(for: request)
            } catch {
                return try await handler(error, request)
            }
        }
    }
    
    public func map<Model: Encodable>(
        error map: @escaping @Sendable (Error) -> Model,
        template: Template<Model>
    ) -> Page {
        self.catch { error, request in
            let model = map(error)
            return try await template.render(model, with: request.view)
        }
    }
    
    public func map(error map: @escaping @Sendable (Error) -> ErrorViewModel) -> Page {
        self.map(error: map, template: .error)
    }
}
