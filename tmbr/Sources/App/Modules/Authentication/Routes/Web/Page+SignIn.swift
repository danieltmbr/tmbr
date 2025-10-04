import Vapor
import Core
import JWT

extension Template where Model == SignInViewModel {
    static let signIn = Template(name: "signin")
}

extension Page where Model == SignInViewModel {
    
    static var redirectingSignIn: Self {
        Page(
            template: .signIn,
            parse: { request in
                let nonce = [UInt8].random(count: 16).base64
                let now = Date()
                let payload = StatePayload(
                    n: nonce,
                    iat: .init(value: now),
                    exp: .init(value: now.addingTimeInterval(5 * 60))
                )
                let state = try await request.jwt.sign(payload)
                return SignInViewModel(
                    clientId: Environment.signIn.appID,
                    redirectUrl: Environment.signIn.redirectUrl,
                    state: state,
                    nonce: nonce
                )
            },
            configure: { request, renderer in
                if request.auth.has(User.self) {
                    request.redirect(to: "/")
                } else {
                    try await renderer(request)
                }
            }
        )
    }
    
    // TODO: Implement a sign in page that shows log out button if user is logged in
}

