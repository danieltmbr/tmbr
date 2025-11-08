import Foundation

public struct Command<Input, Output>: Sendable
where Input: Sendable, Output: Sendable {
    
    public typealias Execute = @Sendable (Input) async throws -> Output
    
    private let execute: Execute
    
    public init(execute: @escaping Execute) {
        self.execute = execute
    }
    
    public func callAsFunction(_ input: Input) async throws -> Output {
        try await execute(input)
    }
    
    public func callAsFunction() async throws -> Output
    where Input == Void {
        try await execute(())
    }
}
