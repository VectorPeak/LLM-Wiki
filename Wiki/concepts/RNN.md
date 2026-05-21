---
type: concept
title: "RNN"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - concept
  - nlp
  - sequence-modeling
complexity: intermediate
domain: "大模型底层原理"
aliases:
  - "循环神经网络"
  - "Recurrent Neural Network"
related:
  - "[[Transformer]]"
  - "[[自然语言处理学习路径]]"
sources:
  - "[[deep-learning-advanced-nlp]]"
raw_bucket: "07.BookCourse"
source_path: "RAW/07.BookCourse/深度学习进阶_自然语言处理.pdf"
---

# RNN

## 定义

RNN，即循环神经网络，是为序列数据设计的神经网络。它通过隐藏状态把前面时间步的信息传递到后面：

$$
h_t = f(x_t, h_{t-1})
$$

## 作用

RNN 曾是 NLP 和时间序列建模的重要基础，用于语言模型、机器翻译、文本生成等任务。

## 与 Transformer 的关系

Transformer 在现代 LLM 中取代了 RNN 的主导地位，但理解 RNN 有助于理解序列建模问题本身，以及为什么 attention 能更好处理长距离依赖和并行训练。
