import SwiftUI

public extension EnvironmentValues {
    @Entry var selectQuoteSources: SelectQuoteSourcesAction = SelectQuoteSourcesAction()
    @Entry var searchQuotes: QuotesSearchAction = QuotesSearchAction()
    @Entry var loadQuotes: QuotesPageLoadAction = QuotesPageLoadAction()
}
