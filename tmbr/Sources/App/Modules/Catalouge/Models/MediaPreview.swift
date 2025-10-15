import Fluent
import Vapor

extension Media {
    
    final class Preview: Fields, Codable, @unchecked Sendable {
        
        @Field(key: "title")
        var title: String
        
        @OptionalField(key: "subtitle")
        var subtitle: String?
        
        @OptionalField(key: "body")
        var body: String?
        
        @OptionalField(key: "image_url")
        var imageURL: String?
        
        init() {
            self.title = ""
            self.subtitle = nil
            self.body = nil
            self.imageURL = nil
        }
        
        init(
            title: String,
            subtitle: String? = nil,
            body: String? = nil,
            imageURL: String? = nil
        ) {
            self.title = title
            self.subtitle = subtitle
            self.body = body
            self.imageURL = imageURL
        }
    }
}
