import Foundation
import CoreWeb
import CoreAuth
import Vapor

extension AuthPermission<Void> {
    static var signOut: AuthPermission<Void> {
        AuthPermission<Void>()
    }
}
