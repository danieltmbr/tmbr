import Foundation
import Vapor
import Core
import Fluent
import AuthKit

class FetchCommand<Item: Model>: Command, @unchecked Sendable {
    
    typealias ItemID = Item.IDValue
    
    typealias Input = FetchParameters<Item.IDValue>
    
    typealias Output = Item

    typealias PermissionInput = (item: Item, reason: FetchReason)
    
    let database: Database
            
    private let permission: ErasedPermissionResolver<PermissionInput>

    init(
        database: Database,
        permission: ErasedPermissionResolver<PermissionInput>
    ) {
        self.database = database
        self.permission = permission
    }
    
    convenience init(
        database: Database,
        readPermission: BasePermissionResolver<Item>,
        writePermission: AuthPermissionResolver<Item>
    ) {
        self.init(
            database: database,
            permission: ErasedPermissionResolver(input: \.item, condition: \.reason) { reason in
                switch reason {
                case .read: readPermission.eraseOutput()
                case .write: writePermission.eraseOutput()
                }
            }
        )
    }
    
    func execute(_ params: FetchParameters<ItemID>) async throws -> Item {
        guard let item = try await Item.find(params.itemID, on: database) else {
            throw Abort(.notFound, reason: "Item not found")
        }
        try await permission.grant((item, params.reason))
        return item
    }
}
