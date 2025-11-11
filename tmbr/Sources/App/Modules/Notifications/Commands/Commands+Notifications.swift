import Foundation
import Core

extension Commands {
    var notifications: Commands.Notifications.Type { Commands.Notifications.self }
}

extension Commands {
    struct Notifications: CommandCollection, Sendable {
        
        let send: CommandFactory<PushNotification, Void>
        
        let post: CommandFactory<Post, Void>
        
        let postByID: CommandFactory<PostID, Void>
        
        init(
            send: CommandFactory<PushNotification, Void> = .send,
            post: CommandFactory<Post, Void> = .postNotification,
            postByID: CommandFactory<PostID, Void> = .postNotificationByID
        ) {
            self.send = send
            self.post = post
            self.postByID = postByID
        }
    }
}
