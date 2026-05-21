---
type: overview
title: "LLMWiki Overview"
created: 2026-05-05
updated: 2026-05-14
status: developing
tags:
  - overview
  - llm-wiki
related:
  - "[[index]]"
  - "[[hot]]"
  - "[[log]]"
sources: []
raw_bucket: ""
source_path: ""
---

# LLMWiki Overview

LLMWiki 是一个由 Codex 维护的多模式 Obsidian 知识库。它采用 Karpathy LLM Wiki 的三层思想：原始资料保存在 `RAW`，结构化知识沉淀到 `Wiki`，维护规则写入 `Schema`。

## 当前定位

本库不是普通文件夹，也不是简单摘要库。它的目标是把个人日志、使用者自笔记、GitHub 项目、研究资料、网页、课程书籍和公司项目资料持续编译成可链接、可查询、可更新的知识网络。

## 当前结构

- `RAW`: 原始资料入口。
- `Wiki`: 编译后的知识节点。
- `Schema`: Codex 维护规则。

## 当前状态

截至 2026-05-14，本库处在 `Schema` 已建立、`RAW` 已有真实资料、`Wiki` 产物层待系统摄取的阶段。换句话说，地基和仓库已经在，但知识图谱还没有充分展开。

当前最重要的维护动作不是立刻回答所有问题，而是按 `Schema/ingest.md` 把 `RAW` 中的资料编译成 `sources`、`concepts`、`methods`、`questions`、`domains` 等页面，并持续更新 [[index]]、[[hot]]、[[log]]。

## 近期重点

1. 完成入口层修复，使 [[index]] 能作为唯一主入口使用。
2. 按 `Schema/ingest.md` 从高价值 `RAW` 资料开始逐步摄取。
3. 每次重要摄取后同步更新 [[index]]、[[hot]]、[[log]]。
4. 每完成 10 到 15 次摄取后按 `Schema/lint.md` 生成健康检查报告。
