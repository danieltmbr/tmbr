import Vapor
import Foundation

struct PostPayload: Decodable, Sendable {
    
    let title: String
    
    let body: String?
    
    let state: Post.State
    
    let _csrf: String?
    
    init(
        title: String = "",
        body: String? = nil,
        state: Post.State = .draft,
        _csrf: String? = nil
    ) {
        self.title = title
        self.body = body
        self.state = state
        self._csrf = _csrf
    }
}
