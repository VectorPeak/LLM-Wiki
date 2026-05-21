---
type: source
title: "Effective harnesses for long-running agents"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - source
  - website
  - agent-harness
related:
  - "[[长程智能体]]"
  - "[[上下文交接]]"
  - "[[工程支架设计]]"
sources: []
raw_bucket: "06.Website"
source_path: "RAW/06.Website/Web_Anthropic_HarnessEngineering_Effective harnesses for long-running agents.md"
source_type: website
author: "Justin Young"
date_published: 2025-11-26
url: "https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents"
confidence: high
key_claims:
  - "长程智能体的核心问题是跨上下文窗口保持连续进展。"
  - "initializer agent 与 coding agent 的分工可以降低一口气做太多、提前宣布完成和交接断裂的风险。"
  - "进度文件、功能清单、git 历史和端到端测试是跨会话交接的关键工件。"
---

# Effective harnesses for long-running agents

## 摘要

这篇 Anthropic 工程文章讨论长程编码智能体如何跨多个上下文窗口稳定推进任务。它的核心判断是：单靠模型能力和 compaction 不足以让智能体长期可靠工作，必须设计外部支架，让每一轮智能体都能快速理解当前状态、选择一个小目标、验证基础功能，并留下下一轮可读的进度痕迹。

## 关键断言

- 长程任务失败不是单纯的“模型不够聪明”，而是上下文、进度、验证和交接缺少结构。
- 初始化阶段应建立功能清单、运行脚本、进度日志和初始提交，为后续会话提供稳定地基。
- 每个 coding agent 应只推进一个明确功能，并在结束时留下干净状态、提交记录和进度说明。
- 端到端测试比只看代码或跑局部测试更重要，尤其是 Web 应用。

## 涉及实体

- Anthropic
- Claude Agent SDK
- Claude Code
- Puppeteer MCP

## 涉及概念

- [[长程智能体]]
- [[上下文交接]]
- [[智能体可读性]]

## 可复用方法

- [[工程支架设计]]

## 局限与不确定性

文章主要基于全栈 Web App 实验，是否能直接推广到科研、金融建模或知识库维护，需要进一步验证。文章也指出，多智能体架构是否优于单一通用 coding agent 仍是开放问题。

## 可继续追问

- [[如何让长程编码智能体稳定推进复杂任务]]
