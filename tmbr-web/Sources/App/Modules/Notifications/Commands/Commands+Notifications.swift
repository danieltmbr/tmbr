import Foundation
import Core
import TmbrCore

extension Commands {
    var notifications: Commands.Notifications.Type { Commands.Notifications.self }
}

extension Commands {
    struct Notifications: CommandCollection, Sendable {

        let filteredSend: CommandFactory<FilteredNotificationInput, Void>

        let note: CommandFactory<Note, Void>

        let post: CommandFactory<Post, Void>

        let postByID: CommandFactory<PostID, Void>

        let send: CommandFactory<PushNotification, Void>

        init(
            filteredSend: CommandFactory<FilteredNotificationInput, Void> = .filteredSend,
            note: CommandFactory<Note, Void> = .noteNotification,
            post: CommandFactory<Post, Void> = .postNotification,
            postByID: CommandFactory<PostID, Void> = .postNotificationByID,
            send: CommandFactory<PushNotification, Void> = .send
        ) {
            self.filteredSend = filteredSend
            self.note = note
            self.post = post
            self.postByID = postByID
            self.send = send
        }
    }
}
