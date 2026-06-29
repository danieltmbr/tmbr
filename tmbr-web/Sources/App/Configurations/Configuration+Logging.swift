import Vapor
import WebCore

extension Configuration where Self == CoreConfiguration {
    static var logging: Self {
        CoreConfiguration { app in
            app.middleware.use(TracingMiddleware())
            app.middleware.use(RequestLoggingMiddleware())
        }
    }
}
