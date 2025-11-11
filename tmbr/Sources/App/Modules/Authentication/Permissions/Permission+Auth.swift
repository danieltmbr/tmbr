import Foundation
import Core
import AuthKit
import Vapor

extension AuthPermission<Void> {
    static var signOut: AuthPermission<Void> {
        AuthPermission<Void>()
    }
}
