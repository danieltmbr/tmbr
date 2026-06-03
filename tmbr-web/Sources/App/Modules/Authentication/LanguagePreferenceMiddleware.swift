import Vapor

private struct LanguagePreferenceKey: StorageKey {
    typealias Value = Set<String>
}

extension Request {
    var languagePreference: Set<String>? {
        storage[LanguagePreferenceKey.self]
    }
}

struct LanguagePreferenceMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        if let value = request.cookies["lang_pref"]?.string, !value.isEmpty {
            let languages = Set(value.split(separator: "|").map(String.init).filter { !$0.isEmpty })
            if !languages.isEmpty {
                request.storage[LanguagePreferenceKey.self] = languages
            }
        }
        return try await next.respond(to: request)
    }
}
