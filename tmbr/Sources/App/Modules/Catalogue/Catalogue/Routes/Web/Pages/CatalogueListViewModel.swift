import Vapor
import Core

struct CatalogueListViewModel: Encodable, Sendable {
    let compose: ComposePopupViewModel?
    let term: String?
    let previews: [PreviewViewModel]
}
