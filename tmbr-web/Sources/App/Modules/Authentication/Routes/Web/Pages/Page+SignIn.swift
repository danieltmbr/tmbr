import Vapor
import Core
import JWT
import AuthKit

struct SignInViewModel: Encodable {
    
    private let clientId: String
    
    private let scope: String = "name email"
    
    private let redirectUrl: String
    
    private let state: String?
    
    private let nonce: String?
    
    private let popup: Bool = false
    
    init(
        clientId: String,
        redirectUrl: String,
        state: String? = nil,
        nonce: String? = nil
    ) {
        self.clientId = clientId
        self.redirectUrl = redirectUrl
        self.state = state
        self.nonce = nonce
    }
    
    static func withNonce(
        date: Date = .now,
        signedBy sign: @escaping (StatePayload) async throws -> String
    ) async rethrows -> SignInViewModel {
        let nonce = [UInt8].random(count: 16).base64
        let payload = StatePayload(
            n: nonce,
            iat: .init(value: date),
            exp: .init(value: date.addingTimeInterval(5 * 60))
        )
        let state = try await sign(payload)
        return SignInViewModel(
            clientId: Environment.signIn.appID,
            redirectUrl: Environment.signIn.redirectUrl,
            state: state,
            nonce: nonce
        )
    }
}


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
            request.redirectReturnDestination = request.url
                .queryItems?
                .item(named: URLQueryItem.redirectReturnKey)?
                .value
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
