import Foundation
import Core

extension Commands {
    var quotes: Commands.Quotes.Type { Commands.Quotes.self }
}

extension Commands {
    struct Quotes: CommandCollection, Sendable {
                
        let list: CommandFactory<QuoteQueryPayload, [Quote]>
        
        let random: CommandFactory<QuoteQueryPayload, Quote>
                
        let search: CommandFactory<QuoteQueryPayload, [Quote]>
        
        init(
            list: CommandFactory<QuoteQueryPayload, [Quote]> = .listQuotes,
            random: CommandFactory<QuoteQueryPayload, Quote> = .randomQuote,
            search: CommandFactory<QuoteQueryPayload, [Quote]> = .searchQuote
        ) {
            self.list = list
            self.random = random
            self.search = search
        }
    }
}
