import AuthKit

extension PermissionScopes {
    var gallery: PermissionScopes.Gallery.Type { PermissionScopes.Gallery.self }
}

extension PermissionScopes {
    struct Gallery: PermissionScope, Sendable {
        
        let create: AuthPermission<Void>
        
        let delete: AuthPermission<Image>
        
        let list: AuthPermission<Void>

        init(
            create: AuthPermission<Void> = .createImage,
            delete: AuthPermission<Image> = .deleteImage,
            list: AuthPermission<Void> = .listImages
        ){
            self.create = create
            self.delete = delete
            self.list = list
        }
    }
}
