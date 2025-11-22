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
    
    static var accessImage: AuthPermission<Image> {
        AuthPermission<Image>(
            "Only logged in users can see images."
        ) { _, _ in
            true
        }
    }
    
    static var deleteImage: AuthPermission<Image> {
        AuthPermission<Image>(
            "Only its owner can delete an image."
        ) { user, image in
            image.$owner.id == user.userID || user.role == .admin
        }
    }
    
    static var editImage: AuthPermission<Image> {
        AuthPermission<Image>(
            "Only its owner can update an image."
        ) { user, image in
            image.$owner.id == user.userID || user.role == .admin
        }
    }
}
