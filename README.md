<div align="center">

# LLM Wiki | 个人大模型知识库

**一个面向 LLM、Agent、RAG、微调、评估与 AI 工程实践的 Obsidian 知识网络**

![knowledge](https://img.shields.io/badge/knowledge-LLM%20%7C%20Agent%20%7C%20RAG-blue)
![vault](https://img.shields.io/badge/vault-Obsidian-7C3AED)
![wiki-notes](https://img.shields.io/badge/wiki%20notes-190-brightgreen)
![raw-files](https://img.shields.io/badge/raw%20files-158-orange)
![license](https://img.shields.io/badge/license-CC%20BY--NC%204.0-lightgrey)

**简体中文** | [English](./README_EN.md)

```text
RAW 原始资料  ──►  Wiki 结构化笔记  ──►  可链接、可查询、可复用的知识网络
```

</div>

---

## 简介

LLM Wiki 是一个公开的 Obsidian 知识库，用来持续整理现代 AI 工程相关内容，覆盖大语言模型、Agent、RAG、微调、强化学习、评估、推理优化，以及围绕这些方向的工程工具和实践方法

它的目标不是“收集一切”，而是把真正有价值的资料加工成一个紧凑、可导航、可复用的知识图谱。换句话说，`RAW` 更像原矿，`Wiki` 更像被冶炼过的知识合金，`Schema` 则是保证后续加工不跑偏的工艺规程

## 为什么存在

学习 LLM 相关知识时，常见失败模式不是“资料不够”，而是资料过多、层级混乱、概念互相孤立、看完之后无法复用。LLM Wiki 试图把论文、文章、项目、课程、面试题和个人笔记压缩成一套能被反复查询和扩展的结构化系统

这个库采用一种偏 Karpathy 风格的学习方法：先保留原始资料，再用自己的话重写关键概念，最后通过链接、对比、问题和工程场景把知识织成网络

## 核心结构

```text
.
├─ RAW/       # 原始资料层：论文、网页、书籍、课程、项目资料、学习日志
├─ Wiki/      # 知识产品层：概念、方法、问题、项目、领域和来源笔记
├─ Schema/    # 维护规则层：摄取、结构、风格、来源、查询和 lint 规则
└─ .obsidian/ # Obsidian 库配置和部分插件元数据
```

### RAW：原始资料层

`RAW` 用来保存还没有完全加工成稳定知识的材料，包括论文、网页、课程、书籍、GitHub 项目资料、面试题、算法题、学习日志和个人原始笔记

### Wiki：知识产品层

`Wiki` 不按资料来源分类，而按知识角色组织。它更像一个知识图谱的节点集合，每个节点都应该能回答一个清晰问题，或承载一个可复用概念

| 目录 | 作用 |
|---|---|
| [`Wiki/concepts`](./Wiki/concepts) | 原子概念，例如 Transformer、KV Cache、GRPO、RAG chunking |
| [`Wiki/methods`](./Wiki/methods) | 学习路径、工程方法、评估方法和实践框架 |
| [`Wiki/questions`](./Wiki/questions) | 面试型问题、研究型问题和容易混淆的问题 |
| [`Wiki/projects`](./Wiki/projects) | LangChain、LangGraph、LlamaIndex、RAGFlow 等项目 |
| [`Wiki/domains`](./Wiki/domains) | Agent 工程、RAG、大模型底层原理等领域 |
| [`Wiki/sources`](./Wiki/sources) | 对原始资料进行重写后的来源笔记 |
| [`Wiki/comparisons`](./Wiki/comparisons) | 容易混淆对象的对比笔记 |

### Schema：维护规则层

`Schema` 描述这个知识库应该如何被持续更新，包括 frontmatter、ingest、structure、style、source-policy、query、lint 等规则。它的作用类似“知识库操作系统”的系统调用约束，保证后续由人或 AI 维护时不会随意堆文件

## 推荐入口

- [`Wiki/index.md`](./Wiki/index.md)：全库主索引，适合从结构开始浏览
- [`Wiki/overview.md`](./Wiki/overview.md)：知识库定位、结构和当前状态总览
- [`Wiki/hot.md`](./Wiki/hot.md)：近期上下文与高频工作区
- [`Schema/AGENTS.md`](./Schema/AGENTS.md)：AI 辅助维护规则
- [`Schema/style.md`](./Schema/style.md)：写作风格规则
- [`Schema/query.md`](./Schema/query.md)：查询和使用规则

## 当前主题

这个知识库目前重点覆盖以下方向：

- 大模型底层原理：Transformer、Attention、KV Cache、MoE、预训练与微调
- RAG 工程：文本分块、Embedding、Rerank、PDF 解析、效果评估和工程链路
- Agent 系统：ReAct、Reflection、Tool Calling、记忆系统、人工干预和长程任务
- AI 编程工具：Claude Code、Repository-Level Context、Spec-Driven Development
- 模型训练与评估：SFT、RLHF、GRPO、LM Evaluation Harness、推理优化
- 算法与面试：传统机器学习、深度学习、NLP、数据结构与算法

## 设计原则

- **来源优先**：重要判断尽量能回到原始来源
- **自顶向下**：先讲全局定位，再讲机制细节
- **小块知识，高密度链接**：避免大而散的长文堆积
- **工程导向**：不仅讲“是什么”，也讲“怎么用、何时失败、如何落地”
- **公开安全**：本地缓存、剪藏全文、上传历史、Agent 状态和密钥不进入公开仓库

## 如何使用

如果只是在线阅读，建议从 [`Wiki/index.md`](./Wiki/index.md) 开始，再沿着 `domains`、`methods`、`concepts`、`questions` 逐层展开

如果要在本地使用，可以克隆仓库后用 Obsidian 打开根目录：

```bash
git clone https://github.com/VectorPeak/LLM-Wiki.git
```

然后在 Obsidian 中选择仓库目录作为 vault，即可使用双链、全文搜索、图谱视图和本地插件能力

## 公开边界

这是知识库的公开版本。以下内容会被刻意排除在 Git 之外：

- 文章剪藏全文和抽取缓存
- 图片上传插件历史
- 本地 Agent 插件状态
- Obsidian workspace 状态
- `.env`、密钥、账号凭据和其他私有配置

公开仓库用于展示知识结构和整理后的笔记，不用于同步所有私人草稿和工具中间产物

## 当前状态

这个知识库仍在持续建设中。部分旧笔记可能还存在结构粗糙、链接不完整或历史导入导致的编码问题。长期目标是让 `Wiki` 层比 `RAW` 层更干净、更密集、更适合复习、检索和复用

## License

Original knowledge notes, documentation, and curated written content in this repository are licensed under [CC BY-NC 4.0](./LICENSE), unless a specific file states otherwise

Others may copy, share, and adapt the repository's original content for non-commercial purposes, provided that they give appropriate credit, indicate changes, and include a license link

Third-party source materials, quotations, papers, webpages, clippings, and project documents under `RAW/` remain the property of their respective authors or rights holders and should be used according to their original licenses and source terms
