---
type: question
title: "如何选择 Embedding 和 Rerank 模型"
created: 2026-05-19
updated: 2026-05-19
status: seed
tags:
  - question
  - rag
  - embedding
  - rerank
related:
  - "[[Embedding 与 Rerank 选型方法]]"
  - "[[RAG 工程摄取链路]]"
sources:
  - "[[阿里面试官-bge-和-gte-的区别都说不清-rerank-模型怎么配的也不知道-你这-rag-是蒙着眼做的]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/阿里面试官：BGE 和 GTE 的区别都说不清，Rerank 模型怎么配的也不知道，你这 RAG 是蒙着眼做的？.md"
question: "RAG 项目中如何选择 Embedding 和 Rerank 模型？"
answer_quality: draft
---

# 如何选择 Embedding 和 Rerank 模型

## 简答

先用 embedding 做高召回候选，再用 rerank 做精排。选型时不要只看榜单，要用自己的语料和问题集测 Recall@k、MRR、nDCG、延迟和成本。

## 面试回答要点

- 先定义业务语料和查询类型。
- 用真实问题构造 golden set。
- 对比 embedding 模型的召回能力。
- 对比 rerank 模型对 top-k 的重排收益。
- 结合延迟预算决定是否启用 rerank，以及 rerank 放在多少候选上。

