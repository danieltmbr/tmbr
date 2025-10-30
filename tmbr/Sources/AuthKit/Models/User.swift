import Fluent
import Vapor
import Foundation

public final class User: Model, Content, Authenticatable, @unchecked Sendable {
    
    public enum Role: String, Codable {
        case admin
        case author
        case standard
    }
    
    public static let schema = "users"

    @Field(key: "apple_id")
    public var appleID: String
        
    @Field(key: "email")
    public var email: String?
    
    @Field(key: "first_name")
    public var firstName: String?
    
    @ID(custom: "id", generatedBy: .database)
    public var id: Int?
    
    @Field(key: "last_name")
    public var lastName: String?
    
    @Field(key: "role")
    public var role: Role

    public init() { }

    public init(
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
    
    public static func findOrCreate(
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
    
    public static func find(
        appleID: String,
        in database: any Database
    ) async throws -> User? {
        try await User.query(on: database)
            .filter(\.$appleID == appleID)
            .first()
    }
}

extension User: ModelSessionAuthenticatable {}
