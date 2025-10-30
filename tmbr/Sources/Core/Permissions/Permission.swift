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
    
    public typealias Verify = @Sendable (Request, Input) throws(PermissionError) -> Void
    
    private let verify: Verify
    
    public init(verify: @escaping Verify) {
        self.verify = verify
    }
    
    public func verify(_ input: Input, on request: Request) throws(PermissionError) {
        try self.verify(request, input)
    }
    
    public func verify(on request: Request) throws(PermissionError)
    where Input == Void {
        try self.verify((), on: request)
    }
    
    public static func granted() -> Self {
        Self { _, _ in }
    }
    
    public static func denied(error: PermissionError = .forbidden) -> Self {
        Self { _, _ throws(PermissionError) -> Void in throw error }
    }
}
