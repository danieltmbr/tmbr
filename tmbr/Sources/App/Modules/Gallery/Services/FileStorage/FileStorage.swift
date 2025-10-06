import Foundation
import Vapor

protocol FileStorage: Sendable {
    
    func delete(name: String) async throws
    
    func file(named: String) async throws -> Data
    
    func store(data: Data, contentType: String, name: String) async throws
}
