import Foundation

public extension JSONDecoder {
    /// A shared response decoder for all tmbr API responses.
    ///
    /// The Vapor backend encodes `Date` fields as **ISO 8601 strings** (e.g. `"2026-06-06T18:44:02Z"`).
    /// This decoder tries fractional-seconds first, then falls back to whole-second ISO 8601, so both
    /// `"…T00:00:00.000Z"` and `"…T18:44:02Z"` decode correctly.
    static func tmbr() -> JSONDecoder {
        let decoder = JSONDecoder()
        // Formatters are created inside the closure (not captured) so the @Sendable closure captures
        // no non-Sendable state — ISO8601DateFormatter is not Sendable.
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = ISO8601.date(from: string) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Expected ISO 8601 date string, got: \(string)"
                )
            }
            return date
        }
        return decoder
    }
}
