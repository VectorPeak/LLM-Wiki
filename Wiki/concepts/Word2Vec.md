---
type: concept
title: "Word2Vec"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - concept
  - nlp
  - embedding
complexity: intermediate
domain: "大模型底层原理"
aliases:
  - "word embedding"
related:
  - "[[自然语言处理学习路径]]"
  - "[[RNN]]"
sources:
  - "[[deep-learning-advanced-nlp]]"
raw_bucket: "07.BookCourse"
source_path: "RAW/07.BookCourse/深度学习进阶_自然语言处理.pdf"
---

# Word2Vec

## 定义

Word2Vec 是把词表示为稠密向量的经典方法。它让语义相近的词在向量空间中更接近，为后续神经网络 NLP 奠定了表示学习基础。

## 典型模型

- CBOW：根据上下文预测中心词。
- Skip-gram：根据中心词预测上下文。

## 与现代 LLM 的关系

现代 LLM 使用上下文化 token 表示，远比静态词向量复杂。但 Word2Vec 仍有教学价值：它说明语言可以被映射到连续向量空间，并通过预测任务学习语义结构。
