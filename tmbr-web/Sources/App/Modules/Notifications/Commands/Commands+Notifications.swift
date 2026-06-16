import Foundation
import CoreWeb
import CoreTmbr

extension Commands {
    var notifications: Commands.Notifications.Type { Commands.Notifications.self }
}

extension Commands {
    struct Notifications: CommandCollection, Sendable {

        let content: CommandFactory<FilteredNotificationInput, Void>

        let note: CommandFactory<Note, Void>

        let post: CommandFactory<Post, Void>

        let postByID: CommandFactory<PostID, Void>

        let send: CommandFactory<PushNotification, Void>

        init(
            content: CommandFactory<FilteredNotificationInput, Void> = .content,
            note: CommandFactory<Note, Void> = .noteNotification,
            post: CommandFactory<Post, Void> = .postNotification,
            postByID: CommandFactory<PostID, Void> = .postNotificationByID,
            send: CommandFactory<PushNotification, Void> = .send
        ) {
            self.content = content
            self.note = note
            self.post = post
            self.postByID = postByID
            self.send = send
        }
    }
}
