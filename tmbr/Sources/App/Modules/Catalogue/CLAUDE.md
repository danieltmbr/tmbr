# Catalogue Module

Nested module with inner `ModuleRegistry`. Sub-modules: Books, Movies, Songs, Podcasts.

## When Adding a New Catalogue Item Type

1. Create directory under `Catalogue/` (e.g., `Catalogue/Games/`)
2. Conform model to `Previewable` protocol
3. Configure field mappings to Preview's `primaryInfo`/`secondaryInfo`/`image`
4. Register in `Catalogue.swift`'s inner `ModuleRegistry`

`PreviewModelMiddleware` automatically manages Preview records — no manual Preview creation needed.

## Before Database/Schema Work

Read `/.claude/docs/database.md` for Preview pattern and relationship diagrams.
