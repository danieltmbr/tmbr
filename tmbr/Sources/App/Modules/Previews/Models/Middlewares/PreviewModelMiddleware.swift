import Fluent
import Vapor
import Foundation
import AuthKit

protocol Previewable: Model where IDValue == Int {

    static var previewType: String { get }

    var access: Access { get }

    var ownerID: UserID { get }
}

final class PreviewModelMiddleware<M: Previewable>: AsyncModelMiddleware {

    private let readPreviewID: @Sendable (M) -> PreviewID?

    private let attach: @Sendable (PreviewID, M) throws -> Void

    private let configure: @Sendable (inout Preview, M) throws -> Void

    private let fetch: @Sendable (M, Database) async throws -> Preview

    init(
        readPreviewID: @escaping @Sendable (M) -> PreviewID? = { _ in nil },
        attach: @escaping @Sendable (PreviewID, M) throws -> Void,
        configure: @escaping @Sendable (inout Preview, M) throws -> Void,
        fetch: @escaping @Sendable (M, Database) async throws -> Preview
    ) {
        self.readPreviewID = readPreviewID
        self.attach = attach
        self.configure = configure
        self.fetch = fetch
    }

    func create(
        model: M,
        on db: any Database,
        next: any AnyAsyncModelResponder
    ) async throws {
        if let adoptingID = readPreviewID(model) {
            try await next.create(model, on: db)
            guard var preview = try await Preview.find(adoptingID, on: db) else {
                throw Abort(.notFound, reason: "Orphan preview not found for adoption")
            }
            preview.adopt(
                parentID: try model.requireID(),
                parentType: M.previewType,
                parentAccess: model.access,
                parentOwner: model.ownerID
            )
            try configure(&preview, model)
            try await preview.save(on: db)
        } else {
            let previewID = UUID()
            try attach(previewID, model)
            try await next.create(model, on: db)
            var preview = Preview(
                id: previewID,
                parentID: try model.requireID(),
                parentAccess: model.access,
                parentOwner: model.ownerID,
                parentType: M.previewType
            )
            try configure(&preview, model)
            try await preview.save(on: db)
        }
    }

    func update(
        model: M,
        on db: any Database,
        next: any AnyAsyncModelResponder
    ) async throws {
        try await next.update(model, on: db)
        var preview = try await fetch(model, db)
        try configure(&preview, model)
        try await preview.save(on: db)
    }
    
    func delete(
        model: M,
        force: Bool,
        on db: any Database,
        next: any AnyAsyncModelResponder
    ) async throws {
        let preview = try await fetch(model, db)
        try await next.delete(model, force: force, on: db)
        try await preview.delete(on: db)
    }
}

