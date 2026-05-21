---
type: concept
title: "LangGraph 状态流转"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - concept
  - langgraph
  - agent
complexity: intermediate
domain: "Agent 与 RAG 工程面试"
aliases:
  - "LangGraph state flow"
related:
  - "[[Agent 记忆系统]]"
  - "[[生产级 Agent 系统设计]]"
sources:
  - "[[langgraph-state-flow]]"
  - "[[production-agent-system-three-questions]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat"
---

# LangGraph 状态流转

## 定义

LangGraph 状态流转是指 Agent 图中 state 如何被节点读取、更新，并沿边路由到下一步执行。它的核心不是定时拉状态，而是图执行循环根据节点结果和路由条件推进。

## 关键机制

- 节点：执行具体工作。
- 边：决定下一步走向。
- state：跨节点共享和累计的信息。
- checkpoint：跨会话持久化和恢复。
- interrupt/resume：处理人工介入或等待外部输入。

## 面试陷阱

如果被问“是否需要定时任务去拉状态”，直接回答“需要轮询”通常暴露出对执行模型理解不深。更好的回答是区分：普通流转由图执行驱动；等待人或外部事件时用中断、持久化和恢复。
