import AuthKit

extension PermissionScopes {
    var notifications: PermissionScopes.Notifications.Type { PermissionScopes.Notifications.self }
}

extension PermissionScopes {
    struct Notifications: PermissionScope, Sendable {
        
        let generic: AuthPermission<PushNotification>
        
        let post: AuthPermission<Post>

        init(
            generic: AuthPermission<PushNotification> = .genericNotification,
            post: AuthPermission<Post> = .postNotification
        ){
            self.generic = generic
            self.post = post
        }
    }
}
