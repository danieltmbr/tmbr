import Foundation
import Core
import AuthKit
import Vapor

extension AuthPermission<Void> {
    static var createImage: AuthPermission<Void> {
        AuthPermission<Void>()
    }
    
    static var listImages: AuthPermission<Void> {
        AuthPermission<Void>()
    }
}

extension AuthPermission<Image> {
    static var deleteImage: AuthPermission<Image> {
        AuthPermission<Image>(
            "Only its owner can delete an image."
        ) { user, image in
            image.$owner.id == user.userID || user.role == .admin
        }
    }
}
