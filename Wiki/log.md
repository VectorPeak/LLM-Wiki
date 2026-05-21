---
type: meta
title: "LLMWiki Log"
created: 2026-05-05
updated: 2026-05-19
status: developing
tags:
  - meta
  - log
related:
  - "[[index]]"
  - "[[overview]]"
  - "[[hot]]"
sources: []
raw_bucket: ""
source_path: ""
---

# LLMWiki Log

新日志写在顶部。

## 2026-05-19 | ingest | RAW/09.Wechat 批量去重摄取

- 对 `RAW/09.Wechat` 执行批量 `/Ingest`，先按 `source_path` 去重：96 个原始 Markdown 中，8 个已存在来源页，88 个生成新来源页。
- 发现 `算法工程师要掌握这些技能.md` 与 `算法工程师要掌握这些技能 1.md` 内容重复，保留主来源页并删除副本来源页。
- 新增实体页 [[波哥聊大模型]]，新增对比页 [[RAGFlow 与 LlamaIndex]]、[[LangChain 与 LangGraph]]。
- 新增方法页 [[Embedding 与 Rerank 选型方法]]、[[LLM 推理优化方法]]、[[传统机器学习面试准备框架]]、[[RAG 效果评估]]、[[Prompt 工程]]、[[LM Evaluation Harness 工程]]。
- 新增概念页 [[KV Cache]]、[[MoE]]、[[GRPO]]、[[Prompt Cache]]、[[多模态 RAG]]。
- 新增问题页 [[为什么代码检索不总是适合用 RAG]]、[[如何选择 Embedding 和 Rerank 模型]]、[[GRPO 为什么可能出现 Reward Hacking]]、[[如何赋予 LLM 规划能力]]。
- 更新 [[index]] 与 [[hot]]。

## 2026-05-19 | lint | RAW 结构调整后的补充核查与修复

- 生成并更新 [[lint-report-2026-05-19]]。
- 删除未登记且为空的 `Wiki/business` 目录；`comparisons`、`entities`、`logs`、`projects` 保留为 Schema 允许的 Wiki 类型目录。
- 将旧 `RAW/10.Interview` 的 `raw_bucket` 和 `source_path` 迁移到当前 `RAW/09.Wechat`。
- 更新 [[index]] 与 [[hot]]，移除 `RAW/10.Interview`、`RAW/08.Business`、Business 分区等旧结构描述。
- 补强 `Schema/lint.md`，加入空目录、RAW 分区漂移、失效 `source_path`、未摄取 RAW 覆盖率和 Schema 漂移检查项。

## 2026-05-14 | lint | 多批次摄取后结构检查

- 生成 [[lint-report-2026-05-14]]。
- 检查结果：无死链、无必填 frontmatter 缺口、无失效 `source_path`、无 `RAW` 派生缓存目录。
- 按使用者将目录改为 `RAW/10.Interview` 的决定，统一所有 Interview 相关 `raw_bucket` 和 `source_path` 的大小写。

## 2026-05-14 | ingest | 多批次摄取 Agent/RAG、自笔记、Research PDF、BookCourse PDF

- 按使用者要求，未摄取 `RAW/01.Inbox`，也未摄取 `RAW/02.Logs`。
- 摄取 `RAW/10.Interview` 的 Agent/RAG 子集 8 篇，生成 Agent 架构、ReAct、Reflection、Memory、Tool Calling、LangGraph、RAG 分块、父子 Chunk、MCP 与 CLI 等节点。
- 摄取 `RAW/03.Self-Notes` 4 篇，生成 Claude Code、OpenClaw、Hermes、Spec-Driven Development、AI 编程工具面试准备等节点；所有自笔记来源页标记为 `source_type: self_note`。
- 摄取 `RAW/05.Research` 5 个 PDF，生成 AGENTS.md 评估、删除权通知协议、Attention Residuals 等研究节点。
- 摄取 `RAW/07.BookCourse` 4 个 PDF，生成算法、深度学习、NLP、大模型学习路径和基础概念节点。
- PDF 抽取文本保存在 `Clippings/.llmwiki-cache`，未写入 `RAW`；正式 `source_path` 均回指 `RAW` 原始 PDF。
- 更新 [[index]] 和 [[hot]]，并执行 wikilink、frontmatter、RAW 缓存污染检查。

## 2026-05-14 | ingest | 摄取 RAW/06.Website Harness Engineering 资料

- 按使用者要求，本轮不摄取 `RAW/01.Inbox` 和 `RAW/02.Logs`。
- 摄取 `RAW/06.Website` 三篇网站资料：Anthropic long-running agents、Anthropic long-running application harness、OpenAI Codex harness engineering。
- 新增来源页：[[effective-harnesses-for-long-running-agents]]、[[harness-design-for-long-running-application-development]]、[[openai-harness-engineering-codex]]。
- 新增领域页：[[智能体工程支架领域]]。
- 新增概念页：[[长程智能体]]、[[上下文交接]]、[[智能体可读性]]。
- 新增方法页：[[工程支架设计]]、[[生成器-评估器循环]]。
- 新增问题页：[[如何让长程编码智能体稳定推进复杂任务]]。
- 更新 [[index]] 和 [[hot]]，并保持 `source_path` 回指 `RAW/06.Website` 原始 Markdown。

## 2026-05-14 | schema | 缓存目录迁移到 Clippings

- 按使用者决定，将工具缓存位置从 `D:\LLMWiki\.llmwiki-cache\` 迁移为 `D:\LLMWiki\LLMWiki\Clippings\.llmwiki-cache\`。
- 更新 `Schema/AGENTS.md`、`Schema/structure.md`、`Schema/ingest.md`、`Schema/source-policy.md` 中的缓存路径。
- 明确 `Clippings/.llmwiki-cache` 虽位于 `Clippings` 下，但不是剪藏语料，不参与 `/Ingest` 的原始资料枚举。

## 2026-05-14 | schema | 明确 RAW 与缓存边界

- 更新 `Schema/AGENTS.md`、`Schema/structure.md`、`Schema/ingest.md`、`Schema/source-policy.md`。
- 明确 `RAW` 只保存原始资料，不放 PDF 抽取文本、OCR、切片、embedding 输入、临时 JSON 或工具缓存。
- 当时规定可再生中间产物放入 vault 外部缓存；后续已按使用者决定迁移到 `D:\LLMWiki\LLMWiki\Clippings\.llmwiki-cache\`。
- 规定 `Wiki/sources/` 的 `source_path` 必须回指 `RAW` 原始文件，不能指向缓存文本。

## 2026-05-14 | audit | Wiki 入口层审计与修复

- 读取 `Schema/structure.md`、`Schema/ingest.md`、`Schema/query.md`、`Schema/lint.md`、`Schema/frontmatter.md` 和 `Schema/AGENTS.md`。
- 确认 [[index]]、[[overview]]、[[hot]]、[[log]] 四个入口文件存在，但主索引仍是初始化骨架。
- 修复入口页之间的内部链接，避免 `LLMWiki Index`、`LLMWiki Overview` 这类名称与文件名不一致的潜在死链。
- 更新 [[index]]，补齐 Core Entrypoints、Current Status、Logs、Business、Meta，并标注各知识分区待 `/Ingest`。
- 更新 [[hot]]，同步当前 `RAW` 分区状态和下一步维护线程。

## 2026-05-05 | scaffold | Codex 维护版 LLM Wiki 初始化

- 初始化 `Schema` 规则文件。
- 初始化 `Wiki` 基础目录和核心页面。
- 确定原则：`RAW` 按来源组织，`Wiki` 按知识类型组织。
