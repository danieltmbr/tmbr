import Fluent
import Vapor

/// Middleware that deletes image files from disk after the DB row was deleted.
struct ImageCleanupMiddleware: AsyncModelMiddleware {
    typealias Model = Image

    private let publicDirectory: String
    
    init(publicDirectory: String) {
        self.publicDirectory = publicDirectory
    }

    func delete(model: Image, on db: Database, next: AnyAsyncModelResponder) async throws {
        // Perform the delete in DB first
        try await next.delete(model, force: true, on: db)

        let fm = FileManager.default
        let originalPath = fsPath(for: model.path)
        let thumbnailPath = fsPath(for: model.thumbnailPath)

        if fm.fileExists(atPath: originalPath) {
            try? fm.removeItem(atPath: originalPath)
        }
        if thumbnailPath != originalPath, fm.fileExists(atPath: thumbnailPath) {
            try? fm.removeItem(atPath: thumbnailPath)
        }
    }
    
    private func fsPath(for publicPath: String) -> String {
        // If already absolute under Public/, return as-is
        guard !publicPath.hasPrefix(publicDirectory) else {
            return publicPath
        }
        // Otherwise treat it as a public URL path and prefix with Public/
        let trimmed = publicPath.hasPrefix("/") ? String(publicPath.dropFirst()) : publicPath
        return publicDirectory + trimmed
    }
}
