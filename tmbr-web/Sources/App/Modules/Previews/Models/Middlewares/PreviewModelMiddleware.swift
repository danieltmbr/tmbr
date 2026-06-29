import Fluent
import Vapor
import Foundation
import WebAuth
import TmbrCore

protocol Previewable: Model, Timestamped where IDValue == Int {

    static var previewType: String { get }

    var access: Access { get }

    var ownerID: UserID { get }

    var preview: Preview { get }
}

extension Previewable {
    var createdAt: Date { preview.createdAt }
}

final class PreviewModelMiddleware<M: Previewable>: AsyncModelMiddleware {

    private let attach: @Sendable (PreviewID, M) throws -> Void

    private let configure: @Sendable (inout Preview, M) throws -> Void

    private let fetch: @Sendable (M, Database) async throws -> Preview

    private let previewID: @Sendable (M) -> PreviewID?

    init(
        attach: @escaping @Sendable (PreviewID, M) throws -> Void,
        configure: @escaping @Sendable (inout Preview, M) throws -> Void,
        fetch: @escaping @Sendable (M, Database) async throws -> Preview,
        previewID: @escaping @Sendable (M) -> PreviewID? = { _ in nil }
    ) {
        self.attach = attach
        self.configure = configure
        self.fetch = fetch
        self.previewID = previewID
    }

    func create(
        model: M,
        on db: any Database,
        next: any AnyAsyncModelResponder
    ) async throws {
        let catalogueCategory = try await CatalogueCategory.query(on: db)
            .filter(\.$slug == M.previewType)
            .first()
        guard let categoryID = catalogueCategory?.id else {
            throw Abort(.internalServerError, reason: "No CatalogueCategory found for type '\(M.previewType)'")
        }
        if let adoptingID = previewID(model) {
            try attach(adoptingID, model)
            try await next.create(model, on: db)
            guard var preview = try await Preview.find(adoptingID, on: db) else {
                throw Abort(.notFound, reason: "Orphan preview not found for adoption")
            }
            preview.adopt(
                parentID: try model.requireID(),
                categoryID: categoryID,
                parentAccess: model.access,
                parentOwner: model.ownerID
            )
            try configure(&preview, model)
            try await preview.save(on: db)
        } else {
            let newID = UUID()
            try attach(newID, model)
            try await next.create(model, on: db)
            var preview = Preview(
                id: newID,
                parentID: try model.requireID(),
                parentAccess: model.access,
                parentOwner: model.ownerID,
                categoryID: categoryID
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

