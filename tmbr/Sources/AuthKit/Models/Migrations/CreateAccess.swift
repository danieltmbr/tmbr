import Fluent
import Foundation
import SQLKit

public struct CreateAccess: AsyncMigration {
    
    public init() {}
    
    public func prepare(on database: Database) async throws {
        let access = try await database.enum("access")
            .case("public")
            .case("private")
            .create()
    }
    
    public func revert(on database: Database) async throws {
        try await database.enum("access").delete()
    }
}
