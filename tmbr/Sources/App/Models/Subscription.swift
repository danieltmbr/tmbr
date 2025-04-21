import Fluent
import Vapor

final class Subscription: Model, Content, @unchecked Sendable {
    static let schema = "subscriptions"
    
    // The auth secret (from subscription.getKey('auth'))
    @Field(key: "auth")
    var auth: String
    
    // The subscription endpoint (URL)
    @Field(key: "endpoint")
    var endpoint: String
    
    @ID(key: .id)
    var id: UUID?
    
    // The P256DH key (from subscription.getKey('p256dh'))
    @Field(key: "p256dh")
    var p256dh: String
    
    init() {}
    
    init(id: UUID? = nil, endpoint: String, p256dh: String, auth: String) {
        self.id = id
        self.endpoint = endpoint
        self.p256dh = p256dh
        self.auth = auth
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let keys = try container.nestedContainer(
            keyedBy: KeysCodingKeys.self,
            forKey: .keys
        )
        self.endpoint = try container.decode(String.self, forKey: .endpoint)
        self.p256dh = try keys.decode(String.self, forKey: .p256dh)
        self.auth   = try keys.decode(String.self, forKey: .auth)
    }
    
    private enum CodingKeys: String, CodingKey {
        case endpoint, keys
    }
    
    private enum KeysCodingKeys: String, CodingKey {
        case p256dh, auth
    }
}
