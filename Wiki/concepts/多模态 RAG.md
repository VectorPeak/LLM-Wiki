---
type: concept
title: "多模态 RAG"
created: 2026-05-19
updated: 2026-05-19
status: seed
tags:
  - concept
  - rag
  - multimodal
complexity: intermediate
domain: "Agent 与 RAG 工程面试"
aliases:
  - "Multimodal RAG"
related:
  - "[[RAG 工程摄取链路]]"
  - "[[PDF 解析与 OCR 预处理]]"
sources:
  - "[[algo-column-什么是多模态rag]]"
  - "[[algo-column-多模态rag50题]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/算法专栏：什么是多模态rag.md"
---

# 多模态 RAG

## 定义

多模态 RAG 是把文本、图片、表格、版面、截图、图表等多种模态纳入检索增强生成流程。它解决的问题不是“把图片转成文字”这么简单，而是如何保留跨模态证据并让模型能引用。

## 常见路线

- Image-to-Text：用视觉模型生成图片描述，再进入文本 RAG。
- Layout-aware Parsing：保留版面、表格、段落和阅读顺序。
- Multimodal Embedding：把图文映射到同一向量空间。
- Late Interaction：在 query 和文档 token/patch 之间做更细粒度匹配。

## 工程难点

多模态 RAG 的难点在证据对齐：回答里引用的文字、图片、表格位置必须能回到原始资料，否则系统容易变成“看似理解图片，实际不可追溯”。

