import Vapor

struct NotificationsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("notifications", page: Page(template: .notifications))
    }
}

extension Template where Model == Never {
    static let notifications = Template(name: "notifications")
}
