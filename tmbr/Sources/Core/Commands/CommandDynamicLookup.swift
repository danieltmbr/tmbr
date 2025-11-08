import Foundation
import Vapor

public protocol CommandCollection: Sendable {}

@dynamicMemberLookup
public struct CommandDynamicLookup<T: Sendable>: Sendable {
    
    private let path: KeyPath<Commands, T>
    
    private let request: Request
    
    init(
        path: KeyPath<Commands, T>,
        request: Request
    ) {
        self.path = path
        self.request = request
    }
    
    public subscript <U>(dynamicMember keyPath: KeyPath<T, U>) -> CommandDynamicLookup<U> {
        CommandDynamicLookup<U>(path: path.appending(path: keyPath), request: request)
    }
    
    public subscript <C, Input, Output>(
        dynamicMember keyPath: KeyPath<C, CommandFactory<Input, Output>>
    ) -> Command<Input, Output>
    where C: CommandCollection, T == C.Type, Input: Sendable, Output: Sendable {
        get async throws {
            let strorage = try request.application.commands
            let collection = try await strorage.collection(C.self)
            let factory = collection[keyPath: keyPath]
            return try factory(request)
        }
    }
}
