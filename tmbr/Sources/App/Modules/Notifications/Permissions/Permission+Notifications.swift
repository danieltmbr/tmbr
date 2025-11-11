import Foundation
import Core
import AuthKit
import Vapor

extension AuthPermission<PushNotification> {
    
    /// Permission to send any kind of notification to all subscribers.
    ///
    static var genericNotification: AuthPermission<PushNotification> {
        AuthPermission<PushNotification>.init(
            "Only admins can send out generic notifications."
        ) { user, _ in
            user.role == .admin
        }
    }
}


extension AuthPermission<Post> {
    /// Permission to send notifications about a post to all subscribers.
    ///
    static var postNotification: AuthPermission<Post> {
        AuthPermission<Post>(
            "Only its owner can send push notification updates about a post."
        ) { user, post in
            post.$author.id == user.userID || user.role == .admin
        }
    }
}
