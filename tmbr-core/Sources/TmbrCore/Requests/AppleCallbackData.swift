public struct AppleCallbackData: Codable, Sendable {

    public struct User: Codable, Sendable {

        public struct Name: Codable, Sendable {
            public let firstName: String
            public let lastName: String

            public init(firstName: String, lastName: String) {
                self.firstName = firstName
                self.lastName = lastName
            }
        }

        public let email: String?
        public let name: Name?

        public init(email: String?, name: Name?) {
            self.email = email
            self.name = name
        }
    }

    public let code: String
    public let idToken: String
    public let nonce: String?
    public let user: User?

    public init(code: String, idToken: String, nonce: String?, user: User?) {
        self.code = code
        self.idToken = idToken
        self.nonce = nonce
        self.user = user
    }

    private enum CodingKeys: String, CodingKey {
        case code
        case idToken = "id_token"
        case nonce
        case user
    }
}
