import CoreAuth

extension PermissionScopes {
    var notifications: PermissionScopes.Notifications.Type { PermissionScopes.Notifications.self }
}

extension PermissionScopes {
    struct Notifications: PermissionScope, Sendable {

        let generic: AuthPermission<PushNotification>

        let note: AuthPermission<Note>

        let post: AuthPermission<Post>

        init(
            generic: AuthPermission<PushNotification> = .genericNotification,
            note: AuthPermission<Note> = .noteNotification,
            post: AuthPermission<Post> = .postNotification
        ) {
            self.generic = generic
            self.note = note
            self.post = post
        }
    }
}
