import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        req.view.render("index.html")
    }
}
