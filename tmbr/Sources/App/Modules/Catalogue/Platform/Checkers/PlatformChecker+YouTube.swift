import Foundation

extension PlatformChecker {

    static let youtube = PlatformChecker { url in
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("youtube.") || host.contains("youtu.be")
    }
}
