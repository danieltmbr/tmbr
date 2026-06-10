import Fluent
import TmbrCore

/// Batch-fetches notes authored by `userID` for a set of preview IDs.
/// Returns a dictionary keyed by PreviewID for O(1) lookup when building responses.
func batchLoadNotes(
    for previewIDs: [PreviewID],
    authorID: Int,
    on database: Database
) async throws -> [PreviewID: [Note]] {
    guard !previewIDs.isEmpty else { return [:] }
    let notes = try await Note.query(on: database)
        .filter(\.$attachment.$id ~~ previewIDs)
        .filter(\.$author.$id == authorID)
        .with(\.$attachment) { a in a.with(\.$image) }
        .with(\.$author)
        .with(\.$quotes)
        .all()
    return Dictionary(grouping: notes, by: { $0.$attachment.id })
}
