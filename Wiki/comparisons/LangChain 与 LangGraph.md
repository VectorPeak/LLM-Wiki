---
type: comparison
title: "LangChain 与 LangGraph"
created: 2026-05-19
updated: 2026-05-19
status: seed
tags:
  - comparison
  - agent
  - langgraph
related:
  - "[[LangGraph 状态流转]]"
  - "[[Agent 架构]]"
sources:
  - "[[手写agent框架②-langchain-langgraph-选型指南]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/手写Agent框架②：LangChain  LangGraph 选型指南.md"
subjects:
  - "[[LangChain]]"
  - "[[LangGraph]]"
dimensions:
  - "抽象层级"
  - "状态管理"
  - "流程控制"
  - "可恢复性"
verdict: "LangChain 更适合组件编排和快速接入，LangGraph 更适合显式状态机、多步骤 Agent、checkpoint 和 interrupt/resume。"
---

# LangChain 与 LangGraph

## 对比结论

LangChain 更像一组 LLM 应用组件和链式封装；LangGraph 更像面向 Agent 工作流的有状态图执行框架。需要简单串联模型、retriever、prompt 时，LangChain 足够；需要循环、分支、暂停恢复、人工干预和持久化状态时，LangGraph 更合适。

## 面试说法

不要把二者说成替代关系。更准确的说法是：LangGraph 可以承载更复杂的 Agent 状态流转，而 LangChain 生态中的模型、工具和 retriever 组件仍可被复用。

