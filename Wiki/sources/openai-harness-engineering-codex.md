---
type: source
title: "工程技术：在智能体优先的世界中利用 Codex"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - source
  - website
  - codex
  - agent-harness
related:
  - "[[智能体可读性]]"
  - "[[工程支架设计]]"
  - "[[智能体工程支架领域]]"
sources: []
raw_bucket: "06.Website"
source_path: "RAW/06.Website/Web_OpenAI_HarnessEngineering_工程技术：在智能体优先的世界中利用 Codex.md"
source_type: website
author: "Ryan Lopopolo"
date_published: 2026-05-05
url: "https://openai.com/zh-Hans-CN/index/harness-engineering/"
confidence: high
key_claims:
  - "在人类不直接写代码的约束下，工程师的核心工作转向环境设计、意图表达和反馈回路。"
  - "代码仓库应成为智能体可读的记录系统，而不是把知识留在聊天、会议或人脑中。"
  - "架构不变量、文档索引、可观测性和自动化审查能放大智能体吞吐量。"
---

# 工程技术：在智能体优先的世界中利用 Codex

## 摘要

这篇 OpenAI 工程文章总结了一个 Codex-first 软件工程实验：人类不直接写代码，而是设计环境、约束、文档、验证和反馈回路，让 Codex 智能体端到端推进产品。它的重点不是“让模型替代工程师敲代码”，而是把工程系统改造成智能体可导航、可验证、可持续修复的记录系统。

## 关键断言

- 人类的稀缺资源是注意力和判断，不是键盘输入。
- `AGENTS.md` 不应成为百科全书，而应成为短小稳定的地图，指向更深的事实来源。
- 代码仓库本地、版本化、结构化的文档和计划，是智能体真正可用的上下文。
- 严格架构边界、自定义 lint、结构测试和可观测性能让智能体高吞吐工作而不快速漂移。
- 技术债需要被持续垃圾回收，而不是等到堆积成大规模重构。

## 涉及实体

- OpenAI
- Codex
- AGENTS.md
- Aardvark

## 涉及概念

- [[智能体可读性]]
- [[长程智能体]]

## 可复用方法

- [[工程支架设计]]

## 局限与不确定性

文章描述的是 OpenAI 内部高投入、强工具链、强约束的工程环境。其端到端自主能力不能直接假设能在普通代码库中泛化。

## 可继续追问

- [[如何让长程编码智能体稳定推进复杂任务]]
