import Vapor
import Core

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
}

extension Template where Model == SignInViewModel {
    static let signIn = Template(name: "signin")
}

extension Page where Model == SignInViewModel {
    
    static var redirectingSignIn: Self {
        Page(
            template: .signIn,
            parse: { request in
                let nonce = [UInt8].random(count: 16).base64
                request.session.data["nonce"] = nonce
                return SignInViewModel(
                    clientId: Environment.signIn.appID,
                    redirectUrl: Environment.signIn.redirectUrl,
                    nonce: nonce
                )
            }
//            ,
//            configure: { request, renderer in
//                if request.auth.has(User.self) {
//                    request.redirect(to: "/")
//                } else {
//                    try await renderer(request)
//                }
//            }
        )
    }
    
    // TODO: Implement a sign in page that shows log out button if user is logged in
}

