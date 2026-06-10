import SwiftUI

extension View {
    func catalogue(_ model: CatalogueModel) -> some View {
        environment(model)
            .environment(\.syncCatalogue, SyncCatalogueAction(model: model))
            .environment(\.createNote, CreateNoteAction(syncEngine: model.syncEngine))
            .environment(\.updateNote, UpdateNoteAction(syncEngine: model.syncEngine))
            .environment(\.deleteNote, DeleteNoteAction(syncEngine: model.syncEngine))
    }
}
