---
type: concept
title: "MoE"
created: 2026-05-19
updated: 2026-05-19
status: seed
tags:
  - concept
  - llm
  - architecture
complexity: intermediate
domain: "大模型底层原理"
aliases:
  - "Mixture of Experts"
  - "混合专家模型"
related:
  - "[[Transformer]]"
sources:
  - "[[algo-column-大模型moe]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/算法专栏：大模型MoE.md"
---

# MoE

## 定义

MoE 是 Mixture of Experts，即混合专家结构。它用路由器为每个 token 选择少量专家网络参与计算，从而在参数规模很大的情况下控制单次激活计算量。

## 核心权衡

- 优点：总参数量大，单 token 激活参数相对少，训练和推理可能更高效。
- 难点：路由负载均衡、专家塌缩、通信开销、部署复杂度。

## 和稠密模型的对比

稠密模型每层大部分参数都会参与计算；MoE 模型拥有更多专家参数，但每次只激活一部分。它像一个大型专家团队，每个问题只派部分专家处理。

