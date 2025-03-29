import Fluent
import Vapor
import Foundation

final class User: Model, Content, Authenticatable, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "apple_id")
    var appleID: String
        
    @Field(key: "email")
    var email: String?
    
    @Field(key: "first_name")
    var firstName: String?
    
    @Field(key: "last_name")
    var lastName: String?

    init() { }

    init(
        id: UUID? = nil,
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
    
    static func findOrCreate(
        in database: any Database,
        appleID: String,
        email: String?,
        firstName: String?,
        lastName: String?
    ) async throws -> User {
        let user: User
        if let existingUser = try await find(appleID: appleID, in: database) {
            user = existingUser
        } else {
            user = User(
                appleID: appleID,
                email: email,
                firstName: firstName,
                lastName: lastName
            )
            try await user.save(on: database)
        }
        return user
    }
    
    static func find(
        appleID: String,
        in database: any Database
    ) async throws -> User? {
        try await User.query(on: database)
            .filter(\.$appleID == appleID)
            .first()
    }
}
