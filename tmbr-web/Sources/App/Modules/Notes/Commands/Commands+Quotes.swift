import Foundation
import WebCore
import TmbrCore

extension Commands {
    var quotes: Commands.Quotes.Type { Commands.Quotes.self }
}

extension Commands {
    struct Quotes: CommandCollection, Sendable {

        let list: CommandFactory<ListQuotesInput, [Quote]>

        let random: CommandFactory<QuoteQueryPayload, Quote>

        let fetch: CommandFactory<QuoteID, Quote>

        init(
            list: CommandFactory<ListQuotesInput, [Quote]> = .listQuotes,
            random: CommandFactory<QuoteQueryPayload, Quote> = .randomQuote,
            fetch: CommandFactory<QuoteID, Quote> = .fetchQuote
        ) {
            self.list = list
            self.random = random
            self.fetch = fetch
        }
    }
}
