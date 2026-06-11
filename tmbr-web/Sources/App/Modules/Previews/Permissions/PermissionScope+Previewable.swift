import AuthKit
import Fluent
import Vapor
import Foundation



struct PreviewablePermissionScope<M>: PermissionScope, Sendable
where M: Model & Previewable {

    let access: Permission<M>

    let create: AuthPermission<Void>

    let delete: AuthPermission<M>

    let edit: AuthPermission<M>

    let list: AuthPermission<Void>

    let query: Permission<QueryBuilder<M>>

    init(
        access: Permission<M>,
        create: AuthPermission<Void>,
        delete: AuthPermission<M>,
        edit: AuthPermission<M>,
        list: AuthPermission<Void> = AuthPermission<Void>(),
        query: Permission<QueryBuilder<M>>
    ) {
        self.access = access
        self.create = create
        self.delete = delete
        self.edit = edit
        self.list = list
        self.query = query
    }
}
