---
type: concept
title: "父子 Chunk"
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
  - "parent-child chunk"
related:
  - "[[RAG 文本分块]]"
sources:
  - "[[rag-chunking-strategy]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/Wechat_波哥聊大模型_RAG 系统的文本分块策略.md"
---

# 父子 Chunk

## 定义

父子 Chunk 是 RAG 中一种两级文本块结构：子 chunk 用于精确检索，父 chunk 用于提供更完整的上下文。

## 为什么需要

单一 chunk 尺寸很难同时满足精确匹配和上下文完整。父子结构把这两个目标拆开：

- 子 chunk：小，适合 embedding 匹配。
- 父 chunk：大，适合回答时补上下文。

## 检索流程

1. 用户问题先匹配子 chunk。
2. 根据命中的子 chunk 找到父 chunk。
3. 把父 chunk 或父子组合交给生成模型。

## 风险

父子映射如果不稳定，会带来上下文漂移；父块过大也会重新引入噪声。
