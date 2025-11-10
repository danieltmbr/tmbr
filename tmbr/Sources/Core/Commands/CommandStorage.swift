import Foundation
import Vapor

public actor CommandStorage {
    
    public struct Key: StorageKey {
        public typealias Value = CommandStorage
    }

    private var storage: [String: CommandCollection]
    
    public init(storage: [String : CommandCollection] = [:]) {
        self.storage = storage
    }
    
    public func add<C: CommandCollection>(collection: C) {
        storage[String(reflecting: type(of: collection))] = collection
    }

    func collection<C: CommandCollection>(_ type: C.Type) throws -> C {
        guard let collection = storage[String(reflecting: type)] as? C else {
            throw Abort(.serviceUnavailable, reason: "CommandCollection (\(type)) is unavailable.")
        }
        return collection
    }
}

extension Application {
    public var commands: CommandStorage {
        get throws {
            guard let commands = storage[CommandStorage.Key.self] else {
                throw Abort(.serviceUnavailable, reason: "Command Stroage is unavailable.")
            }
            return commands
        }
    }
}
