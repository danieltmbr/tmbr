import Vapor
import Fluent
import Core
import SotoCore
import AuthKit

struct Notes: Module {
    
    private let notePermissions: PermissionScopes.Notes
    
    private let quotePermissions: PermissionScopes.Quotes
    
    init(
        notePermissions: PermissionScopes.Notes,
        quotePermissions: PermissionScopes.Quotes
    ) {
        self.notePermissions = notePermissions
        self.quotePermissions = quotePermissions
    }
    
    func configure(_ app: Vapor.Application) async throws {
        app.migrations.add(CreateNote())
        app.migrations.add(CreateQuote())
        app.migrations.add(UpdateNoteVisibilityToAccess())
        app.databases.middleware.use(NoteModelMiddleware())
        
        try await app.permissions.add(scope: notePermissions)
        try await app.permissions.add(scope: quotePermissions)
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
        try routes.register(collection: NotesController())
    }
}

extension Module where Self == Notes {
    static var notes: Self {
        Notes(
            notePermissions: PermissionScopes.Notes(),
            quotePermissions: PermissionScopes.Quotes()
        )
    }
}
