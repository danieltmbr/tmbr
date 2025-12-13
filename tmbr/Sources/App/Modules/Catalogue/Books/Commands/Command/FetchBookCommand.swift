import Vapor
import Core

extension CommandFactory<FetchParameters<BookID>, Book> {
    
    static var fetchBook: Self {
        CommandFactory { request in
            PlainCommand.fetch(
                database: request.commandDB,
                readPermission: request.permissions.books.access,
                writePermission: request.permissions.books.edit,
                load: \.$cover, \.$owner, \.$post
            )
            .logged(name: "Fetch Book", logger: request.logger)
        }
    }
}
