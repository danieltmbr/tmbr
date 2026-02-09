import Foundation
import Core

struct Platform<M>: Sendable {

    typealias Fetcher = @Sendable (URL) async throws -> Metadata

    private let name: @Sendable (URL) -> String?
    
    private let metadata: @Sendable (URL, Fetcher) async throws -> M?

    // MARK: - Functional init

    init(
        name: @escaping @Sendable (URL) -> String?,
        metadata: @escaping @Sendable (URL, Fetcher) async throws -> M?
    ) {
        self.metadata = metadata
        self.name = name
    }

    // MARK: - Convenience init

    init(
        name: String,
        checker: PlatformChecker,
        extractor: MetadataExtractor<M>? = nil
    ) {
        self.init(
            name: { url in
                checker.matches(url) ? name : nil
            },
            metadata: { url, fetcher in
                guard checker.matches(url) else { return nil }
                return try await extractor?.extract(from: url, fetcher: fetcher)
            }
        )
    }

    // MARK: - Composite init

    init(platforms: [Platform<M>]) {
        self.init(
            name: { url in
                for platform in platforms {
                    if let name = platform.name(for: url) {
                        return name
                    }
                }
                return nil
            },
            metadata: { url, fetcher in
                for platform in platforms {
                    if let metadata = try await platform.metadata(for: url, fetcher: fetcher) {
                        return metadata
                    }
                }
                return nil
            }
        )
    }

    // MARK: - Methods

    func metadata(for url: URL, fetcher: Fetcher) async throws -> M? {
        try await metadata(url, fetcher)
    }
    
    func name(for url: URL) -> String? {
        name(url)
    }

    func hyperlink(from url: URL) -> Hyperlink? {
        guard let name = name(for: url) else { return nil }
        return Hyperlink(label: name, url: url)
    }

    func hyperlink(from urlString: String) -> Hyperlink? {
        guard let url = URL(string: urlString) else { return nil }
        return hyperlink(from: url)
    }
}
