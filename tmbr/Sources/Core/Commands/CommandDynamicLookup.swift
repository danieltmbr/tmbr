import Foundation
import Vapor

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
    
//    public subscript <Input, Output>(dynamicMember keyPath: KeyPath<T, CommandFactory<Input, Output>>) -> any Command<Input, Output>
//    where T: CommandCollection {
//        get async throws {
//            let strorage = try request.application.commands
//            let collection = try await strorage.collection(T.self)
//            let factory = collection[keyPath: keyPath]
//            return try factory(request)
//        }
//    }
    
    public subscript <Input, Output>(dynamicMember keyPath: KeyPath<T, CommandFactory<Input, Output>>) -> CommandResolver<Input, Output>
    where T: CommandCollection {
        CommandResolver {
            let strorage = try request.application.commands
            let collection = try await strorage.collection(T.self)
            let factory = collection[keyPath: keyPath]
            return try factory(request)
        }
    }

}
