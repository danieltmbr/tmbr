import AuthKit

extension Permission<Void> {

    static var listDeletions: Self {
        Permission { request, _ in
            guard let user = request.auth.get(AuthKit.User.self),
                  let userID = user.id else { return nil }
            return Permission.User(user: user, userID: userID)
        }
    }
}
