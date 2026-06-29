import Foundation

public extension ISO8601DateFormatter {

    /// Parses an ISO 8601 date string produced by the tmbr backend.
    ///
    /// Tries fractional-seconds first (`…02.123Z`), then falls back to whole-second (`…02Z`),
    /// matching the Vapor backend's default encoder output and all known date-string formats the
    /// tmbr servers have ever emitted.
    ///
    /// Formatters are created inside the function (not captured) so callers can use this in
    /// `@Sendable` closures — `ISO8601DateFormatter` is not `Sendable`.
    static func parse(_ string: String) -> Date? {
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFractional.date(from: string) { return date }
        let withoutFractional = ISO8601DateFormatter()
        withoutFractional.formatOptions = [.withInternetDateTime]
        return withoutFractional.date(from: string)
    }
}
