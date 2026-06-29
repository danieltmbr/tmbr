import Fluent
import Foundation
import SQLKit

public struct CreateAccess: AsyncMigration {

    public var name: String { "AuthKit.CreateAccess" }

    public init() {}
    
    public func prepare(on database: Database) async throws {
        _ = try await database.enum("access")
            .case("public")
            .case("private")
            .create()
    }
    
    public func revert(on database: Database) async throws {
        try await database.enum("access").delete()
    }
}
