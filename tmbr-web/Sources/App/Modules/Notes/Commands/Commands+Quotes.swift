import Foundation
import WebCore
import TmbrCore

extension Commands {
    var quotes: Commands.Quotes.Type { Commands.Quotes.self }
}

extension Commands {
    struct Quotes: CommandCollection, Sendable {

        let list: CommandFactory<QuoteQueryPayload, [Quote]>

        let random: CommandFactory<QuoteQueryPayload, Quote>

        let search: CommandFactory<QuoteQueryPayload, [Quote]>

        let fetch: CommandFactory<QuoteID, Quote>

        init(
            list: CommandFactory<QuoteQueryPayload, [Quote]> = .listQuotes,
            random: CommandFactory<QuoteQueryPayload, Quote> = .randomQuote,
            search: CommandFactory<QuoteQueryPayload, [Quote]> = .searchQuote,
            fetch: CommandFactory<QuoteID, Quote> = .fetchQuote
        ) {
            self.list = list
            self.random = random
            self.search = search
            self.fetch = fetch
        }
    }
}
