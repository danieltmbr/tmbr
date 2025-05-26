import Vapor
import WebPush

actor NotificationService {
    
    typealias RemoveSubscription = @Sendable (WebPushSubscription) async throws -> Void
    
    enum Priority {
        case low
        case normal
        case hight
    }
    
    private let logger: Logger
    
    private let manager: WebPushManager
    
    private let removeSubscription: RemoveSubscription
    
    let vapidKeyID: VAPID.Key.ID
    
    init(
        logger: Logger,
        manager: WebPushManager,
        removeSubscription: @escaping RemoveSubscription,
        vapidKeyID: VAPID.Key.ID
    ) {
        self.logger = logger
        self.manager = manager
        self.removeSubscription = removeSubscription
        self.vapidKeyID = vapidKeyID
    }
    
    init(app: Application) throws {
        let vapidConfiguration = try VAPID.Configuration(environment: app.environment)
        guard let primaryKey = vapidConfiguration.primaryKey else {
            throw Abort(.internalServerError, reason: "VAPID primary key is missing")
        }
        self.init(
            logger: app.logger,
            manager: WebPushManager(
                vapidConfiguration: vapidConfiguration,
                backgroundActivityLogger: app.logger
            ),
            removeSubscription: { subscription in
                try await subscription.delete(on: app.db)
            },
            vapidKeyID: primaryKey.id
        )
    }
    
    func notify(
        subscriptions: [WebPushSubscription],
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
        subscription: WebPushSubscription,
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
            try? await removeSubscription(subscription)
            logger.error("The subscription is no longer valid and it's been removed.")
        } catch is MessageTooLargeError {
            logger.error("Push Message is too long. Message: \(content.body)")
        } catch let error as PushServiceError {
            logger.error("Push Service error: \(error.localizedDescription)")
        } catch {
            logger.error("Unknownw push error: \(error.localizedDescription)")
        }
    }
    
    private func map(subscription: WebPushSubscription) throws -> Subscriber {
        guard let endpointURL = URL(string: subscription.endpoint) else {
            throw URLError(.badURL)
        }
        return try Subscriber(
            endpoint: endpointURL,
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
