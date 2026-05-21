---
type: concept
title: "MCP 与 CLI"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - concept
  - mcp
  - cli
complexity: intermediate
domain: "Agent 与 RAG 工程面试"
aliases:
  - "MCP vs CLI"
related:
  - "[[Tool Calling]]"
  - "[[智能体可读性]]"
sources:
  - "[[rag-engineering-chain]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/Wechat_波哥聊大模型_RAG工程链路脏活深挖.md"
---

# MCP 与 CLI

## 定义

MCP 是面向 LLM 工具生态的结构化协议，CLI 是面向操作系统和人类开发者的命令行接口。二者都能触发能力，但抽象层级不同。

## 对比

- CLI 像“会敲命令的人”：自由、强大，但参数、输出和错误格式可能不稳定。
- MCP 像“带 schema 的工具合同”：工具、参数、返回值和权限更适合被模型发现和调用。

## 面试要点

LLM 不是不能用 CLI，而是 CLI 对模型来说缺少稳定语义边界。MCP 的价值在于让工具能力更可枚举、可描述、可约束。
