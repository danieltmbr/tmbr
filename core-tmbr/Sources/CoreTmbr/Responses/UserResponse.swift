import Foundation

public struct UserResponse: Codable, Sendable {

    public let id: UserID

    public let appleID: String

    public let email: String?

    public let firstName: String?

    public let lastName: String?

    public init(
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
}
