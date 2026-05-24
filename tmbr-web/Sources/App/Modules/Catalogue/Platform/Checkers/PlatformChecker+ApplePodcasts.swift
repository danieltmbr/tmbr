import Foundation

extension PlatformChecker {

    static let applePodcasts = PlatformChecker { url in
        url.host?.lowercased().contains("podcasts.apple.") ?? false
    }
}
