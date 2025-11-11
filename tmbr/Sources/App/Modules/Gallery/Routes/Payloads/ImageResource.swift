import Foundation
import Vapor

struct ImageResource: Sendable {
    var contentLenght: Int { data.count }
    
    let mediaType: HTTPMediaType
    
    let data: Data
}
