import Foundation
import Vapor
import WebCore
import Logging
import Fluent
import WebAuth

typealias EditBookInput = EditInput<Book, BookInput>

extension CommandFactory<EditBookInput, Book> {
    
    static var editBook: Self {
        CommandFactory { request in
            PlainCommand.edit(
                configure: .book,
                database: request.commandDB,
                permission: request.permissions.books.edit,
                queryNotes: request.commands.notes.query,
                validate: .book
            )
            .logged(name: "Edit Book Command", logger: request.logger)
        }
    }
}
