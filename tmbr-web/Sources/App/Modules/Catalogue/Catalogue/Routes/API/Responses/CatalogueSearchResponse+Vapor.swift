import TmbrCore
import Vapor

extension CatalogueSearchResponse: @retroactive Content {}
extension CatalogueSearchResponse: @retroactive AsyncResponseEncodable {}
