import AuthKit

extension PermissionScopes {
    var quotes: PermissionScopes.Quotes.Type { PermissionScopes.Quotes.self }
}

extension PermissionScopes {
    struct Quotes: PermissionScope, Sendable {
        
        let access: Permission<Quote>
        
        init(
            access: Permission<Quote> = .accessQuote
        ) {
            self.access = access
        }
    }
}
