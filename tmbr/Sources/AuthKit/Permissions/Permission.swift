import Foundation
import Vapor

public enum PermissionError: Swift.Error, Sendable, Hashable {
    case unauthorized
    case forbidden
    case missingPermission
    
    public var httpStatus: HTTPResponseStatus {
        switch self {
        case .unauthorized: return .unauthorized
        case .forbidden: return .forbidden
        case .missingPermission: return .internalServerError
        }
    }
}

public struct Permission<Input>: Sendable {
    
    @dynamicMemberLookup
    public struct AuthenticatedUser: Sendable {
        public let user: User
        
        public let userID: User.IDValue
        
    
        init(user: User, userID: User.IDValue) {
            self.user = user
            self.userID = userID
        }
        
        init(from request: Request) throws(PermissionError) {
            guard let user = request.auth.get(User.self),
                  let userID = user.id else {
                throw PermissionError.unauthorized
            }
            self.init(user: user, userID: userID)
        }
        
        public subscript<V>(dynamicMember keyPath: WritableKeyPath<User, V>) -> V {
            get { user[keyPath: keyPath] }
            // nonmutating set { user[keyPath: keyPath] = newValue }
        }
    }
    
    public typealias Grant = AuthenticatedUser
    
    public typealias Verify = @Sendable (Request, Input) throws(PermissionError) -> Grant
    
    private let verify: Verify
    
    public init(verify: @escaping Verify) {
        self.verify = verify
    }
    
    public init(verify: @Sendable @escaping (AuthenticatedUser, Input) throws(PermissionError) -> Void) {
        self.init { (request, input) throws(PermissionError) -> Grant in
            let authenticatedUser = try AuthenticatedUser(from: request)
            try verify(authenticatedUser, input)
            return authenticatedUser
        }
    }
    
    public init(granted: @Sendable @escaping (AuthenticatedUser, Input) -> Bool) {
        self.init { (user, input) throws(PermissionError) -> Void in
            if !granted(user, input) { throw .forbidden }
        }
    }
    
    @discardableResult
    public func verify(_ input: Input, on request: Request) throws(PermissionError) -> Grant {
        try self.verify(request, input)
    }
    
    @discardableResult
    public func verify(on request: Request) throws(PermissionError) -> Grant
    where Input == Void {
        try self.verify((), on: request)
    }
}
