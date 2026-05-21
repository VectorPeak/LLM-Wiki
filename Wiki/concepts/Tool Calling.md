---
type: concept
title: "Tool Calling"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - concept
  - agent
  - tools
complexity: intermediate
domain: "Agent 与 RAG 工程面试"
aliases:
  - "函数调用"
  - "工具调用"
related:
  - "[[Agent 架构]]"
  - "[[MCP 与 CLI]]"
sources:
  - "[[agent-interview-summary-1]]"
  - "[[agent-summary-2026-03]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat"
---

# Tool Calling

## 定义

Tool Calling 是让 LLM 以结构化方式选择并调用外部工具的机制。工具可以是搜索、数据库、浏览器、代码执行、业务 API 或文件操作。

## 关键问题

- 工具描述是否清晰。
- 参数 schema 是否可验证。
- 工具选择是否可解释。
- 调用失败后如何重试或降级。
- 如何防止无限循环和危险操作。

## 面试表达

在 20 个以上工具的场景中，不能只依赖模型“自然选择”。应通过工具分组、路由器、权限、预算、失败计数和观测日志来控制工具调用。
