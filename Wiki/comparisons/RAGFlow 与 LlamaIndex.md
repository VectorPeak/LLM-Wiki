---
type: comparison
title: "RAGFlow 与 LlamaIndex"
created: 2026-05-19
updated: 2026-05-19
status: seed
tags:
  - comparison
  - rag
  - framework
related:
  - "[[RAG 工程摄取链路]]"
  - "[[Embedding 与 Rerank 选型方法]]"
sources:
  - "[[llm-engineer-ragflow和llamaindex区别]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/大模型工程师：ragflow和llamaindex区别.md"
subjects:
  - "[[RAGFlow]]"
  - "[[LlamaIndex]]"
dimensions:
  - "产品定位"
  - "工程集成"
  - "数据摄取"
  - "二次开发"
verdict: "RAGFlow 更像偏产品化的 RAG 平台，LlamaIndex 更像面向开发者的 RAG/数据编排框架；具体选择取决于团队要快速落地平台还是要深度嵌入代码系统。"
---

# RAGFlow 与 LlamaIndex

## 对比结论

RAGFlow 和 LlamaIndex 都围绕 RAG 构建，但抽象层不同。RAGFlow 更接近开箱即用的知识库系统，强调文档解析、检索和可视化流程；LlamaIndex 更接近开发框架，强调数据连接器、索引、retriever、query engine 和应用内集成。

## 适用场景

- 需要快速搭一个面向业务人员的知识库平台：优先考虑 RAGFlow。
- 需要在现有 Python 应用、Agent 或后端服务中嵌入 RAG：优先考虑 LlamaIndex。
- 需要面试回答时，不要只背“一个平台一个框架”，要说明摄取、索引、检索、评估、部署和二次开发的差异。

## 待核对

该页当前主要来自微信面试资料。若用于正式技术选型，应再核对 RAGFlow 和 LlamaIndex 的官方仓库、文档、版本和生态状态。

