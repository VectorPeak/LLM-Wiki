---
type: meta
title: "Lint Report 2026-05-14"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - meta
  - lint
related:
  - "[[index]]"
  - "[[log]]"
sources: []
raw_bucket: ""
source_path: ""
---

# Lint Report: 2026-05-14

## Summary

- Pages scanned: 79
- Issues found: 0 blocking issues
- Auto-fixed: normalized `RAW/10.Interview` path casing after the folder was renamed.
- Needs review: entity pages and comparison pages are still intentionally empty.

## Page Counts

- Root entry pages: 4
- Sources: 24
- Concepts: 28
- Methods: 13
- Domains: 6
- Questions: 4
- Meta reports: 1

## Orphan Pages

Not fully evaluated in this lightweight lint pass. A deeper graph pass should distinguish acceptable entry/source pages from true orphan pages.

## Dead Links

None found. All Obsidian wikilinks resolve to current Wiki Markdown basenames.

## Duplicate Concepts

No blocking duplicate concept pages found in this pass. `agent-interview-summary-1` and `agent-summary-2026-03` are overlapping source pages by design and point into the same concept set.

## Missing Pages

- `Wiki/entities/` has no entity pages yet.
- `Wiki/comparisons/` has no comparison pages yet.
- `Wiki/projects/` has no project pages yet.

These are not blocking for the current ingest batches.

## Missing Sources

No missing `source_path` targets found. All non-empty `source_path` values resolve to existing `RAW` files or directories.

## Frontmatter Gaps

None found. All Wiki Markdown files start with YAML frontmatter and include the required fields.

## Stale Claims

Not evaluated. Pages based on `RAW/03.Self-Notes` explicitly mark themselves as self-note derived and require external verification for product/version/current-state claims.

## Cross-Reference Gaps

Not fully evaluated. The first priority was structural validity after multi-batch `/Ingest`.

## Stale Index Entries

None found in current pass. `Wiki/index.md` was rebuilt to include the current source, domain, concept, method and question pages.

## Empty Sections

No blocking empty generated pages found. Some index sections remain intentionally marked as not yet ingested.
