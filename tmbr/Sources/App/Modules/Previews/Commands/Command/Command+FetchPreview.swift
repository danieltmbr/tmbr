import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct FetchPreviewCommand: Command {
    
    typealias PermissionInput = (preview: Preview, reason: FetchReason)
    
    typealias Input = FetchParameters<PreviewID>
    
    typealias Output = Preview
    
    private let database: Database
            
    private let permission: ErasedPermissionResolver<PermissionInput>

    init(
        database: Database,
        permission: ErasedPermissionResolver<PermissionInput>
    ) {
        self.database = database
        self.permission = permission
    }
    
    init(
        database: Database,
        readPermission: BasePermissionResolver<Preview>,
        writePermission: AuthPermissionResolver<Preview>
    ) {
        self.init(
            database: database,
            permission: ErasedPermissionResolver(input: \.preview, condition: \.reason) { reason in
                switch reason {
                case .read: readPermission.eraseOutput()
                case .write: writePermission.eraseOutput()
                }
            }
        )
    }
    
    func execute(_ params: FetchParameters<PreviewID>) async throws -> Preview {
        guard let preview = try await Preview.find(params.itemID, on: database) else {
            throw Abort(.notFound, reason: "Post not found")
        }
        try await preview.$parentOwner.load(on: database)
        try await permission.grant((preview, params.reason))
        try await preview.$image.load(on: database)
        return preview
    }
}

extension CommandFactory<FetchParameters<PreviewID>, Preview> {
    
    static var fetchPreview: Self {
        CommandFactory { request in
            FetchPreviewCommand(
                database: request.commandDB,
                readPermission: request.permissions.previews.access,
                writePermission: request.permissions.previews.edit
            )
            .logged(logger: request.logger)
        }
    }
}
