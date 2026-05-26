import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct CreateBookCommand: Command {
    
    private let configure: ModelConfiguration<Book, BookInput>
    
    private let database: Database
        
    private let permission: AuthPermissionResolver<Void>
    
    private let validate: Validator<BookInput>

    init(
        configure: ModelConfiguration<Book, BookInput>,
        database: Database,
        permission: AuthPermissionResolver<Void>,
        validate: Validator<BookInput>
    ) {
        self.configure = configure
        self.database = database
        self.permission = permission
        self.validate = validate
    }

    func execute(_ input: BookInput) async throws -> Book {
        let user = try await permission.grant()
        try validate(input)

        var book = Book(owner: user.userID)
        configure(&book, with: input)
        try await book.save(on: database)
        
        return book
    }
}

extension CommandFactory<BookInput, Book> {

    static var createBook: Self {
        CommandFactory { request in
            CreateBookCommand(
                configure: .book,
                database: request.commandDB,
                permission: request.permissions.books.create,
                validate: .book
            )
            .logged(logger: request.logger)
        }
    }
}
