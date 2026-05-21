---
type: method
title: "Embedding 与 Rerank 选型方法"
created: 2026-05-19
updated: 2026-05-19
status: seed
tags:
  - method
  - rag
  - embedding
  - rerank
related:
  - "[[RAG 工程摄取链路]]"
  - "[[RAG 文本分块]]"
sources:
  - "[[阿里面试官-bge-和-gte-的区别都说不清-rerank-模型怎么配的也不知道-你这-rag-是蒙着眼做的]]"
  - "[[llm-engineer-评价rag项目效果]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/阿里面试官：BGE 和 GTE 的区别都说不清，Rerank 模型怎么配的也不知道，你这 RAG 是蒙着眼做的？.md"
method_type: engineering
applies_to: "RAG 检索模型选型与评估"
limitations:
  - "微信资料可提供面试追问方向，但具体模型排名和版本应回到 MTEB、官方模型卡或项目评测核对。"
---

# Embedding 与 Rerank 选型方法

## 核心思路

Embedding 负责第一阶段召回，Rerank 负责在候选集里重排。一个稳妥的 RAG 选型流程不是只问“哪个模型强”，而是先定义数据类型、语言、查询形态、延迟预算和评估集。

## 选型步骤

1. 明确语料：中文、英文、代码、表格、多模态或混合语料。
2. 明确查询：关键词型、长问题型、问答型、实体查找型或多跳推理型。
3. 建立小型 golden set：至少包含正例文档、困难负例和真实用户问题。
4. 对比 embedding 召回指标：Recall@k、MRR、nDCG。
5. 加入 rerank 后比较端到端指标：命中率、答案相关性、延迟和成本。
6. 再决定是否需要 hybrid search、metadata filter、query rewrite 或 chunk 策略调整。

## 面试表达

面试中应避免只报模型名。更有说服力的回答是：用什么评估集、用什么指标、在什么延迟预算下比较 embedding 与 rerank 组合。

