import Vapor
import WebPush

actor NotificationService {
    enum Priority {
        case low
        case normal
        case hight
    }
    
    private let manager: WebPushManager
    
    let vapidKeyID: VAPID.Key.ID
    
    init(manager: WebPushManager, vapidKeyID: VAPID.Key.ID) {
        self.manager = manager
        self.vapidKeyID = vapidKeyID
    }
    
    init(app: Application) throws {
        let vapidConfiguration = try VAPID.Configuration(environment: app.environment)
        guard let primaryKey = vapidConfiguration.primaryKey else {
            throw Abort(.internalServerError, reason: "VAPID primary key is missing")
        }
        self.init(
            manager: WebPushManager(
                vapidConfiguration: vapidConfiguration,
                backgroundActivityLogger: app.logger
            ),
            vapidKeyID: primaryKey.id
        )
    }
    
    func notify(
        subscriptions: [Subscription],
        content: PushNotification,
        priority: Priority = .low
    ) async {
        await withTaskGroup { group in
            for subscription in subscriptions {
                group.addTask {
                    await self.notify(
                        subscription: subscription,
                        content: content,
                        priority: priority
                    )
                }
            }
        }
    }
    
    func notify(
        subscription: Subscription,
        content: PushNotification,
        priority: Priority = .low
    ) async {
        do {
            try await manager.send(
                json: content,
                to: map(subscription: subscription),
                urgency: map(priority: priority)
            )
        } catch is BadSubscriberError {
            // The subscription is no longer valid and should be removed.
            // TODO: Remove subscription
        } catch is MessageTooLargeError {
            // The message was too long and should be shortened.
            print("Push Message is too long")
        } catch let error as PushServiceError {
            // The push service ran into trouble. error.response may help here.
            print("Push Service error: \(error.localizedDescription)")
        } catch {
            // An unknown error occurred.
            print("Unknownw push error: \(error.localizedDescription)")
        }
    }
    
    private func map(subscription: Subscription) throws -> Subscriber {
        try Subscriber(
            // TODO: Throw instead of force unwrap
            endpoint: URL(string: subscription.endpoint)!,
            userAgentKeyMaterial: UserAgentKeyMaterial(
                publicKey: subscription.p256dh,
                authenticationSecret: subscription.auth
            ),
            vapidKeyID: vapidKeyID
        )
    }
    
    private func map(priority: Priority) -> WebPushManager.Urgency {
        switch priority {
        case .low: .low
        case .normal: .normal
        case .hight: .high
        }
    }
}
