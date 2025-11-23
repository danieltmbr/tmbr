import Foundation
import Vapor

extension Page {
    public struct Recover {
        public typealias Handler = @Sendable (Error, Request) async throws -> AsyncResponseEncodable
        
        public static var all: Self {
            let throwAbort = Self.init { error in
                if error is AbortError {
                    throw error
                } else {
                    throw Abort(
                        .internalServerError,
                        reason: "Unknown error: \(error.localizedDescription)"
                    )
                }
            }
            return throwAbort.combine(with: .aborts)
        }
        
        public static var aborts: Self {
            .unathorized
                .combine(with: .fourhundreds)
                .combine(with: .fivehundreds)
        }
        
        private let handler: Handler
        
        public init(handler: @escaping Handler) {
            self.handler = handler
        }
        
        public init<Model: Encodable>(
            error map: @escaping @Sendable (Error) throws -> Model,
            template: Template<Model>
        ) {
            self.init { error, request in
                let model = try map(error)
                return try await template.render(model, with: request.view)
            }
        }
        
        public init(error map: @escaping @Sendable (Error) throws -> ErrorViewModel) {
            self.init(error: map, template: .error)
        }
        
        public init(abort map: @escaping @Sendable (AbortError) throws -> ErrorViewModel) {
            self.init { error in
                guard let abort = error as? AbortError else { throw error }
                return try map(abort)
            }
        }
        
        public init<Response>(
            status: HTTPResponseStatus,
            response: Response
        ) where Response: AsyncResponseEncodable & Sendable {
            self.init { error, _ in
                guard let abort = error as? Abort, abort.status == status else { throw error }
                return response
            }
        }
        
        func callAsFunction(_ error: Error, _ request: Request) async throws -> AsyncResponseEncodable {
            try await handler(error, request)
        }
        
        public func combine(with other: Self) -> Self {
            Self { error, request in
                do {
                    return try await handler(error, request)
                } catch {
                    return try await other(error, request)
                }
            }
        }
    }
}

extension Page {

    public func recover(handler: @escaping Recover.Handler) -> Page {
        recover(Recover(handler: handler))
    }
    
    public func recover<Model: Encodable>(
        error map: @escaping @Sendable (Error) throws -> Model,
        template: Template<Model>
    ) -> Page {
        recover(Recover(error: map, template: template))
    }
    
    public func recover(error map: @escaping @Sendable (Error) throws -> ErrorViewModel) -> Page {
        recover(Recover(error: map))
    }
    
    public func recover(abort map: @escaping @Sendable (AbortError) -> ErrorViewModel) -> Page {
        recover(Recover(abort: map))
    }
    
    public func recover(
        error status: HTTPResponseStatus,
        response: AsyncResponseEncodable
    ) -> Page {
        recover(Recover(status: status, response: response))
    }
}
