import Foundation
import Vapor

public struct Form: Encodable, Hashable, Sendable {
    
    public struct Submit: Encodable, Hashable, Sendable {
        private let action: String
        
        private let label: String

        private let method: String
        
        public init(
            action: String,
            label: String,
            method: HTTPMethod = .POST
        ) {
            self.action = action
            self.label = label
            self.method = method.rawValue
        }
    }
}
