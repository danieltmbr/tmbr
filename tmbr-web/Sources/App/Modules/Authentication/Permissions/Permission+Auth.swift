import Foundation
import WebCore
import WebAuth
import Vapor

extension AuthPermission<Void> {
    static var signOut: AuthPermission<Void> {
        AuthPermission<Void>()
    }
}
