import Foundation

struct MediaPlatform: Codable, Sendable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
    
    private let name: String
        
    var displayName: String {
        switch self {
        case .appleMusic: "Apple Music"
        case .spotify: "Spotify"
        case .imdb: "IMDb"
        case .rottenTomatoes: "Rotten Tomatoes"
        case .youtube: "YouTube"
        case .goodreads: "Goodreads"
        default: Self.denormalise(name)
        }
    }
    
    var description: String { name }
    
    /// Whether this value matches any of the known providers.
    var isSupported: Bool {
        Self.supported.contains(self)
    }
    
    // MARK: - Initialization

    init(_ name: String) {
        self.name = MediaPlatform.normalize(name)
    }

    init(stringLiteral value: StringLiteralType) {
        self.init(value)
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

    // MARK: - Known providers
    
    static let appleMusic: Self = "apple-music"
    
    static let imdb: Self = "imdb"
    
    static let goodreads: Self = "goodreads"
    
    static let rottenTomatoes: Self = "rotten-tomatoes"
    
    static let spotify: Self = "spotify"

    static let web: Self = "web"
    
    static let youtube: Self = "youtube"

    static let supported: Set<MediaPlatform> = [
        .appleMusic,
        .imdb,
        .goodreads,
        .rottenTomatoes,
        .spotify,
        .web,
        .youtube,
    ]

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
