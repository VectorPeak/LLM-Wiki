---
type: source
title: "Attention Residuals"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - source
  - paper
  - llm
  - transformer
related:
  - "[[Attention Residuals]]"
  - "[[残差连接]]"
sources: []
raw_bucket: "05.Research"
source_path: "RAW/05.Research/残差连接_ATTENTION RESIDUALS.pdf"
source_type: paper
author: "Kimi Team"
date_published: ""
url: "https://github.com/MoonshotAI/Attention-Residuals"
confidence: medium
key_claims:
  - "标准 PreNorm 残差连接以固定单位权重累加所有层输出，可能导致隐藏状态随深度增长并稀释单层贡献。"
  - "Attention Residuals 用动态注意力式聚合替代固定残差累加，以改善深层 LLM 的信息聚合。"
---

# Attention Residuals

## 摘要

这份技术报告关注 Transformer 中残差连接的聚合方式。传统 PreNorm 残差以固定权重累计各层输出，论文认为这会造成隐藏状态增长和层贡献稀释。Attention Residuals 试图用可学习、动态的聚合方式替代固定累加。

## 关键断言

- 标准残差连接简单稳定，但对深层模型可能不是最优聚合方式。
- 动态残差聚合可以让模型按输入和层状态调整信息流。
- 该方向与长上下文、深层 LLM 稳定训练和表达能力有关。

## 涉及概念

- [[Attention Residuals]]
- [[残差连接]]

## 局限与不确定性

本页只做论文主题摄取。实验结果、适用模型规模和实现细节需要后续精读。
