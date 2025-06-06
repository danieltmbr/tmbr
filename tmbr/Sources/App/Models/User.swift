import Fluent
import Vapor
import Foundation

final class User: Model, Content, Authenticatable, @unchecked Sendable {
    
    enum Role: String, Codable {
        case admin
        case standard
    }
    
    static let schema = "users"

    @Field(key: "apple_id")
    var appleID: String
        
    @Field(key: "email")
    var email: String?
    
    @Field(key: "first_name")
    var firstName: String?
    
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "last_name")
    var lastName: String?
    
    @Children(for: \.$author)
    var posts: [Post]
    
    @Field(key: "role")
    var role: Role

    init() { }

    init(
        appleID: String,
        email: String?,
        firstName: String?,
        id: Int? = nil,
        lastName: String?,
        role: Role = .standard
    ) {
        self.id = id
        self.appleID = appleID
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.role = role
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
