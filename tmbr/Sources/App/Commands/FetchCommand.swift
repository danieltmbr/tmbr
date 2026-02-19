import Foundation
import Vapor
import Core
import Fluent
import AuthKit

struct FetchPermissionInput<Item: Sendable>: Sendable {
    let item: Item
    let reason: FetchReason
}

extension PlainCommand where Output: Model, Input == FetchParameters<Output.IDValue> {

    static func fetch(
        database: Database,
        permission: ErasedPermissionResolver<FetchPermissionInput<Output>>,
        eagerLoad: @escaping @Sendable (Output, Database) async throws -> Void
    ) -> Self {
        PlainCommand { params in
            guard let item = try await Output.find(params.itemID, on: database) else {
                throw Abort(.notFound, reason: "\(Output.self) not found")
            }
            try await permission.grant(FetchPermissionInput(item: item, reason: params.reason))
            try await eagerLoad(item, database)
            return item
        }
    }

    static func fetch(
        database: Database,
        readPermission: BasePermissionResolver<Output>,
        writePermission: AuthPermissionResolver<Output>
    ) -> Self {
        self.fetch(
            database: database,
            permission: ErasedPermissionResolver(input: { $0.item }, condition: { $0.reason }) { reason in
                switch reason {
                case .read: readPermission.eraseOutput()
                case .write: writePermission.eraseOutput()
                }
            },
            eagerLoad: { model, db in }
        )
    }

    static func fetch<each Property>(
        database: Database,
        readPermission: BasePermissionResolver<Output>,
        writePermission: AuthPermissionResolver<Output>,
        load properties: repeat KeyPath<Output, each Property>
    ) -> Self
    where repeat (each Property): AsyncLoadable {
        self.fetch(
            database: database,
            permission: ErasedPermissionResolver(input: { $0.item }, condition: { $0.reason }) { reason in
                switch reason {
                case .read: readPermission.eraseOutput()
                case .write: writePermission.eraseOutput()
                }
            },
            eagerLoad: { model, db in
                // FIXME: this crashes the compiler... so fall back to sequential execution
                // try await withThrowingTaskGroup(of: Void.self) { group in
                //     repeat group.addTask {
                //         try await model[keyPath: (each properties)].load(on: db)
                //     }
                //     for try await _ in group {}
                // }
                try await (repeat model[keyPath: (each properties)].load(on: db))
            }
        )
    }
}
