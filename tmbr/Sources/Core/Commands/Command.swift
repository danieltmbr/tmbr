import Foundation

public protocol Command<Input, Output>: Sendable {
    
    associatedtype Input: Sendable
    
    associatedtype Output: Sendable
    
    @Sendable
    func execute(_ input: Input) async throws -> Output
}

public extension Command {

    func callAsFunction(_ input: Input) async throws -> Output {
        try await execute(input)
    }
}

public extension Command where Input == Void {
    
    func execute() async throws -> Output {
        try await execute(())
    }
    
    func callAsFunction() async throws -> Output {
        try await execute()
    }
}
