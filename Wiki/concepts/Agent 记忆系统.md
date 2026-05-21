---
type: concept
title: "Agent 记忆系统"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - concept
  - agent
  - memory
complexity: intermediate
domain: "Agent 与 RAG 工程面试"
aliases:
  - "Agent Memory"
  - "Memory system"
related:
  - "[[上下文交接]]"
  - "[[长程智能体]]"
  - "[[ReAct]]"
sources:
  - "[[react-reflection-memory]]"
  - "[[agent-interview-summary-1]]"
  - "[[langgraph-state-flow]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat"
---

# Agent 记忆系统

## 定义

Agent 记忆系统负责保存和检索任务执行中需要延续的信息。它既包括当前上下文窗口里的短期状态，也包括外部数据库、向量库、文件、checkpoint 和用户画像等长期信息。

## 层次

- 短期记忆：当前对话和任务步骤。
- 工作记忆：当前任务的计划、变量、工具结果。
- 长期记忆：跨会话复用的事实、偏好、经验。
- 结构化状态：LangGraph state、checkpoint、任务日志。

## 核心权衡

记忆不是越多越好。记忆系统需要解决检索精度、陈旧信息、隐私边界和写入策略。低质量记忆会污染后续推理。

## 与 LLMWiki 的关系

LLMWiki 可以看作 Codex 的外部长期记忆，但它必须通过 `Schema`、索引、来源页和 lint 保持结构化，否则会退化成噪声仓库。
