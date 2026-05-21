---
type: source
title: "Harness design for long-running application development"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - source
  - website
  - agent-harness
related:
  - "[[生成器-评估器循环]]"
  - "[[工程支架设计]]"
  - "[[长程智能体]]"
sources: []
raw_bucket: "06.Website"
source_path: "RAW/06.Website/Web_Anthropic_HarnessEngineering_Harness design for long-running application development.md"
source_type: website
author: "Prithvi Rajasekaran"
date_published: 2026-03-24
url: "https://www.anthropic.com/engineering/harness-design-long-running-apps"
confidence: high
key_claims:
  - "复杂智能体任务需要把生成者和评估者分离。"
  - "主观质量也可以通过明确评分准则变得可评估。"
  - "planner、generator、evaluator 三角色可以提升长程应用开发质量，但成本和复杂度也显著上升。"
---

# Harness design for long-running application development

## 摘要

这篇 Anthropic 工程文章把支架设计从“跨上下文交接”推进到“多智能体生成与评估”。作者先在前端设计中用 generator/evaluator 结构把主观审美转化为可评分准则，再扩展到全栈应用开发，形成 planner、generator、evaluator 的长程应用开发架构。

## 关键断言

- 智能体自评经常偏宽松，尤其在设计质量和复杂产品完成度上。
- 外部 evaluator 的价值在于把反馈从“模型自我感觉良好”变成“可操作的缺陷清单”。
- sprint contract 可以把高层产品目标转化为可验证的完成标准。
- 支架复杂度不是越高越好。随着模型增强，应持续移除不再承重的结构。

## 涉及实体

- Anthropic
- Claude Agent SDK
- Playwright MCP
- Claude Opus 4.5
- Claude Opus 4.6

## 涉及概念

- [[长程智能体]]
- [[生成器-评估器循环]]
- [[上下文交接]]

## 可复用方法

- [[工程支架设计]]

## 局限与不确定性

文章中的完整 harness 成本高、耗时长。它证明了支架有明显质量增益，但也提示维护者必须区分“当前模型做不到的能力缺口”和“已经过时的支架复杂度”。

## 可继续追问

- [[如何让长程编码智能体稳定推进复杂任务]]
