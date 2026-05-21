---
type: method
title: "PDF 解析与 OCR 预处理"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - method
  - rag
  - ocr
method_type: engineering
applies_to: "扫描件、PDF、文档入库、RAG 前处理"
limitations:
  - "预处理过强可能破坏原始版式或引入 OCR 伪影。"
related:
  - "[[RAG 工程摄取链路]]"
  - "[[RAG 文本分块]]"
sources:
  - "[[rag-engineering-chain]]"
  - "[[sft-rag-interview]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat"
---

# PDF 解析与 OCR 预处理

## 方法定位

PDF 解析与 OCR 预处理是 RAG 入库前的质量闸门。若这一层把段落、表格、标题或扫描文字处理坏，后面的 embedding、rerank 和生成模型很难补救。

## 解析输出格式

- 纯文本：简单但丢结构。
- Markdown：适合保留标题和列表。
- HTML：适合保留版式和表格。
- JSON：适合保存块、坐标、页码和层级。

## 图像预处理

- 去噪：减少扫描噪点。
- 锐化：增强字符边缘。
- 超分：提高低分辨率文字可读性。
- 对比度增强：拉开文字与背景。

## 工程原则

预处理的目标不是让图片“看起来更清楚”，而是提升 OCR 和后续结构化解析的稳定性。
