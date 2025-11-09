import Vapor

public struct PermissionResolver<Input, Output>: Sendable {
    
    public typealias Resolve = @Sendable (Input) async throws -> Output
    
    private let resolve: Resolve
    
    init(resolve: @escaping Resolve) {
        self.resolve = resolve
    }
    
    init<S: PermissionScope>(
        request: Request,
        scope: S.Type,
        keyPath: KeyPath<S, Permission<Input>>
    ) where Output == Permission<Input>.AuthenticatedUser? {
        self.init { input in
            let storage = try request.application.permissions
            let scope = try await storage.scope(S.self)
            let permission = scope[keyPath: keyPath]
            return try permission.grant(input, on: request)
        }
    }
    
    init<S: PermissionScope>(
        request: Request,
        scope: S.Type,
        keyPath: KeyPath<S, AuthenticatingPermission<Input>>
    ) where Output == AuthenticatingPermission<Input>.AuthenticatedUser {
        self.init { input in
            let storage = try request.application.permissions
            let scope = try await storage.scope(S.self)
            let permission = scope[keyPath: keyPath]
            return try permission.grant(input, on: request)
        }
    }
    
    @discardableResult
    public func grant(_ input: Input) async throws -> Output {
        try await resolve(input)
    }
    
    @discardableResult
    public func grant() async throws -> Output
    where Input == Void {
        try await grant(())
    }
    
    @discardableResult
    public func callAsFunction(_ input: Input) async throws -> Output {
        try await grant(input)
    }
    
    @discardableResult
    public func callAsFunction() async throws -> Output
    where Input == Void {
        try await grant()
    }
}
