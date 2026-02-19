import Vapor
import Fluent
import Core
import SotoCore
import AuthKit

struct Notes: Module {
    
    private let noteCommands: Commands.Notes
    
    private let notePermissions: PermissionScopes.Notes
    
    private let quoteCommands: Commands.Quotes
    
    private let quotePermissions: PermissionScopes.Quotes
    
    init(
        noteCommands: Commands.Notes,
        notePermissions: PermissionScopes.Notes,
        quoteCommands: Commands.Quotes,
        quotePermissions: PermissionScopes.Quotes
    ) {
        self.noteCommands = noteCommands
        self.notePermissions = notePermissions
        self.quoteCommands = quoteCommands
        self.quotePermissions = quotePermissions
    }
    
    func configure(_ app: Vapor.Application) async throws {
        app.migrations.add(CreateNote())
        app.migrations.add(CreateQuote())
        app.migrations.add(UpdateNoteVisibilityToAccess())
        app.migrations.add(ChangeNoteIDToUUID())
        app.migrations.add(DeferQuoteForeignKey())
        app.databases.middleware.use(NoteModelMiddleware())
        
        try await app.permissions.add(scope: notePermissions)
        try await app.permissions.add(scope: quotePermissions)
        
        try await app.commands.add(collection: noteCommands)
        try await app.commands.add(collection: quoteCommands)
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {}
}

extension Module where Self == Notes {
    static var notes: Self {
        Notes(
            noteCommands: Commands.Notes(),
            notePermissions: PermissionScopes.Notes(),
            quoteCommands: Commands.Quotes(),
            quotePermissions: PermissionScopes.Quotes()
        )
    }
}
