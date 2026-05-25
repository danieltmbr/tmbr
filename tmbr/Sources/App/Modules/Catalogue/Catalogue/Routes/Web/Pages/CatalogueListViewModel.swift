import Vapor
import Core

struct CatalogueListViewModel: Encodable, Sendable {
    
    let compose: ComposePopupViewModel?
    
    let filterItems: [FilterItemViewModel]
    
    let term: String?
    
    let previews: [PreviewViewModel]

    init(
        compose: ComposePopupViewModel?,
        filterItems: [FilterItemViewModel] = [],
        term: String?,
        previews: [PreviewViewModel]
    ) {
        self.compose = compose
        self.filterItems = filterItems
        self.term = term
        self.previews = previews
    }
}
