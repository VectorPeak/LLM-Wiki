---
type: concept
title: "Repository-Level Context Files"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - concept
  - coding-agent
  - context
complexity: intermediate
domain: "智能体工程支架"
aliases:
  - "仓库级上下文文件"
  - "AGENTS.md"
related:
  - "[[智能体可读性]]"
  - "[[工程支架设计]]"
sources:
  - "[[evaluating-agents-md-paper]]"
  - "[[openai-harness-engineering-codex]]"
raw_bucket: "05.Research"
source_path: "RAW/05.Research/Agents_Evaluating AGENTS.md Are Repository-Level Context Files Helpful for Coding Agents.pdf"
---

# Repository-Level Context Files

## 定义

Repository-Level Context Files 是放在代码仓库中、供 coding agent 理解项目规则和导航路径的上下文文件，例如 `AGENTS.md`、`CLAUDE.md` 或类似项目指令文件。

## 关键问题

这类文件的价值不在“写得多”，而在是否让 agent 更快找到正确信息、遵守项目约束、减少错误路径。一个过长、过旧、不可验证的指令文件可能反而污染上下文。

## 与 LLMWiki 的关系

LLMWiki 的 `Schema/AGENTS.md` 扮演类似角色：它应保持短、稳定、可执行，并把详细规则分散到结构化 Schema 文件中。
