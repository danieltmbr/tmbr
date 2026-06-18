import Foundation
import SwiftData
import CoreTmbr

/// The single SwiftData schema shared by all three apps (Author / Reader / Personal).
///
/// Each app builds its own `ModelContainer` from this list with its own `ModelConfiguration`
/// (plain on-disk for Author/Reader; `.private` CloudKit for Personal). The schema is the same;
/// only the container configuration and the injected sync composition differ.
/// 
public enum AppSchema {

    public static let models: [any PersistentModel.Type] = [
        PreviewRecord.self,
        SongRecord.self,
        AlbumRecord.self,
        BookRecord.self,
        MovieRecord.self,
        PodcastRecord.self,
        PlaylistRecord.self,
        ContainerEntryRecord.self,
        NoteRecord.self,
        PostRecord.self,
        QuoteRecord.self,
        UserRecord.self,
    ]

    public static var schema: Schema { Schema(models) }
}
