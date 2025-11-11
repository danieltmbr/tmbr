import Foundation
import Core

extension Commands {
    var gallery: Commands.Gallery.Type { Commands.Gallery.self }
}

extension Commands {
    struct Gallery: CommandCollection, Sendable {
                
        let add: CommandFactory<ImageUploadPayload, Image>
        
        let delete: CommandFactory<ImageID, Void>

        let fetch: CommandFactory<ImageID, Image>
        
        let list: CommandFactory<Void, [Image]>
        
        let resource: CommandFactory<String, ImageResource>
        
        init(
            add: CommandFactory<ImageUploadPayload, Image> = .addImage,
            delete: CommandFactory<ImageID, Void> = .deleteImage,
            fetch: CommandFactory<ImageID, Image> = .fetchImage,
            list: CommandFactory<Void, [Image]> = .listImages,
            resource: CommandFactory<String, ImageResource> = .fetchResource
        ) {
            self.add = add
            self.delete = delete
            self.fetch = fetch
            self.list = list
            self.resource = resource
        }
    }
}


