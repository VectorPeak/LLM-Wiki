# Frontmatter 规则

每个 `Wiki` 页面都必须以扁平 YAML frontmatter 开头。Obsidian Properties 对嵌套对象支持不稳定，因此不要使用嵌套 YAML。

## 通用字段

所有 `Wiki` 页面必须包含：

```yaml
---
type: concept
title: "页面标题"
created: 2026-05-05
updated: 2026-05-05
status: seed
tags:
  - example
  - concept
related:
  - "[[相关页面]]"
sources:
  - "[[来源摘要页]]"
raw_bucket: "05.Research"
source_path: "RAW/05.Research/example.md"
---
```

## 字段含义

- `type`: 页面类型。可用值：`source`、`entity`、`concept`、`domain`、`comparison`、`question`、`project`、`method`、`log`、`business`、`overview`、`meta`。
- `title`: 人类可读标题，应与文件名一致或高度接近。
- `created`: 创建日期，格式 `YYYY-MM-DD`。
- `updated`: 最近内容更新日期，格式 `YYYY-MM-DD`。
- `status`: 成熟度。可用值：`seed`、`developing`、`mature`、`evergreen`。
- `tags`: 标签列表，使用小写或中英文稳定命名。
- `related`: 相关 Wiki 页面，必须使用带引号的 wikilink。
- `sources`: 支撑此页的来源摘要页，必须使用带引号的 wikilink。
- `raw_bucket`: 原始资料所在的 `RAW` 分区。
- `source_path`: 原始资料相对路径。

## status 取值

- `seed`: 刚创建，内容很少。
- `developing`: 有实质内容，但仍需扩展、核对或补链接。
- `mature`: 内容较完整，有来源、有链接、有结构。
- `evergreen`: 基本稳定，短期不太需要更新。

## 类型扩展字段

### source

```yaml
source_type: article
author: ""
date_published: 2026-05-05
url: ""
confidence: high
key_claims:
  - "核心断言一"
  - "核心断言二"
```

`source_type` 可用值：`article`、`website`、`github`、`paper`、`book`、`course`、`self_note`、`log`、`leetcode`、`wechat`、`transcript`、`data`、`video`、`podcast`。

### entity

```yaml
entity_type: person
role: ""
first_mentioned: "[[来源摘要页]]"
```

`entity_type` 可用值：`person`、`organization`、`product`、`repository`、`place`、`company`。

### concept

```yaml
complexity: intermediate
domain: ""
aliases:
  - "别名"
  - "英文名"
```

`complexity` 可用值：`basic`、`intermediate`、`advanced`。

### project

```yaml
project_type: github
homepage: ""
repository: ""
status_note: ""
```

`project_type` 可用值：`website`、`github`、`product`、`course`、`book`、`internal`。

### method

```yaml
method_type: learning
applies_to: ""
limitations:
  - "限制一"
```

`method_type` 可用值：`learning`、`research`、`engineering`、`analysis`、`workflow`。

### log

```yaml
log_type: weekly
period: "2026-W19"
mood: ""
energy: ""
next_actions:
  - "行动项"
```

`log_type` 可用值：`daily`、`weekly`、`monthly`、`reflection`、`summary`、`goal`。

### business

```yaml
business_type: project
company: ""
stakeholders:
  - ""
project_status: active
decision_date: YYYY-MM-DD
```

`business_type` 可用值：`project`、`meeting`、`decision`、`deliverable`、`requirement`、`risk`、`retrospective`。

### comparison

```yaml
subjects:
  - "[[对象 A]]"
  - "[[对象 B]]"
dimensions:
  - "性能"
  - "成本"
verdict: "一句话结论。"
```

### question

```yaml
question: "使用者原始问题"
answer_quality: solid
```

`answer_quality` 可用值：`draft`、`solid`、`definitive`。

## 格式规则

1. 只使用扁平 YAML，不嵌套对象。
2. 日期统一为 `YYYY-MM-DD`。
3. 列表统一用多行 `- item`，不要用内联数组。
4. YAML 中的 wikilink 必须加引号，例如 `"[[Transformer]]"`。
5. `related` 和 `sources` 优先链接 Wiki 页面，不直接塞外部网址。
6. 每次实质编辑页面内容，都更新 `updated`。
