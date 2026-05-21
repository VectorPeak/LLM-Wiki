---
type: method
title: "Prompt 工程"
created: 2026-05-19
updated: 2026-05-19
status: seed
tags:
  - method
  - prompt
  - llm
related:
  - "[[Prompt Cache]]"
  - "[[AI 编程工具面试准备]]"
sources:
  - "[[llm-prompt工程60题]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/大模型Prompt工程60题.md"
method_type: engineering
applies_to: "大模型应用提示词设计、调试和评估"
limitations:
  - "Prompt 技巧对模型和任务敏感，应通过真实样例和回归集验证。"
---

# Prompt 工程

## 定位

Prompt 工程不是“写漂亮提示词”，而是把任务目标、输入约束、输出格式、工具边界和错误恢复策略显式化。它本质上是把隐含需求变成模型可执行的接口契约。

## 常见结构

- 角色与任务：让模型知道它要完成什么。
- 背景与上下文：提供必要信息，避免让模型猜。
- 约束与禁止事项：明确边界。
- 输出格式：用 JSON、Markdown、表格或 schema 固定结构。
- 示例：给少量高质量输入输出对。
- 校验：要求模型检查遗漏、矛盾和不确定性。

## 工程化要点

Prompt 应进入版本管理，并配合测试样例。对于生产系统，prompt 变更应像代码变更一样可回滚、可评估、可追踪。

