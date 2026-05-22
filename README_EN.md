<div align="center">

# LLM Wiki | Personal LLM Knowledge Base

**An Obsidian knowledge network for LLMs, agents, RAG, fine-tuning, evaluation, and AI engineering practice**

![knowledge](https://img.shields.io/badge/knowledge-LLM%20%7C%20Agent%20%7C%20RAG-blue)
![vault](https://img.shields.io/badge/vault-Obsidian-7C3AED)
![wiki-notes](https://img.shields.io/badge/wiki%20notes-190-brightgreen)
![raw-files](https://img.shields.io/badge/raw%20files-158-orange)
![license](https://img.shields.io/badge/license-CC%20BY--NC%204.0-lightgrey)

[Chinese](./README.md) | **English**

```text
RAW sources  ->  structured Wiki notes  ->  linkable, searchable, reusable knowledge network
```

</div>

---

## Introduction

LLM Wiki is a public Obsidian vault for learning and organizing modern AI engineering. It focuses on large language models, agents, RAG, fine-tuning, reinforcement learning, evaluation, inference optimization, and practical AI engineering tools

The goal is not to collect everything. The goal is to turn useful sources into a compact, navigable, and reusable knowledge graph. In this repository, `RAW` is the ore, `Wiki` is the refined knowledge alloy, and `Schema` is the process specification that keeps future maintenance consistent

## Why this exists

The hard part of learning LLM engineering is often not the lack of material, but the overload of material, weak hierarchy, isolated concepts, and notes that cannot be reused after reading. LLM Wiki compresses papers, articles, projects, courses, interview questions, and personal notes into a structure that can be queried and expanded over time

This vault follows a Karpathy-style learning workflow: keep raw materials, rewrite important ideas in your own words, and connect knowledge through links, comparisons, questions, and engineering scenarios

## Core structure

```text
.
|-- RAW/       # Source layer: papers, websites, books, courses, project materials, study logs
|-- Wiki/      # Knowledge layer: concepts, methods, questions, projects, domains, source notes
|-- Schema/    # Rule layer: ingestion, structure, style, source policy, query, and lint rules
`-- .obsidian/ # Obsidian vault settings and selected plugin metadata
```

### RAW: source layer

`RAW` stores materials before they are fully distilled into stable knowledge, including papers, web pages, courses, books, GitHub project materials, interview questions, algorithm notes, study logs, and personal notes

### Wiki: knowledge layer

`Wiki` is organized by knowledge role rather than by source type. It is closer to a set of knowledge graph nodes, where each note should answer a clear question or carry a reusable concept

| Directory | Purpose |
|---|---|
| [`Wiki/concepts`](./Wiki/concepts) | Atomic concepts such as Transformer, KV Cache, GRPO, and RAG chunking |
| [`Wiki/methods`](./Wiki/methods) | Learning paths, engineering methods, evaluation methods, and practice frameworks |
| [`Wiki/questions`](./Wiki/questions) | Interview-style questions, research-style questions, and confusing problems |
| [`Wiki/projects`](./Wiki/projects) | Projects such as LangChain, LangGraph, LlamaIndex, and RAGFlow |
| [`Wiki/domains`](./Wiki/domains) | Domains such as agent engineering, RAG, and model internals |
| [`Wiki/sources`](./Wiki/sources) | Rewritten source-level notes derived from raw materials |
| [`Wiki/comparisons`](./Wiki/comparisons) | Side-by-side notes for concepts that are easy to confuse |

### Schema: rule layer

`Schema` defines how this knowledge base should be maintained, including frontmatter, ingestion, structure, style, source policy, query, and lint rules. It acts like a small operating manual for the vault, preventing future human or AI maintenance from becoming arbitrary file dumping

## Recommended entry points

- [`Wiki/index.md`](./Wiki/index.md): main index for browsing the vault structure
- [`Wiki/overview.md`](./Wiki/overview.md): vault positioning, structure, and current status
- [`Wiki/hot.md`](./Wiki/hot.md): recent context and high-frequency workspace
- [`Schema/AGENTS.md`](./Schema/AGENTS.md): rules for AI-assisted maintenance
- [`Schema/style.md`](./Schema/style.md): writing style rules
- [`Schema/query.md`](./Schema/query.md): query and usage rules

## Current topics

This knowledge base currently focuses on these areas:

- Model internals: Transformer, Attention, KV Cache, MoE, pre-training, and fine-tuning
- RAG engineering: chunking, embedding, reranking, PDF parsing, evaluation, and pipelines
- Agent systems: ReAct, Reflection, tool calling, memory systems, human intervention, and long-running tasks
- AI coding tools: Claude Code, repository-level context, and spec-driven development
- Training and evaluation: SFT, RLHF, GRPO, LM Evaluation Harness, and inference optimization
- Algorithms and interviews: classical machine learning, deep learning, NLP, data structures, and algorithms

## Design principles

- **Source first**: important claims should trace back to original sources whenever possible
- **Top-down learning**: start with the global picture before diving into mechanisms and details
- **Small pieces, dense links**: avoid long disconnected essays and prefer reusable connected notes
- **Engineering bias**: explain not only what something is, but how it works, when it fails, and how to use it in practice
- **Public-safe by default**: local caches, private clippings, upload history, agent state, and secrets stay out of Git

## How to use

For online reading, start from [`Wiki/index.md`](./Wiki/index.md), then follow `domains`, `methods`, `concepts`, and `questions` layer by layer

For local use, clone the repository and open the root directory as an Obsidian vault:

```bash
git clone https://github.com/VectorPeak/LLM-Wiki.git
```

Then select the repository directory in Obsidian to use wikilinks, full-text search, graph view, and local plugin features

## Public boundary

This is the public-facing version of the vault. The following content is intentionally kept out of Git:

- full article clippings and extraction caches
- image upload plugin history
- local agent plugin state
- Obsidian workspace state
- `.env`, secrets, account credentials, and other private configuration

The public repository is intended to show the knowledge structure and curated notes, not every private scratchpad or tool artifact

## Status

This vault is under active development. Some older notes may still have rough structure, incomplete links, or encoding artifacts from previous imports. The long-term direction is to make the `Wiki` layer cleaner, denser, and more useful than the raw source layer

## License

Original knowledge notes, documentation, and curated written content in this repository are licensed under [CC BY-NC 4.0](./LICENSE), unless a specific file states otherwise

This means others may copy, share, and adapt the repository's original content for non-commercial purposes, provided that they give appropriate credit, indicate changes, and include a license link

Third-party source materials, quotations, papers, webpages, clippings, and project documents under `RAW/` remain the property of their respective authors or rights holders and should be used according to their original licenses and source terms
