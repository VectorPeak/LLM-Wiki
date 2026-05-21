---
type: concept
title: "Reflection"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - concept
  - agent
complexity: intermediate
domain: "Agent 与 RAG 工程面试"
aliases:
  - "反思机制"
  - "self-reflection"
related:
  - "[[ReAct]]"
  - "[[生成器-评估器循环]]"
sources:
  - "[[react-reflection-memory]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/Wechat_波哥聊大模型_Agent三件套：ReAct、Reflection、Memory.md"
---

# Reflection

## 定义

Reflection 是让 Agent 对自己的输出、行动轨迹或失败结果进行审视，并据此修正策略的机制。它对应人类做题后的复盘：不仅看答案，还看为什么错、下次如何避免。

## 与 ReAct 的关系

ReAct 解决“如何边推理边行动”，Reflection 解决“行动之后如何发现自己做得不好”。两者结合后，Agent 才能在多步任务中逐步修正。

## 工程注意点

- 反思要有触发条件，不能无限自我审查。
- 反思结果最好写入可检索记忆或任务日志。
- 对关键任务，外部 evaluator 往往比自我反思更可靠。

## 相关概念

- [[生成器-评估器循环]]
- [[Agent 记忆系统]]
