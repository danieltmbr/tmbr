import Fluent
import Vapor
import WebPush
import Core

struct Notifications: Module {
    
    fileprivate struct ServiceKey: StorageKey {
        typealias Value = NotificationService
    }
    
    func configure(_ app: Vapor.Application) throws {
        app.storage.set(
            ServiceKey.self,
            to: try NotificationService(app: app)
        )
        
        app.migrations.add(CreateWebPushSubscription())
    }
    
    func boot(_ app: Vapor.Application) throws {
        try app.register(collection: AuthenticationAPIController())
        app.get("notifications", page: Page(template: .notifications))
    }
}

extension Application {
    var notificationService: NotificationService? {
        storage[Notifications.ServiceKey.self]
    }
}

extension Module where Self == Notifications {
    static var notifications: Self {
        Notifications()
    }
}
