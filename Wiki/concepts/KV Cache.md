---
type: concept
title: "KV Cache"
created: 2026-05-19
updated: 2026-05-19
status: seed
tags:
  - concept
  - llm
  - inference
complexity: intermediate
domain: "大模型底层原理"
aliases:
  - "Key-Value Cache"
  - "注意力缓存"
related:
  - "[[Transformer]]"
  - "[[LLM 推理优化方法]]"
sources:
  - "[[algo-column-大模型kv-cache原理]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/算法专栏：大模型KV Cache原理.md"
---

# KV Cache

## 定义

KV Cache 是自回归 Transformer 推理中的缓存机制。模型生成第 \(t\) 个 token 时，前面 token 的 key/value 已经算过，可以缓存并复用，避免每一步都重新计算完整前缀。

## 直觉

没有 KV Cache 时，每生成一个新 token 都像重新读一遍前文；有 KV Cache 后，模型只需要为新 token 计算 query/key/value，并把历史 key/value 拿来做 attention。

## 代价

KV Cache 用显存换计算。上下文越长、batch 越大、层数和 hidden size 越大，缓存占用越高。

