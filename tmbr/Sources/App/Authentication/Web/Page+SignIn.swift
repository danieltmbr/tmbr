import Vapor
import Core

struct SignInViewModel: Encodable {
    
    private let clientId: String
    
    private let scope: String = "name email"
    
    private let redirectUrl: String
    
    private let state: String
    
    private let popup: Bool = false
    
    init(
        clientId: String,
        redirectUrl: String,
        state: String
    ) {
        self.clientId = clientId
        self.redirectUrl = redirectUrl
        self.state = state
    }
}

extension Template where Model == SignInViewModel {
    static let signin = Template(name: "signin")
}

extension Page where Model == SignInViewModel {
    static var signin: Self {
        Page(template: .signin) { request in
            let state = [UInt8].random(count: 16).base64
            request.session.data["state"] = state
            return SignInViewModel(
                clientId: Environment.signIn.appID,
                redirectUrl: Environment.signIn.redirectUrl,
                state: state
            )
        }
    }
}
