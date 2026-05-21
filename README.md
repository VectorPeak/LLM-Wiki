# LLM Wiki

> A Karpathy-style personal LLM knowledge base: raw materials stay raw, distilled notes become linked knowledge, and the system stays simple enough to keep improving.

LLM Wiki is a public Obsidian vault for learning and organizing modern AI engineering. It focuses on large language models, agents, RAG, fine-tuning, reinforcement learning, evaluation, inference, and the practical tools around them.

The goal is not to collect everything. The goal is to turn useful sources into a compact, navigable knowledge graph.

## What This Is

This repository follows a Karpathy-style knowledge workflow:

1. Keep original materials close to the work.
2. Rewrite important ideas in plain language.
3. Prefer small connected notes over large disconnected summaries.
4. Let code, papers, diagrams, and interview questions reinforce each other.
5. Keep the system inspectable: folders, Markdown, Git, and Obsidian links.

In practice, that means this vault is organized as a pipeline:

```text
RAW sources -> structured Wiki notes -> links, questions, methods, and concepts
```

## Repository Structure

```text
.
├── RAW/       # Original source materials: papers, notes, websites, books, logs
├── Wiki/      # Distilled knowledge nodes for reading, linking, and review
├── Schema/    # Maintenance rules for ingestion, style, structure, and querying
└── .obsidian/ # Obsidian vault settings and selected plugin metadata
```

### RAW

`RAW` is the source layer. It contains materials before they are fully rewritten into durable knowledge:

- papers and research notes
- self-notes and learning logs
- GitHub/project snapshots
- website and article captures
- book/course material
- interview and algorithm notes

### Wiki

`Wiki` is the distilled layer. It is organized by knowledge role rather than by source format:

- `concepts/`: atomic concepts such as Transformer, KV Cache, RAG chunking, GRPO
- `methods/`: reusable learning paths and engineering methods
- `questions/`: interview-style or research-style questions
- `projects/`: tools and frameworks such as LangChain, LangGraph, LlamaIndex, RAGFlow
- `domains/`: broader areas such as agent engineering, RAG, model internals
- `sources/`: source-level summaries and rewritten source notes
- `comparisons/`: side-by-side notes for confusing pairs

### Schema

`Schema` defines how the vault should be maintained. It is the rule layer for future updates: ingestion, frontmatter, source policy, structure, style, and linting.

## Design Principles

- **Source first**: important claims should trace back to a source when possible.
- **Top-down learning**: each topic should start from the big picture, then move into mechanisms and details.
- **Small pieces, dense links**: knowledge should be broken into reusable nodes and connected with Obsidian wikilinks.
- **Engineering bias**: notes should answer how something works, when it fails, and how it is used in practice.
- **Public-safe by default**: local caches, private clippings, upload history, and agent state should stay out of Git.

## How To Use

Open this folder as an Obsidian vault.

Recommended entry points:

- `Wiki/index.md`: main index
- `Wiki/overview.md`: vault overview
- `Wiki/hot.md`: active context and recent work
- `Schema/AGENTS.md`: maintenance rules for AI-assisted updates

If using Obsidian Git, the repository is already a normal Git repository and can be synced with:

```text
Obsidian Git: Commit-and-sync
```

## Public Boundary

This is a public-facing version of the vault. Some local-only data is intentionally ignored:

- article clippings and extraction caches
- image upload plugin history
- local agent plugin state
- Obsidian workspace state
- environment files and secrets

The public repository is intended to show the knowledge structure and curated notes, not every private scratchpad or tool artifact.

## Status

This vault is under active development. Some older notes may contain rough structure, incomplete links, or encoding artifacts from previous imports. The long-term direction is to make the `Wiki` layer cleaner, denser, and more useful than the raw source layer.

## License

No formal license is declared yet. Treat the original source materials under their respective licenses and copyrights.

