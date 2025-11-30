import Foundation
import Core
import AuthKit
import Vapor

extension Permission<Image> {
    
    static var accessQuote: Permission<Quote> {
        Permission<Quote>(
            "Only quotes from public notes can be accessed by other than its author."
        ) { user, quote in
            if quote.note.visibility == .public { return true }
            guard let user else { throw Abort(.unauthorized) }
            return quote.note.author.id == user.userID || user.role == .admin
        }
    }
}
