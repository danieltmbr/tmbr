import Foundation
import Vapor

public struct CommandResolver<Input, Output>: Sendable
where Input: Sendable, Output: Sendable {
    
    typealias Resolve = @Sendable () async throws -> any Command<Input, Output>
    
    private let resolve: Resolve
    
    init(resolve: @escaping Resolve) {
        self.resolve = resolve
    }
    
    public func callAsFunction(_ input: Input) async throws -> Output {
        let command = try await resolve()
        return try await command(input)
    }
    
    public func callAsFunction() async throws -> Output
    where Input == Void {
        try await callAsFunction(())
    }
}
