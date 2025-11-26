import Vapor
import Fluent
import AuthKit

struct MediaController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let media = routes.grouped("media")
        media.post(use: create)
        media.get(":mediaID", use: get)
        media.post(":mediaID", "resources", use: addResources)
        media.post(":mediaID", "notes", use: addNotes)

        let notes = routes.grouped("media", "notes")
        notes.delete(":noteID", use: deleteNote)
    }

    // MARK: - Handlers

    func create(req: Request) async throws -> Media {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        let payload = try req.content.decode(MediaPayload.self)

        return try await req.db.transaction { db in
            let preview = Media.Preview(
                title: payload.preview.title,
                subtitle: payload.preview.subtitle,
                body: payload.preview.body,
                imageURL: payload.preview.imageURL
            )
            let media = Media(
                kind: payload.kind,
                ownerID: userID,
                preview: preview
            )
            try await media.save(on: db)
            let mediaID = try media.requireID()
            
            for note in payload.notes ?? [] {
                let note = MediaNote(
                    mediaID: mediaID,
                    authorID: userID,
                    type: note.type,
                    text: note.text,
                    commentary: note.commentary,
                    state: note.state ?? .draft,
                    positionStart: note.positionStart,
                    positionEnd: note.positionEnd
                )
                try await note.save(on: db)
            }
            
            func saveItem<Item: MediaItem>(
                with resources: [MediaResource<Item>],
                configure: @escaping (Item) throws -> Void = { _ in }
            ) async throws {
                let item = try Item(mediaID: mediaID, configure: configure)
                try await item.save(on: db)
                try await item.upsert(resources: resources, on: db)
            }

            switch payload.content {
            case .book(let book):
                try await saveItem(with: book.resources)
            case .movie(let movie):
                try await saveItem(with: movie.resources)
            case .music(let music):
                try await saveItem(with: music.resources) {
                    $0.entity = music.entity
                }
            case .podcast(let podcast):
                try await saveItem(with: podcast.resources)
            }

            return media
        }
    }

    func get(req: Request) async throws -> Media {
        guard let id = req.parameters.get("mediaID", as: Int.self) else {
            throw Abort(.badRequest)
        }
        guard let media = try await Media.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        try await media.load([.content, .notes], on: req.db)

        return media
    }

    func addResources(req: Request) async throws -> HTTPStatus {
        guard let mediaID = req.parameters.get("mediaID", as: Int.self) else {
            throw Abort(.badRequest)
        }
        let input = try req.content.decode([MediaResourcePayload].self)
        guard let media = try await Media.find(mediaID, on: req.db) else {
            throw Abort(.notFound)
        }
        try await media.load(.content, on: req.db)
        guard let content = media.content else {
            throw Abort(.conflict, reason: "Content is missing")
        }

        try await req.db.transaction { db in
            switch content {
            case .music(let music):
                let resources = try map(resources: input, supported: .music)
                try await music.upsert(resources: resources, on: db)
            case .movie(let movie):
                let resources = try map(resources: input, supported: .movie)
                try await movie.upsert(resources: resources, on: db)
            case .book(let book):
                let resources = try map(resources: input, supported: .book)
                try await book.upsert(resources: resources, on: db)
            case .podcast(let podcast):
                let resources = try map(resources: input, supported: .podcast)
                try await podcast.upsert(resources: resources, on: db)
            }
        }

        return .created
    }

    func addNotes(req: Request) async throws -> HTTPStatus {
        guard let mediaID = req.parameters.get("mediaID", as: Int.self) else {
            throw Abort(.badRequest)
        }
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        
        guard let media = try await Media.find(mediaID, on: req.db) else {
            throw Abort(.notFound)
        }
        try await media.$owner.load(on: req.db)
        guard media.owner.id == userID || media.collaboration == .users else {
            throw Abort(.forbidden)
        }
        let notes = try req.content.decode([MediaPayload.Note].self)
        
        try await req.db.transaction { db in
            try await withThrowingTaskGroup { group in
                for note in notes {
                    let model = MediaNote(
                        mediaID: mediaID,
                        authorID: userID,
                        type: note.type,
                        text: note.text,
                        commentary: note.commentary,
                        state: note.state ?? .draft,
                        positionStart: note.positionStart,
                        positionEnd: note.positionEnd
                    )
                    _ = group.addTaskUnlessCancelled {
                        try await model.save(on: db)
                    }
                    while try await group.next() != nil {}
                }
            }
        }
        
        return .created
    }

    func deleteNote(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let noteID = req.parameters.get("noteID", as: Int.self) else {
            throw Abort(.badRequest)
        }
        guard let note = try await MediaNote.find(noteID, on: req.db) else {
            throw Abort(.notFound)
        }
        try await note.$author.load(on: req.db)
        guard user.role == .admin || note.$author.id == user.id else {
            throw Abort(.forbidden)
        }
        try await note.delete(on: req.db)
        return .noContent
    }
    
    
    private func map<Item: MediaItem>(
        resources: [MediaResourcePayload],
        supported: Set<MediaPlatform<Item>>
    ) throws -> [MediaResource<Item>] {
        try resources.map { try $0.resource(supportedPlatforms: supported) }
    }
}
