import Foundation
import Vapor

public enum PermissionScopes {}

extension Request {
    public var permissions: PermissionDynamicLookup<PermissionScopes> {
        PermissionDynamicLookup(request: self)
    }
}
