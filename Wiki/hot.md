---
type: meta
title: "Hot Cache"
created: 2026-05-05
updated: 2026-05-19
status: developing
tags:
  - meta
  - hot-cache
related:
  - "[[index]]"
  - "[[overview]]"
  - "[[log]]"
sources: []
raw_bucket: ""
source_path: ""
---

# Recent Context

## Last Updated

2026-05-19 - 完成 `RAW/09.Wechat` 批量 /Ingest：新增 88 个来源页，跳过 8 个已摄取来源，移除 1 个重复来源页；补充 entity、comparison、method、concept、question 聚合页。

## Key Recent Facts

- 本知识库采用三层结构：`RAW`、`Wiki`、`Schema`。
- `RAW` 已按资料来源组织，当前入口为 `01.Inbox`、`02.Logs`、`03.Self-Notes`、`04.GitHub`、`05.Research`、`06.Website`、`07.BookCourse`、`08.Leetcode`、`09.Wechat`。
- `Wiki` 按知识类型组织，不复刻 `RAW` 的目录结构。
- 第一批已摄取 `RAW/06.Website` 三篇文章，主题集中在长程智能体、工程支架、Codex-first 代码库、上下文交接和生成器-评估器循环。
- 既有 Agent/RAG 面试资料现归入 `RAW/09.Wechat`，不是旧 `RAW/10.Interview`。
- GitHub 项目进入 `RAW/04.GitHub`，按本地 GitMD-style 规则保存为原始语料。
- 本轮明确跳过 `RAW/01.Inbox` 和 `RAW/02.Logs`。
- PDF 文本抽取缓存位于 `Clippings/.llmwiki-cache`，不作为正式来源。

## Recent Changes

- Created domain: [[Agent 与 RAG 工程面试]]
- Created domain: [[AI 编程工具与 Agent 产品]]
- Created domain: [[隐私保护与删除权]]
- Created domain: [[大模型底层原理]]
- Created domain: [[算法与编程基础]]
- Expanded concepts around Agent、RAG、AI 编程工具、隐私删除权、深度学习和 LLM 基础。
- Updated [[index]] to cover all current source, domain, concept, method and question pages.

## Active Threads

- 当前线程：`wechat-batch-ingest-deduplicated`。
- 下一步可选：补齐 source 页的上游 `sources` 字段，或继续摄取 `RAW/04.GitHub`、`RAW/08.Leetcode`。
