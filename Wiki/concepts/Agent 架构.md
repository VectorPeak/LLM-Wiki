---
type: concept
title: "Agent 架构"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - concept
  - agent
complexity: intermediate
domain: "Agent 与 RAG 工程面试"
aliases:
  - "Agent architecture"
related:
  - "[[ReAct]]"
  - "[[Agent 记忆系统]]"
  - "[[Tool Calling]]"
sources:
  - "[[agent-interview-summary-1]]"
  - "[[agent-summary-2026-03]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat"
---

# Agent 架构

## 定义

Agent 架构是把 LLM 从单轮文本生成器扩展为目标驱动执行系统的结构。它通常包含模型、规划、工具、记忆、执行控制、反馈和终止条件。

## 与 ChatBot 的区别

ChatBot 更像“问答接口”，输入一句，输出一句；Agent 更像“带工具的任务执行者”，会围绕目标持续规划、行动、观察和修正。

## 常见组件

- LLM: 负责理解、推理和生成。
- Planner: 把目标拆成步骤。
- Tool layer: 执行搜索、数据库、代码、浏览器、API 等动作。
- Memory: 保存短期上下文和长期经验。
- Controller: 决定循环、终止、重试和异常处理。
- Evaluator: 判断结果是否满足目标。

## 面试要点

回答 Agent 架构题时，不能只说“LLM + Tools”。更好的答案应说明状态如何流动、工具如何选择、失败如何恢复、记忆如何更新、何时让人介入。
