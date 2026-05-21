---
type: method
title: "RAG 工程摄取链路"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - method
  - rag
  - ingestion
method_type: engineering
applies_to: "RAG 文档入库、企业知识库、PDF/Word/扫描件处理"
limitations:
  - "具体阈值和格式选择需要根据数据质量、查询类型和评测集确定。"
related:
  - "[[RAG 文本分块]]"
  - "[[PDF 解析与 OCR 预处理]]"
  - "[[父子 Chunk]]"
sources:
  - "[[rag-engineering-chain]]"
  - "[[rag-chunking-strategy]]"
  - "[[sft-rag-interview]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat"
---

# RAG 工程摄取链路

## 方法定位

RAG 工程摄取链路是把多格式资料转换成可检索、可追溯、可评测知识单元的流程。它的难点不在“向量化”四个字，而在解析、清洗、分块、索引、召回和质量验证的连续链条。

## 标准流程

1. 文件识别：PDF、Word、网页、扫描件、表格。
2. 解析与 OCR：保留标题、段落、表格、图片和页码结构。
3. 清洗：去噪、去重、修复断行、过滤页眉页脚。
4. 分块：结合标题层级、语义边界和人工保护标记。
5. 索引：embedding、关键词、元数据和父子映射。
6. 检索：召回、rerank、多样性控制和上下文组装。
7. 评测：构造查询集，观察命中、答案、引用和失败案例。

## 面试陷阱

不要把 RAG 回答成“切块 + embedding + 向量库”。真正的工程问题通常出现在 PDF 结构、OCR 质量、chunk 边界、元数据、更新机制和评测闭环。
