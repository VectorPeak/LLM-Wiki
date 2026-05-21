---
type: source
title: "RAG 系统的文本分块策略"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - source
  - interview
  - rag
related:
  - "[[RAG 文本分块]]"
  - "[[父子 Chunk]]"
  - "[[RAG 工程摄取链路]]"
sources: []
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/Wechat_波哥聊大模型_RAG 系统的文本分块策略.md"
source_type: article
author: "波哥聊大模型"
date_published: ""
url: "https://mp.weixin.qq.com/s/yJtkwCbhwB4c27G3ox7zFw"
confidence: medium
key_claims:
  - "固定长度分块只是基线，不是 RAG 分块策略的终点。"
  - "分块需要在粒度、语义连贯性和人工标注成本之间权衡。"
  - "父子 chunk 架构可以解耦检索精度和上下文召回。"
---

# RAG 系统的文本分块策略

## 摘要

这篇文章讨论 RAG 文本分块的工程设计，强调 chunking 直接决定检索粒度上限。固定长度分块简单但容易切断语义，实际系统应结合语义感知、规则、LLM 校验和人工先验。

## 关键断言

- 分块策略影响 embedding 表达、召回质量和后续 rerank 效果。
- 好的 chunking 是粒度、连贯性和维护成本之间的折中。
- 父子 chunk 用较小子块检索、较大父块回填上下文，可以兼顾精确匹配与回答完整性。

## 涉及概念

- [[RAG 文本分块]]
- [[父子 Chunk]]

## 可复用方法

- [[RAG 工程摄取链路]]

## 可继续追问

- [[RAG 文本分块为什么不是固定长度即可]]
