---
type: source
title: "RAG 工程链路脏活深挖"
created: 2026-05-14
updated: 2026-05-14
status: developing
tags:
  - source
  - interview
  - rag
  - ocr
related:
  - "[[RAG 工程摄取链路]]"
  - "[[PDF 解析与 OCR 预处理]]"
  - "[[MCP 与 CLI]]"
sources: []
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/Wechat_波哥聊大模型_RAG工程链路脏活深挖.md"
source_type: article
author: "波哥聊大模型"
date_published: ""
url: "https://mp.weixin.qq.com/s/epasjU2ObYmvtkIZYXAuPg"
confidence: medium
key_claims:
  - "RAG 工程面试会追问 embedding 微调、PDF 解析、OCR 预处理和工具协议差异。"
  - "PDF 解析输出格式和 OCR 前处理质量会显著影响后续检索质量。"
  - "MCP 和 CLI 的本质区别在于结构化工具协议与命令行执行接口。"
---

# RAG 工程链路脏活深挖

## 摘要

这篇面经围绕 RAG 工程链路中容易被忽略的“脏活”展开：embedding 训练目标、PDF 解析格式、图片清晰度判断、OCR 前处理、MCP 与 CLI 的区别。它的价值在于提醒 RAG 系统并不是只有 embedding 和向量库，前处理质量常常决定后续上限。

## 关键断言

- OCR 准确率受去噪、锐化、超分和对比度增强影响。
- PDF 解析要根据后续用途选择 Markdown、HTML、JSON、纯文本或布局结构。
- MCP 更适合作为 LLM 工具调用协议，CLI 更像操作系统层面的命令入口。

## 涉及概念

- [[PDF 解析与 OCR 预处理]]
- [[MCP 与 CLI]]
- [[RAG 文本分块]]

## 可复用方法

- [[RAG 工程摄取链路]]
