---
description: Automatic synthesis - scans the vault for unnamed patterns and writes synthesis pages without being asked
category: thinking
triggers_en: ["synthesize", "auto-synthesis", "make synthesis notes", "find unnamed patterns"]
---

Use the obsidian-second-brain skill. Execute `/obsidian-synthesize`:

This command can run manually or as a scheduled agent. It thinks for you.

1. Read `_CLAUDE.md` first if it exists in the vault root
2. Read `index.md` to understand all existing pages
3. Read recent operation log: read the last 2-3 `Logs/YYYY-MM-DD.md` files; if no daily log exists yet, use `.codex/references/log.md` for the log format (last 20 entries)

4. Scan for synthesis opportunities - spawn parallel subagents:

   - **Cross-source agent**: read all sources ingested in the last 7 days (`01.raw/`). Find concepts that appear in 2+ unrelated sources. If the same idea shows up in a podcast transcript AND an article AND a daily note - that's a synthesis candidate.
   
   - **Entity convergence agent**: scan `02.wiki/entities/` for people who appear together in multiple contexts but have no explicit connection page. If Person A and Person B keep showing up in the same projects/decisions - write a connection note.
   
   - **Concept evolution agent**: scan `02.wiki/concepts/` for ideas that have been updated 3+ times. Track how the concept evolved - write a "Concept Evolution" section showing the timeline of how the user's thinking changed.
   
   - **Orphan rescue agent**: find notes in `02.wiki/` with no incoming links that contain claims or ideas that SHOULD be linked to existing pages. Create the missing links and explain why.

5. For each synthesis found:
   - Create `02.wiki/concepts/Synthesis - Title.md` with:
     ```yaml
     ---
     date: YYYY-MM-DD
     tags:
       - concept
       - synthesis
     auto_generated: true
     ---
     ```
   - Document: what pattern was found, which sources/notes it came from (with links), what it means, and a suggested action
   - Link the synthesis page FROM all the source notes it references

6. Update `index.md` with new synthesis pages
7. Append to the operation log: write `**HH:MM** - synthesize | X synthesis pages created, Y orphans rescued, Z connections found` to `Logs/YYYY-MM-DD.md` (create `Logs/` and the daily file if missing; see `.codex/references/log.md` for the log format)
8. If a daily note exists for today, add a Synthesis section with a brief summary

The vault should generate its own insights. Not just when asked - on its own schedule.

---

**AI-first rule:** Every note created or updated by this command MUST follow `.codex/references/ai-first-rules.md` - `## For future Claude` preamble, rich frontmatter (`type`, `date`, `tags`, `ai-first: true`, plus type-specific fields), recency markers per external claim, mandatory `[[wikilinks]]` for every person/project/concept referenced, sources preserved verbatim with URLs inline, and confidence levels where applicable. The vault is for future-Claude retrieval - not human reading.

**Anti-fabrication:** Search exhaustively before claiming any note, person, or file is absent - false absence is the most common failure mode - and never invent facts, entities, or dates (mark unknowns as `TBD`). See the anti-fabrication and search-completeness hard rules in `.codex/references/ai-first-rules.md`.
