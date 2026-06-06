# Incident: Language picker regressions after PR #176

**Date**: 2026-06-06
**Severity**: Medium
**Status**: Resolved

## What happened

After merging PR #176 (language picker UI + push notification filtering), three regressions were found:

1. Creating a new note on a catalogue item detail page always saved `language = en`, even when the user had selected `hu` in the picker.
2. The post editor language select defaulted to `hu` for new posts instead of `en`.
3. Clicking the globe/language button in the toolbar on detail pages and editor pages did nothing — the language filter panel never opened.

## Root cause

**Bug 1 — note language not saved:** Every `createNote` handler in the six catalogue web controllers (`Songs`, `Books`, `Podcasts`, `Movies`, `Albums`, `Playlists`) decoded the `language` field from the payload but never forwarded it to `CreateNoteInput`. The struct's default of `.en` was always used.

**Bug 2 — post editor wrong default:** `post-editor.leaf` used `#if(language=="hu"){ selected }` without spaces around `==`. Leaf evaluates this as a truthiness check on `language` rather than a string comparison, so both `en` and `hu` options rendered with the `selected` attribute simultaneously. The browser picks the last one, so `hu` always won.

**Bug 3 — language panel not wired up:** `filter.js` (which initialises `FilterController` for all `[data-filter-panel]` elements) was only loaded on list/catalogue pages. The global language panel button in `page.leaf` is present on every page, but without `filter.js` the click handler was never attached on detail and editor pages.

## How it was fixed

- Added `language: payload.language ?? .en` to `CreateNoteInput(...)` in all six catalogue web controllers.
- Changed the post editor Leaf syntax from `#if(language=="hu"){ selected }` to `#if(language == "hu"):selected#endif`, matching the convention used in all other templates.
- Moved `<script src="/Scripts/Shared/filter.js"></script>` into `scripts.leaf` (loaded globally), and removed the now-redundant conditional loads from `catalogue.leaf`, `list.leaf`, and `posts.leaf`.

## Prevention

- [x] New test: `AlbumTests/createNote_withNonDefaultLanguage_savesLanguage` — POSTs a note with `language=hu` to `/albums/:id/notes` and asserts the persisted note has `language == .hu`.
- [ ] Process change: when a `createNote`-style handler is added for a new catalogue type, the test suite should include a note-language round-trip test for that type.
- [ ] Leaf convention: prefer `:...#endif` syntax with spaces around operators; document this in `.claude/docs/frontend.md` to avoid silent comparison failures.

## Tests added

`Tests/AppTests/Catalogue/AlbumTests.swift` — `createNote_withNonDefaultLanguage_savesLanguage`
