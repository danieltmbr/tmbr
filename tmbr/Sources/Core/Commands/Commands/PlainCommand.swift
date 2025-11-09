import Foundation

public struct PlainCommand<Input, Output>: Command
where Input: Sendable, Output: Sendable {
    
    public typealias Execute = @Sendable (Input) async throws -> Output
    
    private let execute: Execute
    
    public init(execute: @escaping Execute) {
        self.execute = execute
    }
    
    public func execute(_ input: Input) async throws -> Output {
        try await execute(input)
    }
}
