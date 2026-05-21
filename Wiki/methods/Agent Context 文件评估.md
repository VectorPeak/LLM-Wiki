---
type: method
title: "Agent Context 文件评估"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - method
  - coding-agent
  - evaluation
method_type: research
applies_to: "AGENTS.md、CLAUDE.md、repo instruction files、LLMWiki Schema"
limitations:
  - "评估结果依赖任务集、agent 模型、工具链和仓库类型。"
related:
  - "[[Repository-Level Context Files]]"
  - "[[智能体可读性]]"
sources:
  - "[[evaluating-agents-md-paper]]"
raw_bucket: "05.Research"
source_path: "RAW/05.Research/Agents_Evaluating AGENTS.md Are Repository-Level Context Files Helpful for Coding Agents.pdf"
---

# Agent Context 文件评估

## 方法定位

Agent Context 文件评估关注 `AGENTS.md` 这类仓库级指令是否真的提升 coding agent 表现。它应从任务成功率、错误类型、上下文利用、规则遵守和维护成本评估，而不是只看文件是否完整。

## 评估维度

- 是否降低错误路径。
- 是否提升任务完成率。
- 是否减少重复探索。
- 是否让 agent 更遵守架构和测试要求。
- 是否因过长或过时导致上下文污染。

## 对 LLMWiki 的应用

LLMWiki 的 `Schema` 也需要同样评估：规则是否让后续 `/Ingest`、`/Query`、`/Lint` 更稳定，而不是只增加文档数量。
