import Foundation
import Vapor

public struct CommandFactory<Input, Output>: Sendable
where Input: Sendable, Output: Sendable {
    
    public typealias Factory = @Sendable (Request) throws -> any Command<Input, Output>
    
    private let make: Factory
    
    public init(make: @escaping Factory) {
        self.make = make
    }
    
    public init(command: any Command<Input, Output>) {
        self.init { _ in command }
    }
    
    @Sendable
    public func callAsFunction(_ request: Request) throws -> any Command<Input, Output> {
        try make(request)
    }
}
