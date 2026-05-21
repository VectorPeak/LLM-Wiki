---
type: method
title: "LM Evaluation Harness 工程"
created: 2026-05-19
updated: 2026-05-19
status: seed
tags:
  - method
  - evaluation
  - llm
  - harness
related:
  - "[[RAG 效果评估]]"
  - "[[工程支架设计]]"
sources:
  - "[[llm-harness工程20题]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/大模型Harness工程20题.md"
method_type: engineering
applies_to: "大模型评测任务工程与基准测试"
limitations:
  - "该页讨论评测 harness，不等同于 Anthropic/OpenAI 语境里的 long-running agent harness。"
---

# LM Evaluation Harness 工程

## 定位

LM Evaluation Harness 是围绕模型评测任务组织数据集、prompt、打分函数、推理后端和结果汇总的工程框架。它关注“如何稳定评测模型”，不是“如何让 Agent 长程执行任务”。

## 工程要点

- 任务定义：选择 multiple choice、generation、loglikelihood 等任务形式。
- 数据加载：把样本、答案、few-shot 示例组织成可复现输入。
- 后端适配：本地模型、API 模型、vLLM、量化模型等。
- 指标统计：准确率、困惑度、pass@k、任务特定指标。
- 可复现性：固定版本、随机种子、prompt 模板和评测配置。

## 易混点

“Harness”在不同语境里含义不同。评测 harness 是评估基础设施；agent harness 是长程任务执行支架。两者都叫支架，但目标和接口不同。

