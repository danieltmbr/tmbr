import Foundation
import Vapor
import Core
import Fluent
import AuthKit
import TmbrCore

struct SyncContainerEntriesInput: Sendable {
    let containerType: String
    let containerID: Int
    let tracks: [TrackMetadata]
    let access: Access
    let ownerID: UserID
}

extension Command where Self == PlainCommand<SyncContainerEntriesInput, Void> {
    static func syncContainerEntries(database: Database) -> Self {
        PlainCommand { input in
            let existing = try await ContainerEntry.query(on: database)
                .filter(\.$containerType == input.containerType)
                .filter(\.$containerID == input.containerID)
                .with(\.$preview) { $0.with(\.$catalogueCategory) }
                .all()

            let existingByPreviewID: [UUID: ContainerEntry] = Dictionary(
                uniqueKeysWithValues: existing.map { entry in (entry.$preview.id, entry) }
            )

            guard let trackCategory = try await CatalogueCategory.query(on: database)
                .filter(\.$slug == "track").first(),
                  let trackCategoryID = trackCategory.id else {
                throw Abort(.internalServerError, reason: "Track category not found")
            }

            // Build a URL→previewID map from the user's existing songs to avoid duplicates
            var existingSongsByURL: [String: UUID] = [:]
            if let songCategory = try await CatalogueCategory.query(on: database)
                .filter(\.$slug == "song").first(),
               let songCategoryID = songCategory.id {
                let songPreviews = try await Preview.query(on: database)
                    .filter(\Preview.$catalogueCategory.$id == songCategoryID)
                    .filter(\Preview.$parentOwner.$id == input.ownerID)
                    .all()
                for preview in songPreviews {
                    guard let id = preview.id else { continue }
                    for link in preview.externalLinks { existingSongsByURL[link] = id }
                }
            }

            // Determine desired previewIDs in order
            var desiredPreviewIDs: [UUID] = []
            for track in input.tracks {
                if let pid = track.previewID {
                    desiredPreviewIDs.append(pid)
                } else if let url = track.url, let existing = existingSongsByURL[url] {
                    desiredPreviewIDs.append(existing)
                } else {
                    let preview = Preview(
                        id: UUID(),
                        parentID: nil,
                        parentAccess: input.access,
                        parentOwner: input.ownerID,
                        categoryID: trackCategoryID
                    )
                    preview.primaryInfo = track.name
                    preview.externalLinks = [track.url].compactMap { $0 }
                    try await preview.save(on: database)
                    desiredPreviewIDs.append(try preview.requireID())
                }
            }

            let desiredSet = Set(desiredPreviewIDs)

            // Remove entries no longer in the desired list
            for entry in existing {
                let pid = entry.$preview.id
                if !desiredSet.contains(pid) {
                    if entry.preview.catalogueCategory?.kind == .promotable {
                        try await entry.preview.delete(on: database)
                    } else {
                        try await entry.delete(on: database)
                    }
                }
            }

            // Upsert entries in correct positions
            for (index, previewID) in desiredPreviewIDs.enumerated() {
                let position = index + 1
                if let existing = existingByPreviewID[previewID] {
                    if existing.position != position {
                        existing.position = position
                        try await existing.save(on: database)
                    }
                } else {
                    let entry = ContainerEntry(
                        containerType: input.containerType,
                        containerID: input.containerID,
                        previewID: previewID,
                        position: position
                    )
                    try await entry.save(on: database)
                }
            }
        }
    }
}

extension CommandFactory<SyncContainerEntriesInput, Void> {
    static var syncContainerEntries: Self {
        CommandFactory { request in
            .syncContainerEntries(database: request.commandDB)
        }
    }
}
