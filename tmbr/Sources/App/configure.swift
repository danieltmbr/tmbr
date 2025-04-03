import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import JWTKit

func configure(_ app: Application) async throws {

    try configureDatabase(app)
    try configureAuth(app)

    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.views.use(.leaf)
        
    try webRoutes(app)
    try apiRoutes(app)
}
