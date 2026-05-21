---
type: concept
title: "RAG 文本分块"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - concept
  - rag
  - chunking
complexity: intermediate
domain: "Agent 与 RAG 工程面试"
aliases:
  - "chunking"
  - "文本切分"
related:
  - "[[父子 Chunk]]"
  - "[[RAG 工程摄取链路]]"
sources:
  - "[[rag-chunking-strategy]]"
  - "[[rag-engineering-chain]]"
  - "[[sft-rag-interview]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat"
---

# RAG 文本分块

## 定义

RAG 文本分块是把原始文档切成可检索单元的过程。它决定了向量表示的语义边界，也决定了检索系统能否召回完整、精确、可回答的信息。

## 核心权衡

分块存在三角约束：

$$
\text{chunk quality} = f(\text{粒度}, \text{语义连贯性}, \text{维护成本})
$$

块太小，语义不完整；块太大，检索不精确；过度依赖人工标注，维护成本高。

## 常见策略

- 固定长度分块：简单，可作为 baseline。
- 语义感知分块：按标题、段落、主题边界切。
- 混合规则 + LLM 校验：规则保证稳定，LLM 处理复杂边界。
- 人工先验注入：通过 no-break 标记、章节结构或领域规则保护关键语义。

## 相关概念

- [[父子 Chunk]]
- [[PDF 解析与 OCR 预处理]]
