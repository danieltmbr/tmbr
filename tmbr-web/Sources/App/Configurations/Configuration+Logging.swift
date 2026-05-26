import Vapor
import Core

extension Configuration where Self == CoreConfiguration {
    static var logging: Self {
        CoreConfiguration { app in
            app.middleware.use(TracingMiddleware())
        }
    }
}
