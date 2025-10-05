import Vapor
import Core
import JWT
import Foundation

struct SignOutViewModel: Encodable {
    let name: String
    let csrf: String

    init(name: String, csrf: String) {
        self.name = name
        self.csrf = csrf
    }
}

extension Template where Model == SignOutViewModel {
    static let signOut = Template(name: "Authentication/signout")
}

extension Page {
    // FIXME: This is more like a "Profile" Page rahter than a "sign out"
    static var signOut: Self {
        Page(template: .signOut) { request in
            let user = try request.auth.require(User.self)
            let name = NameFormatter.author.format(
                givenName: user.firstName,
                familyName: user.lastName
            )
            let csrf = UUID().uuidString
            request.session.data["csrf.signout"] = csrf
            return SignOutViewModel(name: name, csrf: csrf)
        }
    }
}
