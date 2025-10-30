import Foundation
import Core

extension Permission {
    init(verify: @Sendable @escaping (User, Input) throws(PermissionError) -> Void) {
        self.init { (request, input) throws(PermissionError) -> Void in
            guard let user = request.auth.get(User.self), user.id != nil else {
                throw PermissionError.unauthorized
            }
            try verify(user, input)
        }
    }
    
    init(granted: @Sendable @escaping (User, Input) -> Bool) {
        self.init { (user, input) throws(PermissionError) -> Void in
            if !granted(user, input) { throw .forbidden }
        }
    }
}
