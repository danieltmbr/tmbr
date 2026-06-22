import Foundation

/// Canonical ISO 8601 date parser shared across the tmbr platform.
///
/// Tries fractional-seconds first (`…02.123Z`), then falls back to whole-second (`…02Z`),
/// matching the Vapor backend's default encoder output and all known date-string formats the
/// tmbr servers have ever emitted.
public enum ISO8601 {

    /// Parse an ISO 8601 date string produced by the tmbr backend.
    ///
    /// Formatters are created inside the function (not captured) so callers can use this in
    /// `@Sendable` closures — `ISO8601DateFormatter` is not `Sendable`.
    ///
    /// - Returns: the decoded `Date`, or `nil` if `string` matches neither format.
    public static func date(from string: String) -> Date? {
        // Fractional seconds — e.g. "2026-06-06T18:44:02.123Z"
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFractional.date(from: string) { return date }
        // Whole-second — e.g. "2026-06-06T18:44:02Z"
        let withoutFractional = ISO8601DateFormatter()
        withoutFractional.formatOptions = [.withInternetDateTime]
        return withoutFractional.date(from: string)
    }
}
