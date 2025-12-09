import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct EditBookInput {
    
    fileprivate let id: BookID
    
    fileprivate let book: BookInput
    
    init(id: BookID, book: BookInput) {
        self.id = id
        self.book = book
    }
    
    fileprivate func validate() throws {
        try book.validate()
    }
}

struct EditBookCommand: Command {
    
    private let configure: BookConfiguration
    
    private let database: Database

    private let permission: AuthPermissionResolver<Book>
    
    init(
        configure: BookConfiguration = .default,
        database: Database,
        permission: AuthPermissionResolver<Book>
    ) {
        self.configure = configure
        self.database = database
        self.permission = permission
    }
    
    func execute(_ input: EditBookInput) async throws -> Book {
        guard let book = try await Book.find(input.id, on: database) else {
            throw Abort(.notFound, reason: "Book not found")
        }
        try await permission.grant(book)
        try input.validate()
        configure(book, with: input.book)
        
        try await database.transaction { db in
            try await book.save(on: db)
            if book.access == .private {
                try await book.$bookNotes.load(on: db, include: \.$note)
                book.notes.forEach { $0.access = $0.access && book.access }
                try await book.notes.update(on: db)
            }
        }
        return book
    }
}

extension CommandFactory<EditBookInput, Book> {
    
    static var editBook: Self {
        CommandFactory { request in
            EditBookCommand(
                database: request.application.db,
                permission: request.permissions.books.edit
            )
            .logged(logger: request.logger)
        }
    }
}

extension CommandResolver where Input == EditBookInput {
    
    func callAsFunction(
        _ bookID: BookID,
        with payload: BookPayload
    ) async throws -> Output {
        let input = EditBookInput(
            id: bookID,
            book: BookInput(payload: payload)
        )
        return try await self.callAsFunction(input)
    }
}
