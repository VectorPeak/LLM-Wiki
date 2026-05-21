---
type: concept
title: "Prompt Cache"
created: 2026-05-19
updated: 2026-05-19
status: seed
tags:
  - concept
  - prompt
  - cache
complexity: intermediate
domain: "AI 编程工具与 Agent 产品"
aliases:
  - "提示词缓存"
  - "Prompt Caching"
related:
  - "[[Prompt 工程]]"
  - "[[长程智能体]]"
sources:
  - "[[聊聊ai系统的四层缓存架构]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/聊聊AI系统的四层缓存架构.md"
---

# Prompt Cache

## 定义

Prompt Cache 是对重复提示词前缀或上下文片段的缓存机制。它用缓存命中降低重复输入成本和延迟，尤其适合 system prompt、工具说明、固定示例和长期上下文模板。

## 直觉

如果每次请求都带同一段很长的系统说明，模型服务可以复用这段前缀的处理结果。变量内容应尽量放在后面，稳定内容放在前面，这样更容易命中缓存。

## 风险

缓存不是记忆。它不能替代任务状态管理，也不能保证语义正确；它只是性能和成本优化手段。

