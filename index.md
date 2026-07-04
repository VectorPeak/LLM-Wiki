---
date: 2026-06-15
type: index
tags: [index, vault-map]
ai-first: true
---

## For future Claude
This is the navigation entrypoint for the LLM_wiki vault. The vault uses numbered top-level layers: immutable source material under `01.raw/`, maintained notes under `02.wiki/`, and the active Mentor learning system under `03.Mentor/`.

## Core Files

- [[_CLAUDE]] - operating manual for AI agents working in this vault
- [.codex/references/SOUL.md](.codex/references/SOUL.md) - identity, preferences, and long-term style notes
- [[CRITICAL_FACTS]] - short always-load facts
- [.codex/references/log.md](.codex/references/log.md) - pointer to append-only daily operation logs
- [.codex/references/INSTALL.md](.codex/references/INSTALL.md) - installation and Codex CLI setup reference

## Raw Layer

- `01.raw/00.WorkSpace/` - scratch space and staging
- `01.raw/01.Inbox/` - intake queue for raw clips and imports
- `01.raw/02.DailyNotes/` - raw daily-note source files
- `01.raw/03.SelfNotes/` - personal notes and self-study material
- `01.raw/04.Interview/` - interview notes, question banks, and spreadsheet sources
- `01.raw/05.Wechat/` - WeChat source clippings by author
- `01.raw/06.Zhihu/` - Zhihu source clippings by author
- `01.raw/07.Website/` - website captures and exported web articles
- `01.raw/08.Research/` - verified paper PDFs and metadata
- `01.raw/09.Book&Courses/` - books, courses, and manuals
- `01.raw/10.GitHub/` - raw project snapshots
- `01.raw/11.Leetcode/` - problem sets and practice notes
- `01.raw/12.Transcripts/` - reserved transcript intake
- `01.raw/13.Videos/` - reserved video intake

## Wiki Layer

- `02.wiki/entities/` - people, companies, tools, organizations
- `02.wiki/concepts/` - concepts, patterns, methods, synthesis
- `02.wiki/projects/` - project notes
- `02.wiki/daily/` - daily notes
- `02.wiki/logs/` - work and dev logs
- `02.wiki/reviews/` - review notes
- `02.wiki/tasks/` - task notes
- `02.wiki/decisions/` - decision records

## Operational Folders

- `boards/` - kanban boards
- `Bases/` - Obsidian Bases views
- `Logs/` - append-only operation logs
- `_trash/` - soft-deleted notes

## Current Catalog

`02.wiki/` is scaffolded but currently empty. `01.raw/` already contains imported source material across the major source folders, so start there when orienting yourself. Use `/obsidian-save`, `/obsidian-capture`, `/obsidian-ingest`, or `/research` to begin turning raw material into maintained notes.


## Wiki Layer Protocol

- [[LLM_wiki Wiki Layer Protocol]] - stable `/ingest`, `/query`, `/lint` operating protocol.
- [[Wiki Write Plan]] - `/ingest` routing object for `02.wiki` sublayers.
- [[Knowledge Diff]] - comparison output between raw source and existing wiki knowledge.
