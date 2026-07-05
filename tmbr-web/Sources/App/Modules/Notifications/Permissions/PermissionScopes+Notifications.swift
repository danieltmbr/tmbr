import WebAuth

extension PermissionScopes {
    var notifications: PermissionScopes.Notifications.Type { PermissionScopes.Notifications.self }
}

extension PermissionScopes {
    struct Notifications: PermissionScope, Sendable {

        let generic: AuthPermission<PushNotification>

        let note: AuthPermission<Note>

        let post: AuthPermission<Post>

        let preview: AuthPermission<Preview>

        init(
            generic: AuthPermission<PushNotification> = .genericNotification,
            note: AuthPermission<Note> = .noteNotification,
            post: AuthPermission<Post> = .postNotification,
            preview: AuthPermission<Preview> = .previewNotification
        ) {
            self.generic = generic
            self.note = note
            self.post = post
            self.preview = preview
        }
    }
}
