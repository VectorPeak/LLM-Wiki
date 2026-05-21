---
type: source
title: "Agent 面经一"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - source
  - interview
  - agent
  - rag
related:
  - "[[Agent 架构]]"
  - "[[RAG 文本分块]]"
  - "[[Agent 面试准备框架]]"
sources: []
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/Wechat_波哥聊大模型_Agent面经一.md"
source_type: article
author: "波哥聊大模型"
date_published: ""
url: "https://mp.weixin.qq.com/s/wp83RkXmDvehp93F9Q5bHQ"
confidence: medium
key_claims:
  - "Agent 面试常围绕架构、规划、记忆、工具调用、多 Agent、RAG 和生产可靠性展开。"
  - "Agent 与 chatbot 的区别在于是否具备目标驱动、工具使用、状态管理和反馈闭环。"
---

# Agent 面经一

## 摘要

这篇面试资料覆盖 Agent 架构、推理规划、Memory、Tool Calling、多 Agent、RAG 和生产可靠性。它更像面试地图：不是深挖单点，而是列出 Agent/RAG 工程面试中容易被追问的核心维度。

## 关键断言

- Agent 的核心组件包括 LLM、规划器、工具、记忆、执行控制和反馈机制。
- CoT、ReAct、ToT 和模块化 Agent 架构适用于不同复杂度的任务。
- RAG 的关键挑战包括文档分块、检索冗余、多样性控制和端到端质量。
- 生产可靠性要求容错、恢复、监控和人工介入机制。

## 涉及概念

- [[Agent 架构]]
- [[ReAct]]
- [[Agent 记忆系统]]
- [[Tool Calling]]
- [[RAG 文本分块]]

## 可复用方法

- [[Agent 面试准备框架]]
