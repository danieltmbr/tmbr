import Vapor

public typealias AuthPermissionResolver<Input> = PermissionResolver<Input, AuthPermission<Input>.User>

public typealias BasePermissionResolver<Input> = PermissionResolver<Input, Permission<Input>.User?>

public typealias ErasedPermissionResolver<Input> = PermissionResolver<Input, Void>

public struct PermissionResolver<Input, Output>: Sendable {
    
    typealias Resolve = @Sendable (Input) async throws -> Output
    
    private let resolve: Resolve
    
    init(resolve: @escaping Resolve) {
        self.resolve = resolve
    }
    
    init<S: PermissionScope>(
        request: Request,
        scope: S.Type,
        keyPath: KeyPath<S, Permission<Input>>
    ) where Output == Permission<Input>.User? {
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
        keyPath: KeyPath<S, AuthPermission<Input>>
    ) where Output == AuthPermission<Input>.User {
        self.init { input in
            let storage = try request.application.permissions
            let scope = try await storage.scope(S.self)
            let permission = scope[keyPath: keyPath]
            return try permission.grant(input, on: request)
        }
    }
    
    public func eraseOutput() -> PermissionResolver<Input, Void> {
        PermissionResolver<Input, Void> { try await self.grant($0) }
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


extension ErasedPermissionResolver {
    
    // TODO: This could be an actual "CompoundPermissionResolver"
    // but for that we might need to introduce protocols
    
    public init<I, C>(
        input: @escaping (Input) -> I,
        condition: @escaping (Input) -> C,
        select: @escaping (C) -> PermissionResolver<I, Void>
    ) where Output == Void {
        self.init {
            let permission = select(condition($0))
            return try await permission.grant(input($0))
        }
    }
    
    public init<I, C>(
        input: KeyPath<Input, I>,
        condition: KeyPath<Input, C>,
        select: @escaping (C) -> PermissionResolver<I, Void>
    ) where Output == Void {
        self.init(
            input: { $0[keyPath: input] },
            condition: { $0[keyPath: condition] },
            select: select
        )
    }
}
