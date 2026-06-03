import Vapor
import Core

struct CatalogueListViewModel: Encodable, Sendable {

    let compose: ComposePopupViewModel?

    let panels: [FilterPanelViewModel]

    let term: String?

    let previews: [PreviewViewModel]

    init(
        compose: ComposePopupViewModel?,
        panels: [FilterPanelViewModel] = [],
        term: String?,
        previews: [PreviewViewModel]
    ) {
        self.compose = compose
        self.panels = panels
        self.term = term
        self.previews = previews
    }
}
