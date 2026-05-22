import Vapor
import Core

struct CatalogueListViewModel: Encodable, Sendable {
    let compose: String?
    let term: String?
    let previews: [PreviewViewModel]
}
