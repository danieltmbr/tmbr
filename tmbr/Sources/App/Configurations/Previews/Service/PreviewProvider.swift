import Foundation
import Fluent
import Vapor

public protocol PreviewProvider: Sendable {
    
    associatedtype Item
    
    func preview(
        id: Int,
        on request: Request
    ) async throws -> Preview?
}

extension PreviewProvider {
    
    var type: String {
        String(reflecting: Item.Type.self)
    }
}
