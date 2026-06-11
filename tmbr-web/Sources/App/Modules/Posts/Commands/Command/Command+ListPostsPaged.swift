import Foundation
import Vapor
import Core
import Fluent
import TmbrCore

extension Command where Self == PlainCommand<PageInput, [Post]> {

    static func listPostsPaged(database: Database, preferredLanguages: Set<String>?) -> Self {
        PlainCommand { input in
            let languages = preferredLanguages?.compactMap(Language.init(rawValue:))
            let query = Post.query(on: database)
                .filter(\.$state == .published)
                .languages(languages)
                .sort(\.$createdAt, .descending)
                .with(\.$author)
                .with(\.$attachment) { attachment in attachment.with(\.$image) }
            query.page(input)
            return try await query.all()
        }
    }
}

extension CommandFactory<PageInput, [Post]> {

    static var listPostsPaged: Self {
        CommandFactory { request in
            .listPostsPaged(
                database: request.commandDB,
                preferredLanguages: request.languagePreference
            )
            .logged(name: "List posts paged", logger: request.logger)
        }
    }
}
