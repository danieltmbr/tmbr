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
        
        let document = Document(parsing: note.body)
        let quotes = document.quotes.map { Quote(noteID: id, body: $0) }
        try await quotes.create(on: db)
    }
}
