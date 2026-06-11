import Fluent
import TmbrCore

struct DeletionMiddleware<M: Model>: AsyncModelMiddleware {

    let deletionType: DeletionType
    let itemID: @Sendable (M) -> String?

    func delete(model: M, force: Bool, on db: any Database, next: any AnyAsyncModelResponder) async throws {
        try await next.delete(model, force: force, on: db)
        guard let id = itemID(model) else { return }
        try await Deletion(type: deletionType, itemID: id).create(on: db)
    }
}
