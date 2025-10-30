import Vapor
import Core
import JWT
import AuthKit

extension Template where Model == SignInViewModel {
    static let signIn = Template(name: "Authentication/signin")
}

extension Page {
    
    static var signIn: Self {
        Page { request in
            guard !request.auth.has(User.self) else {
                return request.redirect(to: "/")
            }
            let model = try await SignInViewModel.withNonce(signedBy: request.jwt.signState)
            return try await Template.signIn.render(model, with: request.view)
        }
    }

    static var signInOrSignOut: Self {
        Page { request in
            if let user = request.auth.get(User.self) {
                let name = NameFormatter.author.format(
                    givenName: user.firstName,
                    familyName: user.lastName
                )
                let csrf = UUID().uuidString
                request.session.data["csrf.signout"] = csrf
                let model = SignOutViewModel(name: name, csrf: csrf)
                return try await Template.signOut.render(model, with: request.view)
            } else {
                let model = try await SignInViewModel.withNonce(signedBy: request.jwt.signState)
                return try await Template.signIn.render(model, with: request.view)
            }
        }
    }
}

private extension Request.JWT {
    func signState(payload: StatePayload) async throws -> String {
        try await sign(payload)
    }
}
