---
type: question
title: "RAG 文本分块为什么不是固定长度即可"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - question
  - rag
  - chunking
related:
  - "[[RAG 文本分块]]"
  - "[[父子 Chunk]]"
sources:
  - "[[rag-chunking-strategy]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/Wechat_波哥聊大模型_RAG 系统的文本分块策略.md"
question: "RAG 文本分块为什么不是固定长度即可？"
answer_quality: solid
---

# RAG 文本分块为什么不是固定长度即可

## 简答

固定长度分块只是便宜稳定的 baseline。它不理解标题、段落、表格、定义和论证边界，容易把一个完整概念切碎，导致 embedding 表示不完整、检索命中不稳定、回答上下文缺失。

## 详细解释

RAG 的检索质量上限在很大程度上由 chunk 决定。若切分时把问题所需的条件和结论拆到两个块里，后续模型即使很强，也只能基于残缺上下文回答。

更好的策略通常是混合式：用规则保持稳定，用语义边界保护完整性，用人工先验处理高价值文档，用父子 chunk 兼顾精确检索和上下文回填。

## 依据

- [[rag-chunking-strategy]]
