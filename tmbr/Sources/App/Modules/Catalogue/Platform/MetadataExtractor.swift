import Foundation

enum MetadataExtractionError: Error {
    case invalidType(expected: String, actual: String?)
}

struct MetadataExtractor<M>: Sendable {

    typealias Fetcher = @Sendable (URL) async throws -> Metadata

    private let extract: @Sendable (URL, Fetcher) async throws -> M

    init(extract: @escaping @Sendable (URL, Fetcher) async throws -> M) {
        self.extract = extract
    }

    func extract(from url: URL, fetcher: Fetcher) async throws -> M {
        try await extract(url, fetcher)
    }
    
    static func extract(
        key: String,
        from url: URL,
        of type: String,
        with fetcher: Fetcher
    ) async throws -> String? {
        let metadata = try await fetcher(url)
        guard metadata.type == type else { return nil }
        return metadata.data[key]
    }
    
    static func extract(
        key: String,
        from urlString: String?,
        of type: String,
        with fetcher: Fetcher
    ) async throws -> String? {
        guard let url = urlString.flatMap(URL.init) else { return nil }
        return try await extract(key: key, from: url, of: type, with: fetcher)
    }
}
