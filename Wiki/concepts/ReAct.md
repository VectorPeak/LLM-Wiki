---
type: concept
title: "ReAct"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - concept
  - agent
complexity: basic
domain: "Agent 与 RAG 工程面试"
aliases:
  - "Reasoning and Acting"
related:
  - "[[Agent 架构]]"
  - "[[Reflection]]"
sources:
  - "[[react-reflection-memory]]"
  - "[[agent-interview-summary-1]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat"
---

# ReAct

## 定义

ReAct 是 Reasoning and Acting 的组合范式，让模型在推理与工具行动之间交替进行。典型循环是：

$$
\text{Thought} \rightarrow \text{Action} \rightarrow \text{Observation} \rightarrow \cdots \rightarrow \text{Final Answer}
$$

## 直观理解

ReAct 像一个边想边查、边查边改判断的人。它不要求模型一次性想完所有步骤，而是让每次工具反馈都成为下一步推理的输入。

## 局限

- 容易工具调用过多。
- 工具反馈错误时会带偏后续推理。
- 缺少外部约束时可能陷入循环。

## 相关概念

- [[Tool Calling]]
- [[Reflection]]
- [[Agent 记忆系统]]
