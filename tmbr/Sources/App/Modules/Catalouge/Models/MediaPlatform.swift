import Foundation
import Vapor

struct MediaPlatform<ContentType: MediaItem>: Codable, Sendable, Hashable, ExpressibleByStringLiteral {
    
    private let name: String
    
    // MARK: - Initialization

    init(_ name: String) {
        let name = MediaPlatform.normalize(name)
        self.name = name
    }

    init(stringLiteral value: StringLiteralType) {
        self.name = value
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(container.decode(String.self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(name)
    }

    // MARK: - Normalization

    /// Normalizes provider strings to a lowercase hyphenated slug.
    private static func normalize(_ name: String) -> String {
        // Trim whitespace/newlines
        let s = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")
            .folding(options: .diacriticInsensitive, locale: .current)

        var out = String()
        var lastWasHyphen = false
        for scalar in s.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                out.unicodeScalars.append(scalar)
                lastWasHyphen = false
            } else if scalar == "-".unicodeScalars.first! {
                if !lastWasHyphen {
                    out.append("-")
                    lastWasHyphen = true
                }
            } else {
                // For any other separator/punctuation, translate to hyphen (collapsing repeats)
                if !lastWasHyphen {
                    out.append("-")
                    lastWasHyphen = true
                }
            }
        }
        return out.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
    
    private static func denormalise(_ name: String) -> String {
        name.replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
