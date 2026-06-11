import Fluent
import Core

extension QueryBuilder where Model: Previewable {
    @discardableResult
    func page(_ input: PageInput) -> Self {
        if let since = input.since { filter(Preview.self, \Preview.$createdAt > since) }
        if let before = input.before { filter(Preview.self, \Preview.$createdAt < before) }
        return limit(input.limit + 1)
    }
}
