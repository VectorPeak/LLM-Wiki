---
description: Save everything worth keeping from this conversation to the vault
category: vault
triggers_en: ["save this", "save the conversation", "save to vault", "obsidian save"]
---

Use the obsidian-second-brain skill. Execute `/obsidian-save`:

1. Read `_CLAUDE.md` first if it exists in the vault root
2. Scan the entire conversation and identify all vault-worthy items: decisions, tasks, people mentioned, projects started, ideas, learnings, deals, mentions/shoutouts, AND content-worthy items (hooks, data points, swipe-file material, research findings)
3. Group items by type: people, projects, tasks, decisions, ideas, deals, content
4. Spawn parallel subagents - one per group - so all note types are handled simultaneously:
   - **People agent**: search for each person, create or update notes, log interactions
   - **Projects agent**: search for each project, create or update notes
   - **Tasks agent**: parse tasks, add to the right kanban columns
   - **Decisions agent**: find relevant project notes, append to Key Decisions sections
   - **Concepts/ideas agent**: search `02.wiki/concepts/`, `01.raw/01.Inbox/`, and `02.wiki/**` for related notes, create or append in `02.wiki/concepts/`
   - **Content agent** (if a `04.output/SocialMedia/` folder exists in the vault): scan for content-worthy items and route them:
     - **Hooks, angles, contrarian takes** -> append to `04.output/SocialMedia/ideas.md` (dated bullet)
     - **Specific numbers, stats, reusable data points** -> append to `04.output/SocialMedia/data-points.md` (with source)
     - **External posts that hit + why** -> append to `04.output/SocialMedia/swipe-file.md` (link + reason)
     - **Research findings, frameworks, methodologies** -> create `04.output/SocialMedia/research/YYYY-MM-DD - topic.md`
5. After all agents complete: update today's daily note with links to everything saved
6. Report back: a clean list of what was saved and where

Search before creating anything - duplicate notes are vault rot. Propagate every write to boards, daily note, and linked notes. Never create an orphaned note.

The content agent only runs if `04.output/SocialMedia/` exists in the vault. If it doesn't exist, skip silently - don't create the folder unprompted.

---

**AI-first rule:** Every note created or updated by this command MUST follow `.codex/references/ai-first-rules.md` - `## For future Claude` preamble, rich frontmatter (`type`, `date`, `tags`, `ai-first: true`, plus type-specific fields), recency markers per external claim, mandatory `[[wikilinks]]` for every person/project/concept referenced, sources preserved verbatim with URLs inline, and confidence levels where applicable. The vault is for future-Claude retrieval - not human reading.

**Anti-fabrication:** Search exhaustively before claiming any note, person, or file is absent - false absence is the most common failure mode - and never invent facts, entities, or dates (mark unknowns as `TBD`). See the anti-fabrication and search-completeness hard rules in `.codex/references/ai-first-rules.md`.
