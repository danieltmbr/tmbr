import Foundation
import Core

extension Commands {
    var gallery: Commands.Gallery.Type { Commands.Gallery.self }
}

extension Commands {
    struct Gallery: CommandCollection, Sendable {
                
        let add: CommandFactory<ImageUploadPayload, Image>
        
        let delete: CommandFactory<ImageID, Void>
        
        let edit: CommandFactory<EditImageInput, Image>

        let fetch: CommandFactory<FetchParameters<ImageID>, Image>
        
        let list: CommandFactory<Void, [Image]>
        
        let resource: CommandFactory<String, ImageResource>
                
        init(
            add: CommandFactory<ImageUploadPayload, Image> = .addImage,
            delete: CommandFactory<ImageID, Void> = .deleteImage,
            edit: CommandFactory<EditImageInput, Image> = .editImage,
            fetch: CommandFactory<FetchParameters<ImageID>, Image> = .fetchImage,
            list: CommandFactory<Void, [Image]> = .listImages,
            resource: CommandFactory<String, ImageResource> = .fetchResource
        ) {
            self.add = add
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.list = list
            self.resource = resource
        }
    }
}


