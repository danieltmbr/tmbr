import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct CreateBookInput {
    struct Note {
        fileprivate let access: Access
        
        fileprivate let body: String
        
        init(payload: NotePayload) {
            access = payload.access
            body = payload.body
        }
        
        fileprivate func validate() throws {
            guard !body.trimmed.isEmpty else {
                throw Abort(.badRequest, reason: "Note's content is missing.")
            }
        }
    }
    
    fileprivate let book: BookInput
    
    fileprivate let notes: [Note]
    
    init(payload: BookPayload) {
        book = BookInput(payload: payload)
        notes = payload.notes?.map(Note.init) ?? []
    }
    
    fileprivate func validate() throws {
        try book.validate()
        try notes.forEach { try $0.validate() }
    }
}

struct CreateBookCommand: Command {
    
    typealias Input = CreateBookInput
    
    typealias Output = Book
    
    private let configure: BookConfiguration

    private let database: Database
        
    private let permission: AuthPermissionResolver<Void>

    init(
        configure: BookConfiguration = .default,
        database: Database,
        permission: AuthPermissionResolver<Void>
    ) {
        self.configure = configure
        self.database = database
        self.permission = permission
    }

    func execute(_ input: CreateBookInput) async throws -> Book {
        let user = try await permission.grant()
        try input.validate()
        return try await database.transaction { db in
            let book = Book(owner: user.userID)
            configure(book, with: input.book)
            try await book.save(on: database)
            
            let bookID = try book.requireID()
            let previewID = try book.preview.requireID()
            let notes = input.notes.map { note in
                Note(
                    attachmentID: previewID,
                    authorID: user.userID,
                    access: note.access && book.access,
                    body: note.body
                )
            }
            try await notes.create(on: db)
            
            let bookNotes = try notes.map { note in
                BookNote(book: bookID, note: try note.requireID())
            }
            try await bookNotes.create(on: db)
            try await book.$bookNotes.load(on: db, include: \.$note)
            return book
        }
    }
}

extension CommandFactory<CreateBookInput, Book> {

    static var createBook: Self {
        CommandFactory { request in
            CreateBookCommand(
                database: request.application.db,
                permission: request.permissions.books.create
            )
            .logged(logger: request.logger)
        }
    }
}
