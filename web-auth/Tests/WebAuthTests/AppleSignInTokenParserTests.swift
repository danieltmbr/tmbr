import Testing
import VaporTesting
import Logging
@testable import WebAuth

/// The parser is a global middleware, so it runs on every request — including
/// public ones. A request without a Bearer header must pass through silently:
/// vapor/jwt's no-argument `verify()` logs at `.error` *before* throwing, which
/// once flooded production logs on every unauthenticated request.
@Suite struct AppleSignInTokenParserTests {

    @Test func missingBearerHeaderPassesThroughWithoutErrorLog() async throws {
        _ = bootstrapCapturingLogger
        CapturedLogs.shared.reset()

        let app = try await Application.make(.testing)
        app.middleware.use(AppleSignInTokenParser())
        app.get("public") { _ in "ok" }

        do {
            try await app.testing().test(.GET, "public") { response async in
                #expect(response.status == .ok)
            }
        } catch {
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()

        let errors = CapturedLogs.shared.messages(atOrAbove: .error)
        #expect(errors.isEmpty, "Unauthenticated request produced error logs: \(errors)")
    }
}

// MARK: - Log capturing

/// `LoggingSystem.bootstrap` may only run once per process, so it is wrapped
/// in a lazily-evaluated global that every test touches first.
private let bootstrapCapturingLogger: Void = {
    LoggingSystem.bootstrap { label in CapturingLogHandler(label: label) }
}()

final class CapturedLogs: @unchecked Sendable {
    static let shared = CapturedLogs()

    private let lock = NSLock()
    private var records: [(level: Logger.Level, message: String)] = []

    func append(level: Logger.Level, message: String) {
        lock.lock()
        defer { lock.unlock() }
        records.append((level, message))
    }

    func messages(atOrAbove level: Logger.Level) -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return records.filter { $0.level >= level }.map(\.message)
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        records.removeAll()
    }
}

private struct CapturingLogHandler: LogHandler {
    let label: String
    var metadata: Logger.Metadata = [:]
    var logLevel: Logger.Level = .trace

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        CapturedLogs.shared.append(level: level, message: message.description)
    }
}
