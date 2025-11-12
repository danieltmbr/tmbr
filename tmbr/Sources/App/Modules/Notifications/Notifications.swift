import Fluent
import Vapor
import WebPush
import Core
import AuthKit

struct Notifications: Module {
    
    fileprivate struct ServiceKey: StorageKey {
        typealias Value = NotificationService
    }
    
    private let commands: Commands.Notifications
    
    private let permissions: PermissionScopes.Notifications
    
    init(
        commands: Commands.Notifications,
        permissions: PermissionScopes.Notifications
    ) {
        self.commands = commands
        self.permissions = permissions
    }
    
    func configure(_ app: Vapor.Application) async throws {
        await app.storage.setWithAsyncShutdown(
            ServiceKey.self,
            to: try NotificationService(app: app)
        )
        
        app.migrations.add(CreateWebPushSubscription())
        
        try await app.permissions.add(scope: permissions)
        try await app.commands.add(collection: commands)
    }
    
    func boot(_ routes: RoutesBuilder) async throws {
        try routes.register(collection: NotificationsAPIController())
        routes.get("notifications", page: Page(template: .notifications))
    }
}

extension Application {
    var notificationService: NotificationService? {
        storage[Notifications.ServiceKey.self]
    }
}

extension Module where Self == Notifications {
    static var notifications: Self {
        Notifications(
            commands: Commands.Notifications(),
            permissions: PermissionScopes.Notifications()
        )
    }
}
