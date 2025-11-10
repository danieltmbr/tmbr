import Foundation
import Logging

public struct LoggedCommand<Input, Output>: Command
where Input: Sendable, Output: Sendable {
    
    public typealias Execute = @Sendable (Input) async throws -> Output
    
    private let execute: Execute
        
    private let logger: Logger
    
    private let name: String

    public init(
        name: String,
        logger: Logger,
        execute: @escaping Execute
    ) {
        self.name = name
        self.logger = logger
        self.execute = execute
    }
    
    fileprivate init(
        base: some Command<Input, Output>,
        name: String,
        logger: Logger
    ) {
        self.init(name: name, logger: logger, execute: base.execute)
    }
    
    public func execute(_ input: Input) async throws -> Output {
        logger.trace("\(name) started with input: \(String(describing: input))")
        do {
            let output = try await execute(input)
            logger.trace("\(name) produced output: \(String(describing: output))")
            return output
        } catch {
            logger.error("\(name) produced error: \(error)")
            throw error
        }
    }
}

extension Command {
    public func logged(
        name: String = String(describing: Self.self),
        logger: Logger
    ) -> LoggedCommand<Input, Output> {
        if let command = self as? LoggedCommand<Input, Output> {
            return command
        } else {
            return LoggedCommand(base: self, name: name, logger: logger)
        }
    }
}

extension CommandFactory {
    public func logged() -> Self {
        CommandFactory { request in
            try self(request).logged(logger: request.logger)
        }
    }
}
