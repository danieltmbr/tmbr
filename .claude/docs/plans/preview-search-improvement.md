# Improvement: Unify BookSearch / SongSearch via PreviewSearch

## Problem

`Command+BookSearch.swift` and `Command+SongSearch.swift` are nearly identical. Both manually:
- Join the domain table (Book / Song) onto Preview
- Apply raw-SQL ILIKE filters
- Grant permissions on the query
- Run a concurrent note search
- Deduplicate results by preview ID

The only differences are the `parentType` filter and the searched columns.

## Why it hasn't been done yet

A general-purpose `listPreviews` command (`Command+ListPreviews.swift`) already exists and is used by `CatalogueSearch`. It takes `PreviewQueryInput { term, types }` and searches `primaryInfo` (title) and `secondaryInfo` (author/artist) on the Preview table using safe Fluent parameter binding.

The blocker: `listPreviews` only knows about Preview fields. The join-based commands also search `genre` (books) and `album` + `genre` (songs), which live on the domain tables and have no representation on Preview.

## Proposed solution

Add a `tertiaryInfo` field (or a `searchTerms: [String]` array) to `Preview` to hold additional searchable text — populated by `PreviewModelMiddleware` from whatever domain-specific fields make sense (genre, album, etc.).

Once Preview carries all searchable data, `listPreviews` can include a filter on this field, and `BookSearch` / `SongSearch` reduce to:

```swift
static func searchBooks(
    previewSearch: CommandResolver<PreviewQueryInput, [Preview]>,
    noteSearch: CommandResolver<NoteQueryPayload, [Note]>
) -> Self {
    PlainCommand { term in
        let input = PreviewQueryInput(term: term, types: [Book.previewType])
        async let previewsTask = previewSearch(input)
        async let notesTask = noteSearch(NoteQueryPayload(term: term, types: [Book.previewType]))
        let (previews, notes) = try await (previewsTask, notesTask)
        // dedup ...
        return BookSearchResult(previews: previews, noteMatches: noteMatches)
    }
}
```

The `BookSearchResult` / `SongSearchResult` / `CatalogueSearchResult` types are structurally identical and could also be unified into a single shared `SearchResult` type.

## Steps when ready

1. Add migration to add `search_terms` (text array, default `{}`) to `previews`
2. Populate it in each `PreviewModelMiddleware` configure closure (e.g. genre, album)
3. Extend `listPreviews` to also ILIKE-search the `search_terms` array elements
4. Refactor `searchBooks` and `searchSongs` to use `previewSearch` + `noteSearch` resolvers
5. Remove `database` + `permission` params from both commands
6. Optionally unify the three result types into `SearchResult`
