import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

final class FetchBookCommand: FetchCommand<Book>, @unchecked Sendable {
    
    override func execute(_ params: FetchParameters<FetchCommand<Book>.ItemID>) async throws -> Book {
        let book = try await super.execute(params)
        async let cover: Void = book.$cover.load(on: database)
        async let notes = book.$bookNotes.load(on: database, include: \.$note)
        async let owner: Void = book.$owner.load(on: database)
        async let post: Void = book.$post.load(on: database)
        _ = try await (cover, owner, notes, post)
        return book
    }
}

extension CommandFactory<FetchParameters<BookID>, Book> {
    
    static var fetchBook: Self {
        CommandFactory { request in
            FetchBookCommand(
                database: request.commandDB,
                readPermission: request.permissions.books.access,
                writePermission: request.permissions.books.edit
            )
            .logged(logger: request.logger)
        }
    }
}
