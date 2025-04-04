import Vapor

func configureRenderer(_ app: Application) throws {
    if app.environment == .production {
        app.directory = DirectoryConfiguration(workingDirectory: "tmbr")
    }
    app.middleware.use(FileMiddleware(
        publicDirectory: app.directory.publicDirectory
    ))
    app.views.use(.leaf)
}
