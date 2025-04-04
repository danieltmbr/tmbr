import Vapor

func configure(_ app: Application) async throws {
    try configureDatabase(app)
    try configureAuth(app)
    try configureRenderer(app)
    try webRoutes(app)
    try apiRoutes(app)
}
