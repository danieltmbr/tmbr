import Foundation
import Vapor

public enum Commands: Sendable {}

extension Request {
    public var commands: CommandDynamicLookup<Commands> {
        CommandDynamicLookup(request: self)
    }
}
