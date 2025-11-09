import Foundation
import Vapor

public struct AuthenticatingPermission<Input>: Sendable {
    
    public typealias AuthenticatedUser = Permission<Input>.AuthenticatedUser
    
    public typealias Grant = @Sendable (Request, Input) throws -> AuthenticatedUser
    
    private let grant: Grant
    
    public init(grant: @escaping Grant) {
        self.grant = grant
    }
    
    public init(
        grant: @Sendable @escaping (AuthenticatedUser, Input) throws -> Void
    ) {
        self.init { (request, input) in
            guard let user = request.auth.get(User.self),
                  let userID = user.id else {
                throw Abort(.unauthorized)
            }
            let authenticatedUser = AuthenticatedUser(user: user, userID: userID)
            try grant(authenticatedUser, input)
            return authenticatedUser
        }
    }
    
    /// Can be used for permission check where the
    /// only requirement is to have an authenticated user.
    ///
    public init() where Input == Void {
        self.init { _, _ in }
    }
    
    public init(
        _ deniedReason: String,
        granted: @Sendable @escaping (AuthenticatedUser, Input) -> Bool
    ) {
        self.init { (user, input) in
            if !granted(user, input) {
                throw Abort(.forbidden, reason: deniedReason)
            }
        }
    }
    
    @discardableResult
    public func grant(_ input: Input, on request: Request) throws -> AuthenticatedUser {
        try self.grant(request, input)
    }
    
    @discardableResult
    public func grant(on request: Request) throws -> AuthenticatedUser
    where Input == Void {
        try self.grant((), on: request)
    }
}
