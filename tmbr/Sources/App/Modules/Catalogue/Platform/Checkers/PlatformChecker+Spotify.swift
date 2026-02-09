import Foundation

extension PlatformChecker {

    static let spotify = PlatformChecker { url in
        url.host?.lowercased().contains("spotify.") ?? false
    }
}
