---
type: concept
title: "Agent 人工干预"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - concept
  - agent
  - hitl
complexity: intermediate
domain: "Agent 与 RAG 工程面试"
aliases:
  - "Human-in-the-loop"
  - "HITL"
related:
  - "[[LangGraph 状态流转]]"
  - "[[生产级 Agent 系统设计]]"
sources:
  - "[[production-agent-system-three-questions]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/Wechat_波哥聊大模型_26年4月面试题总结-构建生产级 Agent 系统三个值得深挖的面试题.md"
---

# Agent 人工干预

## 定义

Agent 人工干预是在人类判断必须进入任务闭环时，让 Agent 暂停、暴露中间结果、接收修改或审批，再恢复执行的机制。

## 典型场景

- 规划 Agent 生成大纲后，让用户编辑。
- 高风险工具调用前要求审批。
- 业务流程需要人工确认。
- Agent 不确定时请求澄清。

## 工程要点

后端需要保存状态并支持 interrupt/resume；前端需要展示可编辑中间态；通信层可用 SSE 或 WebSocket 推送状态变化。关键不是“弹窗问一下”，而是把人工输入纳入可恢复的状态机。
