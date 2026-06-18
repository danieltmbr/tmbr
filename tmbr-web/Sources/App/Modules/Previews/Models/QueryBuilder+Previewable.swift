import Fluent
import CoreWeb

extension QueryBuilder where Model: Previewable {
    @discardableResult
    func page(_ input: PageInput) -> Self {
        // Delta (`since`) matches items created OR whose notes changed since last sync — note edits
        // bump Preview.updatedAt (see NoteModelMiddleware). Load-more (`before`) stays on createdAt
        // for stable backward paging.
        if let since = input.since {
            group(.or) { or in
                or.filter(Preview.self, \Preview.$createdAt > since)
                or.filter(Preview.self, \Preview.$updatedAt > since)
            }
        }
        if let before = input.before { filter(Preview.self, \Preview.$createdAt < before) }
        return limit(input.limit + 1)
    }
}
