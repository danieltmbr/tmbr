import Foundation
import Core

extension Commands {
    var movies: Commands.Movies.Type { Commands.Movies.self }
}

extension Commands {
    
    struct Movies: CommandCollection, Sendable {
        
        let create: CommandFactory<CreateMovieInput, Movie>
        
        let delete: CommandFactory<MovieID, Void>
        
        let edit: CommandFactory<EditMovieInput, Movie>
        
        let fetch: CommandFactory<FetchParameters<MovieID>, Movie>
        
        init(
            create: CommandFactory<CreateMovieInput, Movie> = .createMovie,
            delete: CommandFactory<MovieID, Void> = .delete(\.movies),
            edit: CommandFactory<EditMovieInput, Movie> = .editMovie,
            fetch: CommandFactory<FetchParameters<MovieID>, Movie> = .fetchMovie
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
        }
    }
}
