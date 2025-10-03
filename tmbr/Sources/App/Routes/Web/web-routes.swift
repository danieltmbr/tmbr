import Vapor

func webRoutes(_ app: Application) throws {
    try app.register(collection: AuthController())
    try app.register(collection: ManifestController())
    try app.register(collection: NotificationsController())
    try app.register(collection: PostsController())

}
