import Vapor

public protocol Module: Configuration {
    func boot(_ app: Application) async throws
}
