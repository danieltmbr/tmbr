import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

extension Command where Self == PlainCommand<String, ImageResource> {
    static func fetchResource(storage: ImageService) -> Self {
        PlainCommand { key in
            async let data = storage.image(for: key)
            async let mediaType = storage.contentType(for: key).httpType
            return ImageResource(
                mediaType: try await mediaType,
                data: try await data
            )
        }
    }
}

extension CommandFactory<String, ImageResource> {
    
    static var fetchResource: Self {
        CommandFactory { request in
            .fetchResource(
                storage: request.application.imageService!
            )
            .logged(name: "Fetch Image Resource", logger: request.logger)
        }
    }
}
