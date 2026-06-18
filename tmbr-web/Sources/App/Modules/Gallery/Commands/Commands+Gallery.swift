import Foundation
import CoreWeb
import CoreTmbr

extension Commands {
    var gallery: Commands.Gallery.Type { Commands.Gallery.self }
}

extension Commands {
    struct Gallery: CommandCollection, Sendable {

        let add: CommandFactory<ImageUploadPayload, Image>

        let addFromURL: CommandFactory<ImageURLPayload, Image>

        let delete: CommandFactory<ImageID, Void>

        let edit: CommandFactory<EditImageInput, Image>

        let fetch: CommandFactory<FetchParameters<ImageID>, Image>

        let list: CommandFactory<Void, [Image]>

        let lookup: CommandFactory<String, Image?>

        let resource: CommandFactory<String, ImageResource>

        init(
            add: CommandFactory<ImageUploadPayload, Image> = .addImage,
            addFromURL: CommandFactory<ImageURLPayload, Image> = .addImageFromURL,
            delete: CommandFactory<ImageID, Void> = .deleteImage,
            edit: CommandFactory<EditImageInput, Image> = .editImage,
            fetch: CommandFactory<FetchParameters<ImageID>, Image> = .fetchImage,
            list: CommandFactory<Void, [Image]> = .listImages,
            lookup: CommandFactory<String, Image?> = .lookupImage,
            resource: CommandFactory<String, ImageResource> = .fetchResource
        ) {
            self.add = add
            self.addFromURL = addFromURL
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.list = list
            self.lookup = lookup
            self.resource = resource
        }
    }
}


