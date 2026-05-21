# LLM Wiki

> 一个 Karpathy 风格的个人 LLM 知识库：原始资料保持原始，重要知识被重写、压缩、链接，并持续沉淀为可查询的知识网络。

## 中文说明

LLM Wiki 是一个公开的 Obsidian 知识库，用来学习和整理现代 AI 工程相关内容。主题包括大语言模型、Agent、RAG、微调、强化学习、评估、推理优化，以及围绕这些方向的工程工具和实践方法。

这个仓库的目标不是“收集一切”，而是把真正有价值的资料加工成一个紧凑、可导航、可复用的知识图谱。

## 这是一个 Karpathy 风格的知识库

这里所说的 Karpathy 风格，指的是一种偏工程、偏第一性原理、偏可解释的学习方式：

1. 原始资料不要急着丢掉，先保留在 `RAW`。
2. 重要概念要用自己的话重写，而不是只摘抄。
3. 笔记要尽量小而清晰，方便被链接和复用。
4. 代码、论文、图解、面试题、工程经验要互相印证。
5. 系统要足够简单：Markdown、文件夹、Git、Obsidian 链接即可。

这个库的核心流水线是：

```text
RAW 原始资料 -> Wiki 结构化笔记 -> 概念、方法、问题、项目和领域网络
```

## 仓库结构

```text
.
|-- RAW/       # 原始资料层：论文、网页、书籍、课程、自笔记、项目资料
|-- Wiki/      # 知识产品层：概念、方法、问题、项目、领域和来源笔记
|-- Schema/    # 维护规则层：摄取、结构、风格、来源、查询和 lint 规则
`-- .obsidian/ # Obsidian 库配置和部分插件元数据
```

### RAW

`RAW` 是原始资料层，用来保存还没有完全加工成稳定知识的材料，包括：

- 论文和研究资料
- 自笔记和学习日志
- GitHub 项目资料
- 网页、文章和文档
- 书籍、课程和教程
- 面试题、算法题和工程笔记

### Wiki

`Wiki` 是知识产品层。它不按资料来源分类，而按知识角色分类：

- `concepts/`：原子概念，例如 Transformer、KV Cache、GRPO、RAG chunking
- `methods/`：学习路径、工程方法、评估方法和实践框架
- `questions/`：面试型问题、研究型问题和容易混淆的问题
- `projects/`：LangChain、LangGraph、LlamaIndex、RAGFlow 等项目
- `domains/`：Agent 工程、RAG、大模型底层原理等领域
- `sources/`：对原始资料进行重写后的来源笔记
- `comparisons/`：容易混淆对象的对比笔记

### Schema

`Schema` 是维护规则层，描述这个知识库应该如何被持续更新。它包含 frontmatter、ingest、structure、style、source-policy、query、lint 等规则。

## 设计原则

- **来源优先**：重要判断尽量能回到原始来源。
- **自顶向下**：先讲全局定位，再讲机制细节。
- **小块知识，高密度链接**：避免大而散的长文堆积。
- **工程导向**：不仅讲“是什么”，也讲“怎么用、何时失败、如何落地”。
- **公开安全**：本地缓存、剪藏全文、上传历史、Agent 状态和密钥不进入公开仓库。

## 如何使用

用 Obsidian 打开这个目录即可：

```text
D:\LLMWiki\LLMWiki
```

推荐入口：

- `Wiki/index.md`：主索引
- `Wiki/overview.md`：知识库总览
- `Wiki/hot.md`：近期上下文
- `Schema/AGENTS.md`：AI 辅助维护规则

如果使用 Obsidian Git，可以通过命令面板执行：

```text
Obsidian Git: Commit-and-sync
```

## 公开边界

这是知识库的公开版本。以下内容会被刻意排除在 Git 之外：

- 文章剪藏全文和抽取缓存
- 图片上传插件历史
- 本地 Agent 插件状态
- Obsidian workspace 状态
- `.env`、密钥、账号凭据和其他私有配置

公开仓库用于展示知识结构和整理后的笔记，不用于同步所有私人草稿和工具中间产物。

## 当前状态

这个知识库仍在持续建设中。部分旧笔记可能还存在结构粗糙、链接不完整或历史导入导致的编码问题。长期目标是让 `Wiki` 层比 `RAW` 层更干净、更密集、更适合复习、检索和复用。

## 许可说明

当前尚未声明正式开源许可证。原始资料仍应遵循其各自来源的版权和许可要求。

---

## English Version

LLM Wiki is a public Obsidian vault for learning and organizing modern AI engineering. It focuses on large language models, agents, RAG, fine-tuning, reinforcement learning, evaluation, inference optimization, and the practical tools around them.

The goal is not to collect everything. The goal is to turn useful sources into a compact, navigable, and reusable knowledge graph.

## A Karpathy-Style Knowledge Base

By Karpathy-style, this repository means an engineering-oriented, first-principles, explainable learning workflow:

1. Keep raw materials close to the work.
2. Rewrite important ideas in plain language.
3. Prefer small connected notes over large disconnected summaries.
4. Let code, papers, diagrams, interview questions, and engineering practice reinforce each other.
5. Keep the system inspectable: Markdown, folders, Git, and Obsidian links.

The core pipeline is:

```text
RAW sources -> structured Wiki notes -> concepts, methods, questions, projects, and domains
```

## Repository Structure

```text
.
|-- RAW/       # Original source materials: papers, notes, websites, books, logs
|-- Wiki/      # Distilled knowledge nodes for reading, linking, and review
|-- Schema/    # Maintenance rules for ingestion, style, structure, and querying
`-- .obsidian/ # Obsidian vault settings and selected plugin metadata
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
- `domains/`: broader areas such as agent engineering, RAG, and model internals
- `sources/`: rewritten source-level notes
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

If using Obsidian Git, the repository can be synced with:

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

