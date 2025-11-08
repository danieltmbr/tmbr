import Foundation
import Vapor

struct TracingMiddleware: AsyncMiddleware {

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let trace: Trace
        if let traceparent = request.headers.first(name: Trace.key),
           let parsed = Trace(traceparent: traceparent) {
            trace = parsed
        } else {
            trace = Trace()
        }
        request.logger.trace = trace
        request.application.logger.trace = trace
        return try await next.respond(to: request)
    }
}
