import Foundation
import Core

extension Commands {
    var notifications: Commands.Notifications.Type { Commands.Notifications.self }
}

extension Commands {
    struct Notifications: CommandCollection, Sendable {
        
        let send: CommandFactory<PushNotification, Void>
        
        init(
            send: CommandFactory<PushNotification, Void> = .send
        ) {
            self.send = send
        }
    }
}
