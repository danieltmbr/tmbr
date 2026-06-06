import Fluent
import Vapor

final class WebPushSubscription: Model, Content, @unchecked Sendable {
    static let schema = "web_push_subscriptions"
    
    @Field(key: "auth")
    var auth: String

    @Field(key: "endpoint")
    var endpoint: String

    @ID(key: .id)
    var id: UUID?

    /// Pipe-separated language codes (e.g. "en|hu"). Empty means receive all languages.
    @Field(key: "languages")
    var languages: String

    @Field(key: "p256dh")
    var p256dh: String

    init() {}

    init(id: UUID? = nil, endpoint: String, p256dh: String, auth: String, languages: String = "") {
        self.id = id
        self.endpoint = endpoint
        self.p256dh = p256dh
        self.auth = auth
        self.languages = languages
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
        let languageList = (try? container.decode([String].self, forKey: .languages)) ?? []
        self.languages = languageList.joined(separator: "|")
    }

    private enum CodingKeys: String, CodingKey {
        case endpoint, keys, languages
    }

    private enum KeysCodingKeys: String, CodingKey {
        case p256dh, auth
    }
}
