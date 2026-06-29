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
            let status = (error as? AbortError)?.status ?? .internalServerError
            let level: Logger.Level = status.code >= 500 ? .error : .warning
            request.logger.log(
                level: level,
                "[\(status.code)] \(request.method) \(request.url.path) — \(String(reflecting: type(of: error))): \(error.localizedDescription)"
            )
            return try await recover(error, request)
                .encodeResponse(for: request)
        }
    }
}
