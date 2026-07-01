import Vapor
import Fluent
import WebCore
import SotoCore
import WebAuth
import TmbrCore

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
        app.migrations.add(AddNoteLanguage())
        app.migrations.add(RefactorQuotesTable())
        app.migrations.add(SeedQuotesWithMarkdown())
        app.migrations.add(RepairQuoteLineBreaks())
        app.migrations.add(FixQuoteBodyToBlockquoteFormat())
        app.migrations.add(FixQuoteCitationClass())
        app.databases.middleware.use(NoteModelMiddleware())
        app.databases.middleware.use(DeletionMiddleware<Note>(
            deletionType: .note,
            itemID: { $0.id?.uuidString },
            ownerID: { $0.$author.id },
            access: { $0.access }
        ))

        try await app.permissions.add(scope: notePermissions)
        try await app.permissions.add(scope: quotePermissions)
        
        try await app.commands.add(collection: noteCommands)
        try await app.commands.add(collection: quoteCommands)
    }
    
    func boot(_ routes: any Vapor.RoutesBuilder) async throws {
        try routes.register(collection: NotesAPIController())
        try routes.register(collection: QuotesAPIController())
        let recovering = routes.grouped(RecoverMiddleware())
        try recovering.register(collection: NotesWebController())
        try recovering.register(collection: QuotesWebController())
    }
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
