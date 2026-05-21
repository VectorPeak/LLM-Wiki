# 查询规则

查询是从 `Wiki` 中检索和综合知识，而不是让 Codex 只凭模型记忆回答。优先读取本地 Wiki；当事实可能过期或需要外部验证时，再联网核对。

## 查询深度

### Quick

适用于简单事实查找。

读取范围：

1. `Wiki/hot.md`
2. `Wiki/index.md`

如果这两个文件无法回答，应说明“当前 quick 缓存不足”，再升级为 standard。

### Standard

默认模式，适用于大多数问题。

读取范围：

1. `Wiki/hot.md`
2. `Wiki/index.md`
3. 3 到 5 个最相关页面

只沿关键 wikilink 追踪到第二层，避免全库乱翻。

### Deep

适用于综合、比较、体系化解释、跨主题分析。

读取范围：

1. `Wiki/hot.md`
2. `Wiki/index.md`
3. 所有相关子索引和页面
4. 必要时联网核对

Deep 查询的高价值回答应沉淀到 `Wiki/questions/`。

## 回答规则

1. 先说明判断依据来自哪些 Wiki 页面或外部来源。
2. 重要概念按 `Schema/style.md` 的自顶向下规则解释。
3. 如果本地 Wiki 覆盖不足，应明确指出缺口。
4. 如果联网资料与本地 Wiki 冲突，应标记冲突，不直接替换。
5. 如果回答产生了可复用洞察，应建议或直接写入 `Wiki/questions/`，具体取决于使用者是否要求执行。

## 问题页模板

```markdown
---
type: question
title: "问题标题"
created: YYYY-MM-DD
updated: YYYY-MM-DD
status: developing
tags:
  - question
related:
  - "[[相关概念]]"
sources:
  - "[[相关来源摘要]]"
raw_bucket: ""
source_path: ""
question: "使用者原始问题"
answer_quality: solid
---

# 问题标题

## 问题

## 简答

## 详细解释

## 依据

## 仍需补充
```

## 不足处理

如果 Wiki 中没有足够资料，不要编造。应说明：

- 缺少哪个子问题的资料。
- 哪类来源最能补足。
- 是否需要从 `RAW` 新增资料或联网查找资料。
