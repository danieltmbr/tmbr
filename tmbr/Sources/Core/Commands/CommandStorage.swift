import Foundation
import Vapor

public actor CommandStorage {
    
    public struct Key: StorageKey {
        public typealias Value = CommandStorage
    }

    private var storage: [String: CommandCollection] = [:]
    
    public func add<C: CommandCollection>(collection: C) {
        storage[String(describing: C.Type.self)] = collection
    }

    func collection<C: CommandCollection>(_ type: C.Type) throws -> C {
        guard let collection = storage[String(describing: type)] as? C else {
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
