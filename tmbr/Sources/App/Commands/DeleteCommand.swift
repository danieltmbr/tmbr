import Foundation
import Vapor
import Logging
import Fluent
import AuthKit
import Core

public struct DeleteCommand<Item: Model>: Command, Sendable {
    
    private let database: Database

    private let permission: PermissionResolver<Item, Void>
    
    public init(
        database: Database,
        permission: PermissionResolver<Item, Void>
    ) {
        self.database = database
        self.permission = permission
    }
    
    public func execute(_ itemID: Item.IDValue) async throws {
        guard let item = try await Item.find(itemID, on: database) else {
            throw Abort(.notFound, reason: "Item not found")
        }
        try await permission.grant(item)
        try await item.delete(on: database)
    }
}

extension CommandFactory where Output == Void {
    
    static func delete<Scope, Item>(
        _ scope: KeyPath<PermissionScopes, Scope.Type>,
        permission: KeyPath<Scope, AuthPermission<Item>>
    ) -> CommandFactory<Item.IDValue, Void>
    where Scope: PermissionScope, Item: Model, Input == Item.IDValue {
        CommandFactory { request in
            let s = request.permissions[dynamicMember: scope]
            let p = s[dynamicMember: permission]
            return DeleteCommand<Item>(
                database: request.db,
                permission: p.eraseOutput()
            ).logged(logger: request.logger)
        }
    }
    
    static func delete<Item>(
        _ scope: KeyPath<PermissionScopes, PreviewablePermissionScope<Item>.Type>,
    ) -> CommandFactory<Item.IDValue, Void>
    where Item: Model & Previewable, Input == Item.IDValue {
        CommandFactory { request in
            let s = request.permissions[dynamicMember: scope]
            return DeleteCommand<Item>(
                database: request.db,
                permission: s.delete.eraseOutput()
            ).logged(logger: request.logger)
        }
    }
}
