---
type: question
title: "如何设计生产级 Agent 的人工干预与 SSE"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - question
  - agent
  - sse
  - hitl
related:
  - "[[Agent 人工干预]]"
  - "[[生产级 Agent 系统设计]]"
sources:
  - "[[production-agent-system-three-questions]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/Wechat_波哥聊大模型_26年4月面试题总结-构建生产级 Agent 系统三个值得深挖的面试题.md"
question: "如何设计生产级 Agent 的人工干预与 SSE？"
answer_quality: solid
---

# 如何设计生产级 Agent 的人工干预与 SSE

## 简答

把人工干预设计成可恢复状态机，而不是简单弹窗。后端负责中断、保存 checkpoint、等待用户输入并恢复；SSE 负责把规划、等待、编辑、恢复和完成事件推给前端；前端负责展示可编辑中间结果并提交用户修改。

## 关键设计

- 事件协议：planning、interrupt、user_edit_required、resume、done、error。
- 状态持久化：每次中断前保存 task id、thread id、checkpoint 和待编辑 payload。
- 前端编辑：用户改完后提交 patch 或完整 payload。
- 恢复执行：后端将用户输入写回 state，再从 checkpoint resume。

## 风险

如果 SSE 只推文本流，不设计状态事件，前端很难区分“模型还在生成”和“正在等待用户”。生产系统要把等待状态显式化。
