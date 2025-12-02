import Foundation
import AuthKit

struct UserResponse: Encodable, Sendable {
    
    private let id: UserID
    
    private let appleID: String
    
    private let email: String?
    
    private let firstName: String?
    
    private let lastName: String?
        
    init(
        id: UserID,
        appleID: String,
        email: String?,
        firstName: String?,
        lastName: String?
    ) {
        self.id = id
        self.appleID = appleID
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
    }
    
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
