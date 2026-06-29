import Vapor
import WebCore
import TmbrCore

extension CommandFactory<FetchParameters<BookID>, Book> {
    
    static var fetchBook: Self {
        CommandFactory { request in
            PlainCommand.fetch(
                database: request.commandDB,
                readPermission: request.permissions.books.access,
                writePermission: request.permissions.books.edit,
                load: \.$cover, \.$owner, \.$post, \.$preview,
                then: { book, db in
                    try await book.preview.$image.load(on: db)
                    try await book.preview.$catalogueCategory.load(on: db)
                }
            )
            .logged(name: "Fetch Book", logger: request.logger)
        }
    }
}
