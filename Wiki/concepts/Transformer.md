---
type: concept
title: "Transformer"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - concept
  - llm
  - transformer
complexity: intermediate
domain: "大模型底层原理"
aliases:
  - "Transformer architecture"
related:
  - "[[残差连接]]"
  - "[[Attention Residuals]]"
  - "[[大模型预训练与微调]]"
sources:
  - "[[build-a-large-language-model-from-scratch]]"
raw_bucket: "07.BookCourse"
source_path: "RAW/07.BookCourse/从零构建大模型-[美]塞巴斯蒂安·拉施卡.pdf"
---

# Transformer

## 定义

Transformer 是以注意力机制为核心的神经网络架构，是现代大语言模型的基础结构。它通过 self-attention 在序列内部建立 token 之间的依赖关系。

## 基本组成

- token embedding
- positional encoding 或位置嵌入
- self-attention
- feed-forward network
- residual connection
- layer normalization

## 与 RNN 的对比

RNN 按时间步递归处理序列，天然顺序依赖强；Transformer 可以并行处理序列，并通过注意力直接建模远距离依赖。

## 仍需补充

后续可从 `从零构建大模型` 中继续拆出 tokenizer、attention、GPT 架构、预训练目标和微调流程。
