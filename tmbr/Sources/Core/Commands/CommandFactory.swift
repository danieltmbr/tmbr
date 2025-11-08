import Foundation
import Vapor

public struct CommandFactory<Input, Output>: Sendable
where Input: Sendable, Output: Sendable {
    
    public typealias Factory = @Sendable (Request) throws -> Command<Input, Output>
    
    private let make: Factory
    
    public init(make: @escaping Factory) {
        self.make = make
    }
    
    public init(command: Command<Input, Output>) {
        self.init { _ in command }
    }
    
    public func callAsFunction(_ request: Request) throws -> Command<Input, Output> {
        try make(request)
    }
}
