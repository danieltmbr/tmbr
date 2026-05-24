import AuthKit
import Fluent

extension PermissionScopes {
    var quotes: PermissionScopes.Quotes.Type { PermissionScopes.Quotes.self }
}

extension PermissionScopes {
    struct Quotes: PermissionScope, Sendable {
        
        let access: Permission<Quote>
        
        let query: Permission<QueryBuilder<Quote>>
        
        init(
            access: Permission<Quote> = .accessQuote,
            query: Permission<QueryBuilder<Quote>> = .queryQuote
        ) {
            self.access = access
            self.query = query
        }
    }
}
