# Catalogue Module

Catalogue is a **nested module** with its own inner `ModuleRegistry`. Sub-modules: Books, Movies, Songs, Podcasts, plus a shared Catalogue controller.

## Adding New Catalogue Item Types

New catalogue item types are added as sub-modules inside Catalogue, not as top-level modules.

1. Create a new directory under `Catalogue/` (e.g., `Catalogue/Games/`)
2. Follow the standard module structure
3. Register in `Catalogue.swift`'s inner `ModuleRegistry`

## Previewable Pattern

All catalogue items conform to `Previewable`. This enables:

- Aggregated listing via `previews` table
- Notes attached to items
- Posts referencing items

The `PreviewModelMiddleware` automatically manages Preview records:
- Creates Preview when item is created
- Updates Preview when item changes
- Deletes Preview when item is deleted

Each item type configures how its fields map to Preview's `primaryInfo`/`secondaryInfo`/`image`.

## Schema Reference

See `/.claude/docs/database.md` for full Preview pattern and relationship diagrams.
