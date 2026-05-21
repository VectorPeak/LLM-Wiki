---
type: question
title: "如何赋予 LLM 规划能力"
created: 2026-05-19
updated: 2026-05-19
status: seed
tags:
  - question
  - agent
  - planning
related:
  - "[[Agent 架构]]"
  - "[[生产级 Agent 系统设计]]"
sources:
  - "[[百度面试官-如何赋予-llm-规划能力]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/百度面试官：如何赋予 LLM 规划能力？.md"
question: "如何赋予 LLM 规划能力？"
answer_quality: draft
---

# 如何赋予 LLM 规划能力

## 简答

LLM 的规划能力通常不是单靠一次 prompt 得到的，而是通过任务分解、显式状态、工具反馈、搜索/回溯和执行监控组合出来的。

## 常见路径

- Chain-of-Thought：让模型显式展开中间步骤。
- Tree-of-Thought：保留多个候选推理分支。
- Graph-of-Thought：把推理状态组织成图。
- Planner-Executor：规划器负责拆任务，执行器负责调用工具。
- ReAct：把 reasoning 和 acting 交替起来，用环境反馈修正计划。

## 工程关键

规划必须能被检查和修正。生产系统里应把计划保存成结构化状态，并允许中断、人工修改、失败重试和回滚。

