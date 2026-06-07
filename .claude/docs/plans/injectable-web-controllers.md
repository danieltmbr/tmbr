# Plan: Injectable Web Controllers (`request.controllers.*`)

## Motivation

Commands (`request.commands.*`) and permissions (`request.permissions.*`) are injected, swappable closure-based types — they encapsulate a single unit of business logic and can be composed or replaced without touching callers.

The web layer currently has no equivalent. Self-contained HTTP features (decode request → run commands → render response) end up either duplicated across controllers or consolidated as hardcoded static helpers (e.g. `NotesWebController.createNote(attachmentID:on:)`). These helpers are better than duplication but they are not injectable, not composable, and don't signal clearly whether they're infrastructure or one-off utilities.

## Proposed Pattern

A `request.controllers` registry, following the same closure-based struct pattern as `CommandFactory` / `AuthPermissionResolver`:

```swift
request.controllers.notes.create(attachmentID: id)  // → Response
request.controllers.notes.edit(noteID: id)           // → Response
```

Each controller is a struct wrapping a closure, built from the request context (commands, view renderer, etc.) and registered the same way commands are — via a `ControllerFactory` and a computed property extension on `Request`.

## Sketch

```swift
struct WebController<Input, Output> {
    private let resolve: @Sendable (Input) async throws -> Output
    func callAsFunction(_ input: Input) async throws -> Output {
        try await resolve(input)
    }
}

struct NoteWebControllers {
    let create: WebController<UUID, Response>   // attachmentID → Response
    let edit:   WebController<NoteID, Response> // noteID → Response
}

extension Request {
    var controllers: WebControllerRegistry { ... }
}
```

Factories are defined close to the feature they own (e.g. `Notes/Routes/Web/`) and wired up in the module's `boot`.

## Benefits

- Same injection/composability story as commands and permissions
- Testable: swap in a stub factory in tests
- Removes the conceptual ambiguity of "is this a static helper or infrastructure?"
- Makes the call site (`request.controllers.notes.create(attachmentID: id)`) read like the existing layers

## Current workaround

`NotesWebController.createNote(attachmentID:on:)` — a static method, honest about being a concrete utility but not injectable. Fine for now; replace when this pattern is adopted.

## Prior art in the codebase

- `CommandFactory` + `Commands+Notes.swift` — exact same struct-wrapping-closure pattern
- `AuthPermissionResolver` + `PermissionScopes+Notes.swift` — same, for auth
