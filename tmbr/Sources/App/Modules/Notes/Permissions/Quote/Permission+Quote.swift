import Foundation
import Core
import AuthKit
import Vapor
import Fluent

extension Permission<Quote> {
    
    static var accessQuote: Permission<Quote> {
        Permission<Quote>(
            "Only quotes from public notes can be accessed by other than its author."
        ) { user, quote in
            if quote.note.access == .public { return true }
            guard let user else { throw Abort(.unauthorized) }
            return quote.note.author.id == user.userID || user.role == .admin
        }
    }
}

extension Permission<QueryBuilder<Quote>> {

    static var queryQuote: Permission<QueryBuilder<Quote>> {
        Permission<QueryBuilder<Quote>> { user, query in
            query
                .join(Note.self, on: \Quote.$note.$id == \Note.$id)
                .group(.or) { group in
                    group.filter(Note.self, \.$access == .public)
                    if let userID = user?.id {
                        group.filter(Note.self, \.$author.$id == userID)
                    }
                }
        }
    }
}
