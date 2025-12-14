import Foundation
import Vapor
import AuthKit
import Core

struct MovieInput {
    
    fileprivate let access: Access
        
    fileprivate let cover: ImageID?
    
    fileprivate let director: String?
    
    fileprivate let genre: String?
        
    fileprivate let releaseDate: Date
    
    fileprivate let resourceURLs: [String]
    
    fileprivate let title: String
    
    init(
        access: Access,
        cover: ImageID?,
        director: String?,
        genre: String?,
        releaseDate: Date,
        resourceURLs: [String],
        title: String
    ) {
        self.access = access
        self.cover = cover
        self.director = director
        self.genre = genre
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.title = title
    }
    
    init(payload: MoviePayload) {
        self.init(
            access: payload.access,
            cover: payload.cover,
            director: payload.director,
            genre: payload.genre,
            releaseDate: payload.releaseDate,
            resourceURLs: payload.resourceURLs,
            title: payload.title
        )
    }
}

extension ModelConfiguration where Model == Movie, Parameters == MovieInput {
    
    static var movie: Self {
        ModelConfiguration { movie, input in
            movie.access = input.access
            movie.$cover.id = input.cover
            movie.director = input.director
            movie.genre = input.genre
            movie.releaseDate = input.releaseDate
            movie.resourceURLs = input.resourceURLs
            movie.title = input.title
        }
    }
}

extension Validator where Input == MovieInput {
    
    static var movie: Self {
        Validator { movie in
            guard !movie.title.trimmed.isEmpty else {
                throw Abort(.badRequest, reason: "The movie author or title is missing")
            }

        }
    }
}
