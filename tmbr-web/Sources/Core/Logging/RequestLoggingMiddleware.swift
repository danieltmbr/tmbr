import Vapor

public struct RequestLoggingMiddleware: AsyncMiddleware {

    public init() {}

    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let start = DispatchTime.now()
        let response = try await next.respond(to: request)
        let ms = Int((DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000)
        let level: Logger.Level = response.status.code >= 500 ? .error
            : response.status.code >= 400 ? .warning : .info
        request.logger.log(level: level, "\(request.method) \(request.url.path) → \(response.status.code) [\(ms)ms]")
        return response
    }
}
