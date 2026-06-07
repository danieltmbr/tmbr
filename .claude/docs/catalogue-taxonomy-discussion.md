# Catalogue Taxonomy: Resource vs Topic vs Tag

## Why this document exists

During the `orphan-previews` feature work (June 2026), we discussed whether the catalogue category model should be extended to support a "topic" or "cross-media" grouping concept. We decided against it for now. This document captures the reasoning so we can revisit later with context.

## The two axes

The category system currently models one axis: **content format / resource type**.

| Kind | Examples | Description |
|------|----------|-------------|
| `catalogue` | song, album, book, movie, podcast | Model-backed items with dedicated metadata schemas and routes |
| `promotable` | track | Awaiting promotion to a full catalogue type |
| `orphan` | recipe, guide, link, workout | User-defined items with no backing model; format-agnostic |
| `collection` | music | Display-only grouping of related catalogue types (added this session) |

A second, orthogonal axis would be **topic / domain** — *what the item is about*, regardless of format:

- A recipe book → format=book, topic=recipes
- A Masterclass cooking video → format=movie, topic=recipes
- A handwritten recipe card → format=orphan/recipe, topic=recipes

The current system has no way to connect these three under a single "Recipe" umbrella.

## Why we didn't build it

1. **Not a real problem yet.** In practice, a "Recipe" orphan item is the recipe itself — format-agnostic, accessed via its external link. The user doesn't need it to also appear in `/books` or `/movies`. The cross-media tagging problem only becomes real if you want one item to live in multiple typed views simultaneously, which isn't a current requirement.

2. **Songs/albums/playlists are different.** The `music` collection groups content *formats* that are all the same domain (music listening). That's why a collection works there — it's collapsing near-identical display entries, not crossing unrelated media types.

3. **The scope creep risk.** Introducing a tag/topic layer would require: a new model (Tag), many-to-many relationships between tags and all item types (Book, Movie, Preview, Song…), UI for tagging and filtering by tag, and API surface. That's a significant feature.

## If we do build it

The right model would be a **tag** (not a category mutation):

- `Tag` entity: `id`, `slug`, `name`
- Join tables: `book_tags`, `movie_tags`, `preview_tags`, `song_tags`, etc.
- Tags appear as a separate filter dimension, not mixed with the type/format filter
- The catalogue and per-type pages would each support filtering by tag

This keeps categories as "what kind of thing is this" and tags as "what is this about" — two cleanly separated concepts.

## Current status

Not built. The existing `collection` kind added in this session only handles the display-grouping of catalogue content types (music). It is not a general-purpose topic system.
