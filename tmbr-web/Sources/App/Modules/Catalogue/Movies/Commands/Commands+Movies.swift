import Foundation
import Core
import TmbrCore

extension Commands {
    var movies: Commands.Movies.Type { Commands.Movies.self }
}

extension Commands {

    struct Movies: CommandCollection, Sendable {

        let create: CommandFactory<MovieInput, Movie>

        let delete: CommandFactory<MovieID, Void>

        let edit: CommandFactory<EditMovieInput, Movie>

        let fetch: CommandFactory<FetchParameters<MovieID>, Movie>

        let list: CommandFactory<PageInput, [Movie]>

        let lookup: CommandFactory<String, Movie?>

        let metadata: CommandFactory<URL, MovieMetadata>

        let search: CommandFactory<String?, MovieSearchResult>

        init(
            create: CommandFactory<MovieInput, Movie> = .createMovie,
            delete: CommandFactory<MovieID, Void> = .delete(\.movies),
            edit: CommandFactory<EditMovieInput, Movie> = .editMovie,
            fetch: CommandFactory<FetchParameters<MovieID>, Movie> = .fetchMovie,
            list: CommandFactory<PageInput, [Movie]> = .listMovies,
            lookup: CommandFactory<String, Movie?> = .lookupMovie,
            metadata: CommandFactory<URL, MovieMetadata> = .fetchMovieMetadata,
            search: CommandFactory<String?, MovieSearchResult> = .searchMovies
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.list = list
            self.lookup = lookup
            self.metadata = metadata
            self.search = search
        }
    }
}
