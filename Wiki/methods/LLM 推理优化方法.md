---
type: method
title: "LLM 推理优化方法"
created: 2026-05-19
updated: 2026-05-19
status: seed
tags:
  - method
  - llm
  - inference
  - optimization
related:
  - "[[Transformer]]"
  - "[[大模型底层原理]]"
sources:
  - "[[algo-column-大模型kv-cache原理]]"
  - "[[algo-column-flashattention]]"
  - "[[llm-engineer-混合精度和全精度区别]]"
  - "[[llm-engineer-主流大模型的解码策略]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat"
method_type: engineering
applies_to: "大模型推理延迟、吞吐和显存优化"
limitations:
  - "当前页是面试资料聚合，具体系统实现需结合推理框架和硬件环境核对。"
---

# LLM 推理优化方法

## 优化地图

LLM 推理优化可以从三层看：

- 算法层：KV Cache、FlashAttention、投机采样、解码策略。
- 数值层：FP32、FP16、BF16、INT8/INT4 量化。
- 系统层：批处理、连续 batching、显存管理、并行策略、缓存复用。

## 常见面试追问

- KV Cache 为什么能减少自回归解码的重复计算？
- FlashAttention 为什么能降低 attention 的显存读写压力？
- 量化带来的速度收益和精度损失如何权衡？
- 投机采样为什么能在保持分布近似的同时提升生成速度？

## 使用边界

推理优化不能只看单次延迟，还要看吞吐、显存占用、并发、输出质量、模型大小和部署硬件。面试回答中最好给出约束条件，否则容易变成泛泛罗列。

