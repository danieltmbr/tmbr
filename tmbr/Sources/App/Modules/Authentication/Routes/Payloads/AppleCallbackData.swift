import Foundation
import Vapor

struct AppleCallbackData: Decodable, Sendable {
    struct User: Decodable, Sendable {
        
        struct Name: Decodable, Sendable {
            
            let firstName: String
            
            let lastName: String
        }
        
        let email: String?
        
        let name: Name?
    }
    
    enum Keys: String, CodingKey {
        case code, id_token, state, nonce, user
    }
    
    let code: String
    
    let id_token: String
    
    let state: String?
    
    let nonce: String?
    
    let user: User?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.id_token = try container.decode(String.self, forKey: .id_token)
        self.state = try container.decodeIfPresent(String.self, forKey: .state)
        self.nonce = try container.decodeIfPresent(String.self, forKey: .nonce)
        
        let userString = try container.decodeIfPresent(String.self, forKey: .user)
        if let userString = userString, let data = userString.data(using: .utf8) {
            self.user = try JSONDecoder().decode(User.self, from: data)
        } else {
            self.user = nil
        }
    }
}
