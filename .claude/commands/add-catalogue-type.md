Add a new catalogue item type end-to-end. The type name will be provided as an argument or in context — use it throughout.

Read `tmbr-web/.claude/docs/database.md` and `tmbr-web/.claude/docs/modules.md` before starting. Read `tmbr-web/.claude/docs/catalogue-blueprint.md` (in `tmbr-web/.claude/docs/plans/`) for the full layer-by-layer reference.

Work through these steps in order. Each step depends on the previous.

---

## Step 0 — Fluent Model & Migration

This step has no reference implementation for new types — do it before anything else.

1. Create `Sources/App/Modules/Catalogue/[Type]/Models/[Type].swift`
   - `final class [Type]: Model, @unchecked Sendable`
   - Fields: all domain-specific fields + `@Parent var preview: Preview` + `@Parent var owner: User` + `@OptionalParent var post: Post?`
   - Conform to `Previewable` — configure `primaryInfo`, `secondaryInfo`, `image` field mappings
   - Add `PreviewModelMiddleware<[Type]>` in the module's `configure()` so Preview records stay in sync automatically

2. Create the migration: `Sources/App/Modules/Catalogue/[Type]/Models/Create[Type]Migration.swift`
   - Create the `[type]s` table with all fields
   - Register in `configure.swift` alongside other migrations

3. Run `swift run Backend serve` and confirm the migration applies cleanly. Fix any issues before proceeding.

---

## Steps 1–9 — Web Implementation

Follow the layer-by-layer guide in `tmbr-web/.claude/docs/plans/catalogue-blueprint.md` exactly. The layers in order:

1. Platform metadata struct + extractors
2. Commands extension (lookup, search, metadata)
3. Editor payload
4. API controller
5. Web: page view models (list, detail, editor, preview)
6. Web controller
7. Module `boot()` — register routes
8. Leaf templates (list, editor, detail)
9. Editor JavaScript

---

## Step 10 — tmbr-core

After the API controller is complete:

1. Add the response DTO (e.g. `[Type]Response`) to `tmbr-core/Sources/TmbrCore/` as `Codable & Sendable`
2. Add any input payload the native app will send (e.g. `Create[Type]Payload`) if applicable
3. In `tmbr-web`, import `TmbrCore` and return the shared type from the API controller — do not define a separate DTO in `tmbr-web`
4. Confirm `tmbr-core` builds on its own: `swift build --package-path tmbr-core`

---

## Final Checklist

Before marking this done:

- [ ] Migration applied cleanly (`swift run Backend serve` starts without errors)
- [ ] All 9 web layers present (metadata, commands, payload, API controller, 4 view models, web controller, routes, templates, JS)
- [ ] Detail template loads `editor.css`, `persistence.js`, `note-detail.js`
- [ ] Detail view model includes `notesEndpoint: String`
- [ ] No separator characters hardcoded in Leaf templates — computed `info: String?` in view model
- [ ] `tmbr-core` updated with response DTO (and input payload if applicable)
- [ ] `tmbr-core` builds standalone
- [ ] At least one command test written (create + ownership check)
- [ ] Artwork resolution uses gallery lookup before upload (no duplicate images)
- [ ] CSRF token generated in `Page` static, validated before DB work in editor handler
