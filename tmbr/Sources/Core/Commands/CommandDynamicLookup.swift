import Foundation
import Vapor
import Fluent

public protocol CommandCollection: Sendable {}

@dynamicMemberLookup
public struct CommandDynamicLookup<T: Sendable>: Sendable {
        
    private let request: Request
    
    init(request: Request) {
        self.request = request
    }
    
    public subscript <U>(dynamicMember keyPath: KeyPath<T, U.Type>) -> CommandDynamicLookup<U> {
        CommandDynamicLookup<U>(request: request)
    }
    
    public subscript <Input, Output>(dynamicMember keyPath: KeyPath<T, CommandFactory<Input, Output>>) -> CommandResolver<Input, Output>
    where T: CommandCollection {
        CommandResolver {
            let strorage = try request.application.commands
            let collection = try await strorage.collection(T.self)
            let factory = collection[keyPath: keyPath]
            return try factory(request)
        }
    }
    
    public func transaction<V>(_ execute: @escaping @Sendable (Self) async throws -> V) async throws -> V
    where T == Commands {
        let database: any Database = request.commandDB
        if database.inTransaction {
            return try await CommandContext.$database.withValue(database) {
                try await execute(self)
            }
        } else {
            return try await database.transaction { tx in
                try await CommandContext.$database.withValue(tx) {
                    try await execute(self)
                }
            }
        }
    }
}
