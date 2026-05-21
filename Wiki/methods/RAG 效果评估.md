---
type: method
title: "RAG 效果评估"
created: 2026-05-19
updated: 2026-05-19
status: seed
tags:
  - method
  - rag
  - evaluation
related:
  - "[[RAG 工程摄取链路]]"
  - "[[Embedding 与 Rerank 选型方法]]"
sources:
  - "[[llm-engineer-评价rag项目效果]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/大模型工程师：评价RAG项目效果.md"
method_type: engineering
applies_to: "RAG 系统离线评估、回归测试和线上监控"
limitations:
  - "微信资料可提供面试框架；正式指标定义需结合 Ragas、IR 指标和业务标注集核对。"
---

# RAG 效果评估

## 评估分层

RAG 不能只看最终回答好不好。更稳妥的评估要拆成三层：

- 检索层：Recall@k、MRR、nDCG、命中文档覆盖率。
- 生成层：faithfulness、answer relevancy、引用一致性。
- 端到端层：用户问题解决率、延迟、成本、失败类型和人工反馈。

## 基本流程

1. 构建 golden set：真实问题、标准答案、应命中文档、困难负例。
2. 先测 retrieval，不要让生成模型掩盖召回失败。
3. 再测 rerank 和 prompt，对比答案质量变化。
4. 最后做回归测试，防止分块、模型和索引调整后质量倒退。

## 面试表达

好的回答应说明“评估对象是什么”。检索错、上下文拼错、模型编造和引用不准是不同问题，不能用一个总分混在一起。

