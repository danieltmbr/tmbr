import Foundation

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
