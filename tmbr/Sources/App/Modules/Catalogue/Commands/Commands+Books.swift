import Foundation
import Core

extension Commands {
    var books: Commands.Books.Type { Commands.Books.self }
}

extension Commands {
    
    struct Books: CommandCollection, Sendable {
        
        let create: CommandFactory<CreateBookInput, Book>
        
        let delete: CommandFactory<BookID, Void>
        
        let edit: CommandFactory<EditBookInput, Book>
        
        let fetch: CommandFactory<FetchParameters<BookID>, Book>
        
        init(
            create: CommandFactory<CreateBookInput, Book> = .createBook,
            delete: CommandFactory<BookID, Void> = .delete(\.books),
            edit: CommandFactory<EditBookInput, Book> = .editBook,
            fetch: CommandFactory<FetchParameters<BookID>, Book> = .fetchBook
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
        }
    }
}
