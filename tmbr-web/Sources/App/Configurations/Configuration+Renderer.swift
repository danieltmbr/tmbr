import Vapor
import CoreWeb

extension Configuration where Self == CoreConfiguration {
    static var renderer: Self {
        CoreConfiguration { app in
            if app.environment == .production {
                app.directory = DirectoryConfiguration(workingDirectory: "tmbr-web")
            }
            app.middleware.use(FileMiddleware(
                publicDirectory: app.directory.publicDirectory
            ))
            app.views.use(.leaf)
        }
    }
}
