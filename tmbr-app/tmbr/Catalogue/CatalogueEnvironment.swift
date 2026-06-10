import SwiftUI

extension EnvironmentValues {
    @Entry var syncCatalogue: SyncCatalogueAction = SyncCatalogueAction()
    @Entry var createNote: CreateNoteAction = CreateNoteAction()
    @Entry var updateNote: UpdateNoteAction = UpdateNoteAction()
    @Entry var deleteNote: DeleteNoteAction = DeleteNoteAction()
}
