import Foundation
import Vapor

actor InMemoryFileStorage: FileStorage {
    
    private var storage: [String: Data] = [:]
    
    func delete(name: String) async throws {
        storage[name] = nil
    }
    
    func file(named name: String) async throws -> Data {
        if let data = storage[name] {
            return data
        } else {
            throw Abort(.notFound, reason: "Image not found with name: \(name)")
        }
    }
    
    func store(
        data: Data,
        contentType: String,
        name: String
    ) async throws {
        storage[name] = data
    }
}
