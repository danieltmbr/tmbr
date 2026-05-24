import Vapor

public protocol Module: Configuration {
    func boot(_ routes: RoutesBuilder) async throws
}
