import Foundation

extension MediaPayload {
        
    struct Book: Decodable, Sendable {
        
        private let goodreads: Resource?
        
        var resources: [MediaResource<App.Book>] {
            [goodreads?.resource(platform: .goodreads)].compactMap(\.self)
        }
    }
}
