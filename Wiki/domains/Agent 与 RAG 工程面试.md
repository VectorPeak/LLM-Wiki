---
type: domain
title: "Agent 与 RAG 工程面试"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - domain
  - interview
  - agent
  - rag
related:
  - "[[Agent 架构]]"
  - "[[RAG 文本分块]]"
  - "[[生产级 Agent 系统设计]]"
sources:
  - "[[agent-interview-summary-1]]"
  - "[[agent-summary-2026-03]]"
  - "[[production-agent-system-three-questions]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat"
---

# Agent 与 RAG 工程面试

## 定位

这个主题域整理面向大模型应用/算法岗位的 Agent 与 RAG 工程面试知识。它不是单纯概念背诵，而是围绕系统设计、工程链路、生产可靠性和追问逻辑组织。

## 核心地图

- [[Agent 架构]]: Agent 与 chatbot 的区别、核心组件和执行闭环。
- [[ReAct]]、[[Reflection]]、[[Agent 记忆系统]]: Agent 三件套。
- [[Tool Calling]]: 工具选择、函数调用和循环控制。
- [[LangGraph 状态流转]]: 图执行、状态更新、checkpoint 与中断恢复。
- [[RAG 文本分块]]、[[父子 Chunk]]: 检索粒度与上下文召回。
- [[RAG 工程摄取链路]]: PDF/OCR/解析/分块/索引/验证。

## 面试侧重点

高质量回答通常要说明三层内容：定义是什么、为什么这样设计、生产里会遇到什么坑。尤其是 RAG 和 Agent 题，面试官往往不满足于“知道名词”，而会追问状态、并发、存储、可靠性和效果验证。
