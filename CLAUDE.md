# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TMBR is a personal web application built with Swift and Vapor. Its core purpose is capturing thoughts, emotions, and reflections — either as standalone Posts or as Notes attached to entities that provoked them (a song, book, movie, podcast, or potentially any future entity type like a friend/contact). The Catalogue is the first such entity source, but the architecture (Preview-based linking, Notes, Posts) is designed to extend to any domain where an entity can own Notes and be referenced by Posts.

## Build & Run Commands

```bash
# Build the project
swift build

# Run the application (from tmbr/ directory)
swift run App serve

# Run with production settings
swift run App serve --env production --hostname 0.0.0.0 --port 8080

# Run tests
swift test

# Run a specific test target
swift test --filter CoreTests
swift test --filter AppTests
```

The main application code is in the `tmbr/` subdirectory. Run Swift commands from there.

## Tech Stack

- **Swift 6.0.3** with Swift 5 language mode
- **Vapor 4** - Server-side Swift web framework
- **Fluent** - ORM with PostgreSQL driver
- **Leaf** - HTML templating engine
- **Swift Testing** - Test framework (uses `@Test` and `#expect`)

## Architecture

### Module System

The app uses a modular architecture defined in `Sources/Core/Module/`:

- **Configuration** protocol: Setup phase for dependencies, migrations, middleware
- **Module** protocol: Extends Configuration with `boot()` for route registration
- **ModuleRegistry**: Orchestrates multiple modules

Modules are registered in `Sources/App/entrypoint.swift`:
```swift
ModuleRegistry(
    configurations: [.logging, .database, .commands, .renderer],
    modules: [.rss, .manifest, .authentication, .notifications,
              .gallery, .previews, .notes, .posts, .catalogue, .debug]
)
```

### Module Structure

Each module in `Sources/App/Modules/` follows this pattern:
- `ModuleName.swift` - Module definition implementing `configure()` and `boot()`
- `Models/` - Fluent database models and migrations
- `Commands/` - Business logic commands (Create, Edit, Delete, Fetch, List)
- `Routes/API/` - REST API controllers and `Responses/` DTOs
- `Routes/Web/` - Web controllers and Pages
- `Permissions/` - Permission scopes for the module
- `Payloads/` - Endpoint-specific request DTOs (API payloads, query parameters, etc.)

Response DTOs (e.g., `PostResponse`, `ImageResponse`) belong in `Routes/API/Responses/`, not in `Payloads/`. They are REST-specific objects — the API equivalent of Web Page view models. Keeping them alongside the API controllers makes the boundary clear.

**Catalogue is a nested module.** Unlike other top-level modules, Catalogue (`Sources/App/Modules/Catalogue/`) contains its own inner `ModuleRegistry` with sub-modules: Books, Movies, Songs, Podcasts, and a shared Catalogue controller. New catalogue item types are added as sub-modules inside Catalogue, not as top-level modules.

### Command Pattern

Business logic is decoupled from HTTP handlers via composable, single-responsibility commands (`Sources/Core/Commands/`). Each command typically performs one focused DB operation (fetch, create, update, delete).

- Accessed via dot syntax: `request.commands.posts.create(input)`
- Commands are defined as `CommandFactory` statics and registered per-module in `Commands+ModuleName.swift`
- **Endpoint-agnostic**: Commands define their own `Input` types, not API payloads. This is intentional — the same command is reused by both REST API controllers and Web Page controllers. The caller (API or Web) is responsible for mapping its endpoint-specific payload into the command's input type. Using a request payload directly as a command input is an anti-pattern.
- **Critical**: Commands must use `request.commandDB` (not `application.db`) for all database access. This is a `@TaskLocal` database instance defined in `CommandContext` that enables transaction support.

**Transactions**: When multiple commands need to run atomically, wrap them in a transaction:
```swift
request.commands.transaction { commands in
    let song = try await commands.songs.create(songInput)
    let notes = try await commands.notes.batchCreate(notesInput)
    return SongResponse(song: song, notes: notes)
}
```
The transaction sets `CommandContext.database` (a `@TaskLocal`) to the transaction DB. Since all commands read from `request.commandDB`, they transparently participate in the transaction without any modification. Outside a transaction, `commandDB` falls back to `application.db`. Nested transaction calls detect an existing transaction and reuse it.

### Permission System

Permissions follow the same composable, single-responsibility pattern as commands (`Sources/AuthKit/Permissions/`). Accessed via dot syntax on the request: `request.permissions.posts.create`.

Two permission types with a critical difference:

- **`Permission<Input>`** — Returns `User?`. For endpoints that are public but behave differently when authenticated. Example: listing posts returns only published posts for anonymous users, but also includes drafts for the authenticated author.
- **`AuthPermission<Input>`** — Returns `User` (non-optional). For strictly private endpoints. Throws `.unauthorized` if no user is authenticated, `.forbidden` if the user lacks the required role. Returns the verified user so commands can use it directly (e.g., assigning `user.userID` as the author of a new post).

Permissions are typically injected into commands via their `CommandFactory`:
```swift
CreatePostCommand(
    database: request.commandDB,
    permission: request.permissions.posts.create  // AuthPermissionResolver<Void>
)
```
Inside the command, `permission.grant()` both enforces authorization and provides the authenticated user:
```swift
let user = try await permission.grant()
let post = Post(authorID: user.userID, ...)
```

Each module defines its permissions in two files:
- `PermissionScopes+ModuleName.swift` — Declares the scope struct with permission properties and a computed property on `PermissionScopes` for dot-syntax navigation
- `Permission+ModuleName.swift` — Static permission definitions with the actual authorization logic

### Adding a New Module — Dot-Syntax Wiring

Both Commands and Permissions use `@dynamicMemberLookup` to enable dot-syntax access (e.g., `request.commands.posts.create`). When adding a new module, writing the command/permission logic alone is not enough — you must also add the extensions that wire it into the lookup chain:

- **Commands**: Add a computed property on `Commands` returning the new collection type, and register the command factories in `Commands+ModuleName.swift`
- **Permissions**: Add a computed property on `PermissionScopes` returning the new scope type, and define the scope struct in `PermissionScopes+ModuleName.swift`

Without these extensions, the dot-syntax won't resolve and the new module's commands/permissions will be inaccessible from the request.

### HTML & CSS Rules

No CSS frameworks. No older-browser polyfills. Modern CSS/HTML only.

- **Never use `<div>` when a semantic element exists** — `<article>`, `<section>`, `<nav>`, `<aside>`, `<main>`, `<footer>`, `<form>`, `<h1>`–`<h6>`, etc.
- **CSS targets tags, not classes** — e.g. `article`, `section > ul`. Only add a class when the same tag genuinely needs different visual variants that context can't distinguish.
- **Flexbox/grid for all layout.**
- **Navigation = `<a>` links.** No JS history manipulation. Dynamic content loading is fine only when it doesn't change the navigable URL state (e.g. pre-filling form fields from an API call).

### JavaScript

Vanilla JS only — no frameworks or build tools. Scripts live in `Public/Scripts/`.

**Controller pattern:** Complex features are split into single-responsibility Controller classes. Each controller owns one concern (editor state, drag-and-drop, gallery, keyboard shortcuts, persistence).

```javascript
class EditorController {
    constructor({ form, titleInput, bodyTextArea }, { persistence }) {
        // Store DOM elements
        this.form = form;
        this.titleInput = titleInput;
        // Store injected dependencies
        this.persistence = persistence;
        // Bind event handlers in constructor
        this._onInput = this.onInput.bind(this);
    }

    init() {
        this.titleInput.addEventListener('input', this._onInput);
    }

    destroy() {
        this.titleInput.removeEventListener('input', this._onInput);
    }
}
```

Key conventions:
- **Constructor signature**: DOM elements as first object, dependencies as second object
- **Lifecycle methods**: `init()` attaches listeners, `destroy()` removes them
- **Handler binding**: Bind handlers in constructor, store as `this._onEventName`
- **No static methods**: Even stateless operations should be instance methods on a controller, injected as a dependency — this keeps everything testable and consistent
- **Bootstrap**: Initialize everything in `DOMContentLoaded`, wire controllers together

```javascript
document.addEventListener('DOMContentLoaded', () => {
    const persistence = new PersistenceController();
    const editor = new EditorController({ form, titleInput }, { persistence });
    editor.init();

    const shortcuts = new ShortcutsController({
        onSave: () => editor.save()
    });
    shortcuts.init();
});
```

Reference implementation: `Public/Scripts/post-editor.js`

### Templates and Pages

Leaf templates (`Resources/Views/`) compose from shared fragments. `Shared/page.leaf` is the base layout with named slots (`main`, `toolbar`, `styles`, `scripts`). Page templates extend it via `#extend("Shared/page")` and `#export("main")`.

`Template<Model>` binds a Leaf template name to a ViewModel type for compile-time safety. `Page` maps a request into a ViewModel and renders it through a Template:
```swift
Page(template: .postEditor, parser: { req in /* → ViewModel */ })
```

Error recovery — two levels:
- Per-page: `page.recover(handler)` for page-specific errors
- Per-route-group: `RecoverMiddleware` wrapping a route collection
```swift
routes.grouped(RecoverMiddleware()).register(collection: PostsWebController())
```

Static assets: `Public/Styles/`, `Public/Scripts/`, `Public/Assets/`.

### Libraries

- **Core** (`Sources/Core/`) - Shared utilities: Module system, Page pattern, Form handling, Markdown, Validation
- **AuthKit** (`Sources/AuthKit/`) - Authentication with Apple Sign-In, User model, Permission system

## Database

PostgreSQL with Fluent ORM. Environment variables:
- Development: `DATABASE_HOST`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `DATABASE_NAME`
- Production: `DATABASE_URL` (connection string)

Migrations run automatically via `app.autoMigrate()` at startup.

### Schema Design

**Preview** is a polymorphic proxy that enables any entity type to participate in aggregated lists, own Notes, and be referenced by Posts — without those children needing direct knowledge of the parent's concrete type. Currently used by Catalogue items (Book, Song, Movie, Podcast), but the pattern is not Catalogue-specific. Any new entity type (e.g., a Friend/Contact) can adopt the same model: conform to `Previewable`, get a Preview, and immediately support Notes, Posts, and aggregated listing.

**Core relationship pattern — children reference parents via Preview, not directly:**
```
Previewable Entity (book/song/movie/podcast/any future type)
  ├── preview: Preview       (@Parent, required, key: "preview_id")
  ├── post: Post?            (@OptionalParent, key: "post_id")
  └── owner: User            (@Parent, key: "owner_id")

Preview (previews)
  ├── parentID: Int           (polymorphic, not a FK — points to the item's table)
  ├── parentType: String      ("book", "song", "movie", "podcast")
  ├── parentOwner: User       (@Parent, key: "parent_owner")
  ├── parentAccess: Access    (enum)
  ├── primaryInfo: String     (title)
  ├── secondaryInfo: String?  (artist/author)
  ├── image: Image?           (@OptionalParent, key: "image_id")
  └── externalLinks: [String]
  UNIQUE(parent_type, parent_id)
  ID type: UUID (not Int like other models)

Post (posts)
  ├── attachment: Preview?    (@OptionalParent, key: "attachment_id")
  ├── author: User            (@Parent, key: "author_id")
  ├── state: .published|.draft
  └── content, title, createdAt

Note (notes)
  ├── attachment: Preview     (@Parent, required, key: "attachment_id")
  ├── author: User            (@Parent, key: "author_id")
  ├── access: Access          (public/private per-note)
  ├── body: String
  └── quotes: [Quote]         (@Children)

Quote (quotes)
  └── note: Note              (@Parent, key: "note_id", cascade delete)
```

**Why this structure:** Aggregated lists query only the `previews` table — no joins across entity-specific tables. Detail pages use `parentType` + `parentID` to fetch the actual item from its dedicated table. Notes and Posts never reference parent entities directly — they hold a Preview FK (`attachment_id`), which provides the parent's type, ID, and owner. This avoids circular dependencies between modules and means Notes/Posts work with any Previewable entity without modification.

**`attachment` is a legacy name.** On both Post and Note, the Preview FK property is named `attachment` (from when it was just an optional add-on to Posts). It should be understood as "parent catalogue item reference" and is a candidate for renaming.

**Previewable protocol and PreviewModelMiddleware:** Catalogue items conform to `Previewable`. The `PreviewModelMiddleware` automatically creates, updates, and deletes the associated Preview record in sync with the item's lifecycle — no manual Preview management needed. Each item type configures how its fields map to Preview's `primaryInfo`/`secondaryInfo`/`image`.

**Quotes are ephemeral.** Quote entities are auto-extracted from a Note's markdown block quotes on every save. All existing Quotes for a Note are deleted and regenerated on each update. **Quote IDs are not stable** — never rely on persistent Quote IDs.

## Testing

Uses Swift Testing framework:
```swift
@Suite("Description")
struct SomeTests {
    @Test("Test description")
    func testSomething() async throws {
        #expect(result == expected)
    }
}
```
