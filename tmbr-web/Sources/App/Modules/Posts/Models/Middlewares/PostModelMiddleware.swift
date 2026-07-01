import Fluent
import Vapor
import Markdown
import WebCore

struct PostModelMiddleware: AsyncModelMiddleware {

    func create(model: Post, on db: any Database, next: any AnyAsyncModelResponder) async throws {
        try await next.create(model, on: db)
        try await rematerializeQuotes(for: model, on: db)
    }

    func update(model: Post, on db: any Database, next: any AnyAsyncModelResponder) async throws {
        try await next.update(model, on: db)
        try await rematerializeQuotes(for: model, on: db)
    }

    func delete(model: Post, force: Bool, on db: any Database, next: any AnyAsyncModelResponder) async throws {
        try await next.delete(model, force: force, on: db)
        guard let id = model.id else { return }
        try await Quote.query(on: db)
            .filter(\.$post.$id == id)
            .delete()
    }

    private func rematerializeQuotes(for post: Post, on db: any Database) async throws {
        guard let postID = post.id else { return }

        let existing = try await Quote.query(on: db)
            .filter(\.$post.$id == postID)
            .all()

        let freshBodies = Document(parsing: post.content).quotes

        let actions = QuoteReconciler.plan(
            existing: existing.compactMap { q in q.id.map { .init(id: $0, body: q.body) } },
            freshBodies: freshBodies
        )

        for (id, newBody) in actions.toUpdate {
            guard let quote = existing.first(where: { $0.id == id }) else { continue }
            quote.body = newBody
            try await quote.update(on: db)
        }
        for body in actions.toInsert {
            try await Quote(postID: postID, body: body).create(on: db)
        }
        for id in actions.toDelete {
            guard let quote = existing.first(where: { $0.id == id }) else { continue }
            try await quote.delete(on: db)
        }
    }
}
