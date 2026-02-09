import Foundation

extension PlatformChecker {

    static let appleMusic = PlatformChecker { url in
        url.host?.lowercased().contains("music.apple.com") ?? false
    }
}
