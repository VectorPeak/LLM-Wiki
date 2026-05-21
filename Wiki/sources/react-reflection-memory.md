---
type: source
title: "Agent 三件套：ReAct、Reflection、Memory"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - source
  - interview
  - agent
related:
  - "[[ReAct]]"
  - "[[Reflection]]"
  - "[[Agent 记忆系统]]"
sources: []
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/Wechat_波哥聊大模型_Agent三件套：ReAct、Reflection、Memory.md"
source_type: article
author: "波哥聊大模型"
date_published: ""
url: "https://mp.weixin.qq.com/s/OexdxbuTa3pDkNu0aV_k0g"
confidence: medium
key_claims:
  - "ReAct、Reflection 和 Memory 分别对应行动推理、自我修正和跨步骤信息保持。"
  - "复杂 Agent 不是单轮生成，而是规划、执行、观察、反思和记忆的组合。"
---

# Agent 三件套：ReAct、Reflection、Memory

## 摘要

这篇文章用面试友好的方式解释 Agent 的三类核心机制：ReAct 让推理和工具调用交织执行，Reflection 让 Agent 审视并修正自身输出，Memory 让信息在步骤和会话之间持续存在。

## 关键断言

- ReAct 通过 Thought、Action、Observation、Final Answer 形成执行循环。
- Reflection 解决模型输出不可靠和复杂任务中途偏航的问题。
- Memory 分为上下文内记忆、外部记忆、长期记忆和任务级记忆等不同层次。
- 三者组合后，Agent 才更接近可持续执行复杂任务的系统。

## 涉及概念

- [[ReAct]]
- [[Reflection]]
- [[Agent 记忆系统]]

## 可复用方法

- [[Agent 面试准备框架]]
