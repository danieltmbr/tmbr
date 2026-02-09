import Foundation
import Vapor

public struct CommandResolver<Input, Output>: Sendable
where Input: Sendable, Output: Sendable {
    
    typealias Resolve = @Sendable () async throws -> any Command<Input, Output>
    
    private let resolve: Resolve
    
    init(resolve: @escaping Resolve) {
        self.resolve = resolve
    }
    
    @Sendable
    public func callAsFunction(_ input: Input) async throws -> Output {
        let command = try await resolve()
        return try await command(input)
    }
    
    @Sendable
    public func callAsFunction() async throws -> Output
    where Input == Void {
        try await callAsFunction(())
    }
            
    @Sendable
    public func callAsFunction(_ stringURL: String) async throws -> Output
    where Input == URL {
        let command = try await resolve()
        return try await command(stringURL)
    }
}

extension Optional {
    
    public func map<Output>(_ command: CommandResolver<Wrapped, Output>) async throws -> Output? {
        guard let value = self.wrapped else { return nil }
        return try await command(value)
    }
}
