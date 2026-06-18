import Foundation
import CoreTmbr
import CoreAuth

extension UserResponse {

    init(user: User) {
        self.init(
            id: user.id!,
            appleID: user.appleID,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName
        )
    }
}
