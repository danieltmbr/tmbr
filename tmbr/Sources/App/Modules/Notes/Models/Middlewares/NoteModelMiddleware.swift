import Fluent
import Vapor
import Markdown
import Core

struct NoteModelMiddleware: AsyncModelMiddleware {
    
    func create(model: Note, on db: any Database, next: any AnyAsyncModelResponder) async throws {
        try await next.create(model, on: db)
        try await rematerializeQuotes(for: model, on: db)
    }
    
    func update(model: Note, on db: any Database, next: any AnyAsyncModelResponder) async throws {
        try await next.update(model, on: db)
        try await rematerializeQuotes(for: model, on: db)
    }
    
    func delete(model: Note, force: Bool, on db: any Database, next: any AnyAsyncModelResponder) async throws {
        try await next.delete(model, force: force, on: db)
        guard let id = model.id else { return }
        try await Quote.query(on: db)
            .filter(\.$note.$id == id)
            .delete()
    }
    
    private func rematerializeQuotes(for note: Note, on db: any Database) async throws {
        guard let id = note.id else { return }

        try await Quote.query(on: db)
            .filter(\.$note.$id == id)
            .delete()

        for quote in Document(parsing: note.body).quotes {
            // TODO: Populate Source based on Note attachment
            let q = Quote(noteID: id, body: quote)
            try await q.save(on: db)
        }
    }
}
