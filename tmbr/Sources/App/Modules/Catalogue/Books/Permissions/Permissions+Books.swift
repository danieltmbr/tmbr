import AuthKit
import Fluent

extension PermissionScopes {
    var books: PreviewablePermissionScope<Book>.Type { PreviewablePermissionScope<Book>.self }
}

extension PreviewablePermissionScope<Book> {
    static var books: Self {
        PreviewablePermissionScope(
            access: .access("This book is private."),
            create: .create("You don't have permission to create a book."),
            delete: .delete("Only its owner can delete a book."),
            edit: .edit("Only its owner can edit a book."),
            query: .query(
                access: \.$access,
                owner: \.$owner.$id
            )
        )
    }
}
