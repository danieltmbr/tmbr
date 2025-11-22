import AuthKit

extension PermissionScopes {
    var gallery: PermissionScopes.Gallery.Type { PermissionScopes.Gallery.self }
}

extension PermissionScopes {
    struct Gallery: PermissionScope, Sendable {
        
        let access: AuthPermission<Image>
        
        let create: AuthPermission<Void>
        
        let delete: AuthPermission<Image>
        
        let edit: AuthPermission<Image>
                
        let list: AuthPermission<Void>

        init(
            access: AuthPermission<Image> = .accessImage,
            create: AuthPermission<Void> = .createImage,
            delete: AuthPermission<Image> = .deleteImage,
            edit: AuthPermission<Image> = .editImage,
            list: AuthPermission<Void> = .listImages
        ){
            self.access = access
            self.create = create
            self.delete = delete
            self.edit = edit
            self.list = list
        }
    }
}
