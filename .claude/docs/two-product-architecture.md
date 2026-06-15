# Two-Product Architecture — superseded

This document has been superseded by the three-app pivot. The "two products from one core" framing
(owner app + future guest read-mode as Product 1; CloudKit consumer app as Product 2) split into
**three apps** once the real product shape became clear:

- **Reader** — public, read-only, on-demand ETag cache
- **Author** — the owner, offline-first, full backend sync (this is what the old "Product 1" became)
- **Personal** — CloudKit-only consumer app (the old "Product 2")

See **`.claude/docs/native-apps-architecture.md`** for the current canonical architecture. It carries
forward the still-valid decisions from this doc (the composition seam, the CloudKit schema
constraints) and explains what changed and why.
