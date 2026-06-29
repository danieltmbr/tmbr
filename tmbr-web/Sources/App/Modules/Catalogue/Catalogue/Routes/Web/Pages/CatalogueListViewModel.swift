import Vapor
import WebCore

struct CatalogueListViewModel: Encodable, Sendable {

    let pageTitle: String

    let compose: ComposePopupViewModel?

    let panels: [FilterPanelViewModel]

    let term: String?

    let previews: [PreviewViewModel]

    init(
        pageTitle: String,
        compose: ComposePopupViewModel?,
        panels: [FilterPanelViewModel] = [],
        term: String?,
        previews: [PreviewViewModel]
    ) {
        self.pageTitle = pageTitle
        self.compose = compose
        self.panels = panels
        self.term = term
        self.previews = previews
    }
}
