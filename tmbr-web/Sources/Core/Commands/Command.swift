import Foundation
import Vapor

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

public extension Command where Input == URL {
            
    func execute(_ stringURL: String) async throws -> Output {
        guard let url = URL(string: stringURL),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme) else {
            throw Abort(.badRequest, reason: "Invalid or missing URL")
        }
        return try await self.execute(url)
    }
    
    func callAsFunction(_ stringURL: String) async throws -> Output {
        try await execute(stringURL)
    }
}
