import Foundation
import Vapor

public final class RecoverMiddleware: AsyncMiddleware {

    private let recover: Page.Recover
    
    public init(recover: Page.Recover = .all) {
        self.recover = recover
    }
    
    public func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch {
            request.logger.error("Recover error: \(error.localizedDescription)")
            return try await recover(error, request)
                .encodeResponse(for: request)
        }
    }
}
