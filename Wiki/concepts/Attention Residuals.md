---
type: concept
title: "Attention Residuals"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - concept
  - transformer
  - llm
complexity: advanced
domain: "大模型底层原理"
aliases:
  - "AttnRes"
related:
  - "[[残差连接]]"
sources:
  - "[[attention-residuals]]"
raw_bucket: "05.Research"
source_path: "RAW/05.Research/残差连接_ATTENTION RESIDUALS.pdf"
---

# Attention Residuals

## 定义

Attention Residuals 是一种替代标准固定残差累加的机制。它试图让模型在聚合历史层输出时使用动态权重，而不是简单地把每层输出以单位权重累加。

## 背景

Transformer 常用 PreNorm 残差结构：

$$
x_{l+1} = x_l + F_l(\mathrm{Norm}(x_l))
$$

这种结构稳定、简单，但当层数很深时，所有层输出固定相加可能导致隐藏状态幅度增长，并稀释后续层的有效贡献。

## 直观类比

标准残差像把每一层的意见都等权放进会议纪要；Attention Residuals 更像主持人根据当前议题动态决定哪些历史意见更重要。

## 仍需补充

需要后续精读论文，补充具体公式、实验结果、适用模型规模和实现成本。
