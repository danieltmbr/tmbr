import AuthKit
import Fluent

extension PermissionScopes {
    var books: PreviewablePermissionScope<Book>.Type { PreviewablePermissionScope<Book>.self }
    
    var movies: PreviewablePermissionScope<Movie>.Type { PreviewablePermissionScope<Movie>.self }
    
    var podcasts: PreviewablePermissionScope<Podcast>.Type { PreviewablePermissionScope<Podcast>.self }
    
    var songs: PreviewablePermissionScope<Song>.Type { PreviewablePermissionScope<Song>.self }
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

extension PreviewablePermissionScope<Movie> {
    static var movies: Self {
        PreviewablePermissionScope(
            access: .access("This movie is private."),
            create: .create("You don't have permission to create a movie."),
            delete: .delete("Only its owner can delete a movie."),
            edit: .edit("Only its owner can edit a movie."),
            query: .query(
                access: \.$access,
                owner: \.$owner.$id
            )
        )
    }
}

extension PreviewablePermissionScope<Podcast> {
    static var podcasts: Self {
        PreviewablePermissionScope(
            access: .access("This podcast is private."),
            create: .create("You don't have permission to create a podcast."),
            delete: .delete("Only its owner can delete a podcast."),
            edit: .edit("Only its owner can edit a podcast."),
            query: .query(
                access: \.$access,
                owner: \.$owner.$id
            )
        )
    }
}

extension PreviewablePermissionScope<Song> {
    static var songs: Self {
        PreviewablePermissionScope(
            access: .access("This song is private."),
            create: .create("You don't have permission to create a song."),
            delete: .delete("Only its owner can delete a song."),
            edit: .edit("Only its owner can edit a song."),
            query: .query(
                access: \.$access,
                owner: \.$owner.$id
            )
        )
    }
}
