import Vapor
import CoreWeb

extension Configuration where Self == CoreConfiguration {
    static var commands: Self {
        CoreConfiguration { app in
            await app.storage.setWithAsyncShutdown(
                CommandStorage.Key.self,
                to: CommandStorage()
            )
        }
    }
}
