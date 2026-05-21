# 摄取规则

摄取是把 `RAW` 原始资料编译成 `Wiki` 知识节点的过程。Codex 不应只写摘要，而应抽取来源、实体、概念、方法、项目、问题和对比关系。

## 摄取前检查

1. 阅读 `Schema/AGENTS.md`、`Schema/structure.md`、`Schema/frontmatter.md`。
2. 阅读 `Wiki/hot.md`，理解最近上下文。
3. 阅读 `Wiki/index.md`，避免创建重复页面。
4. 判断资料来自哪个 `RAW` 分区。
5. 判断资料类型：`log`、`website`、`github`、`paper`、`book`、`course`、`self_note`、`article`、`leetcode`、`wechat`、`transcript`、`data` 等。

## 中间产物规则

摄取可以生成可再生的读取辅助物，例如 PDF 抽取文本、OCR 结果、分块文本或临时索引，但这些文件不得写入 `RAW`。统一写入：

```text
D:\LLMWiki\LLMWiki\Clippings\.llmwiki-cache\
```

推荐按原始路径镜像缓存结构，例如：

```text
D:\LLMWiki\LLMWiki\Clippings\.llmwiki-cache\extracted_text\RAW\05.Research\example.txt
```

缓存只用于帮助 Codex 阅读原始资料。创建 `Wiki/sources/` 页面时，`source_path` 必须指向 `RAW` 中的原始文件，而不是缓存文件。

注意：`Clippings/.llmwiki-cache` 不参与 `/Ingest` 的原始资料枚举。它只在处理对应 `RAW` 原始文件时作为读取加速或解析辅助。

## RAW 分区处理

- `01.Inbox`: 先判断资料类型。可以在来源摘要页记录建议归属，但默认不移动原文件。
- `02.Logs`: 标记为 `source_type: log`。优先抽取时间线、今日总结、明日目标、阶段目标、情绪/精力模式、反复出现的问题、已形成的决策和可执行行动项。
- `03.Self-Notes`: 标记为 `source_type: self_note`。使用者观点不自动等同于客观事实。
- `04.GitHub`: 优先抽取项目、仓库、模块、架构、依赖、设计决策、方法。
- `05.Research`: 优先抽取论文/报告断言、方法、概念、证据、局限和开放问题。
- `06.Website`: 优先抽取网站、产品、页面结构、目标用户、内容策略、概念。
- `07.BookCourse`: 优先抽取章节结构、概念、学习路径、方法和可迁移框架。
- `08.Leetcode`: 标记为 `source_type: leetcode`。优先抽取题目、约束、数据结构、算法范式、复杂度、边界条件、易错点、模板和可迁移解题模式。
- `09.Wechat`: 标记为 `source_type: wechat`。优先抽取文章主题、作者/公众号、关键断言、概念解释、面试题、工程经验、可验证事实和需要二次核对的观点。

## 单资料摄取流程

1. 完整读取原始资料，不只看标题和开头。
2. 创建或更新 `Wiki/sources/` 中的来源摘要页。
3. 抽取实体，创建或更新 `Wiki/entities/`。
4. 抽取项目，创建或更新 `Wiki/projects/`。
5. 抽取概念，创建或更新 `Wiki/concepts/`。
6. 抽取方法，创建或更新 `Wiki/methods/`。
7. 如果来自 `RAW/02.Logs`，创建或更新 `Wiki/logs/` 中的复盘、目标或行动页。
8. 如果来自 `RAW/08.Leetcode`，创建或更新 `Wiki/concepts/`、`Wiki/methods/` 或 `Wiki/questions/` 中的算法、题型和解题模式页面。
9. 如果来自 `RAW/09.Wechat`，优先判断其主题归属，再创建或更新 `Wiki/sources/`、`Wiki/concepts/`、`Wiki/questions/`、`Wiki/methods/` 或 `Wiki/projects/` 页面。
10. 归入或更新 `Wiki/domains/` 中的主题域。
11. 如果存在明确比较对象，创建或更新 `Wiki/comparisons/`。
12. 如果资料回答了重要问题，创建或更新 `Wiki/questions/`。
13. 更新 `Wiki/index.md`。
14. 更新 `Wiki/hot.md`。
15. 在 `Wiki/log.md` 顶部追加日志。

## 来源摘要页模板

```markdown
---
type: source
title: "来源标题"
created: YYYY-MM-DD
updated: YYYY-MM-DD
status: developing
tags:
  - source
related:
  - "[[相关页面]]"
sources: []
raw_bucket: "05.Research"
source_path: "RAW/05.Research/example.md"
source_type: paper
author: ""
date_published: YYYY-MM-DD
url: ""
confidence: medium
key_claims:
  - "关键断言"
---

# 来源标题

## 摘要

## 关键断言

## 涉及实体

## 涉及概念

## 可复用方法

## 局限与不确定性

## 可继续追问
```

## 冲突处理

如果新资料与旧页面冲突，不要静默覆盖旧内容。在相关页面加入：

```markdown
> [!contradiction] 与 [[新来源]] 冲突
> 旧页面认为 X，新来源认为 Y。需要检查日期、语境、定义范围和证据强度。
```

冲突不是错误，而是知识库的重要资产。

## 批量摄取

批量摄取时先列出待处理文件和分区。每 10 个来源做一次小结。批量结束后统一更新 `index.md`、`hot.md`、`log.md`，并做一次交叉链接检查。

## 禁止事项

- 不修改 `RAW` 原始资料。
- 不在 `RAW` 内创建 `_extracted_text`、`ocr`、`cache`、`chunks`、`tmp` 等派生目录。
- 不把缓存文本当成正式来源；正式来源必须回指 `RAW` 原始文件。
- 不为同一概念创建多个近义页面。
- 不跳过来源摘要页。
- 不跳过 `index.md`、`hot.md`、`log.md` 更新。
- 不把使用者自笔记直接写成客观事实。

## GitHub RAW 入库补充

当使用者给出 GitHub 项目链接、`owner/repo` 或仓库相关资料时，先读取 `Schema/github-raw.md`。

默认处理方式：

1. 不调用 `gitmd.org`；由 Codex 本地读取 GitHub 原仓库信息。
2. 参考 GitMD 的结构，将公开 GitHub 仓库处理成结构化 Markdown。
3. 将生成结果保存到 `RAW/04.GitHub`，命名为 `<owner>__<repo>.gitmd.md`。
4. 在 frontmatter 中标记 `capture_method: gitmd-style-local`。
5. 后续摄取时，再从该 RAW 文件编译 `Wiki/sources`、`Wiki/projects`、`Wiki/concepts`、`Wiki/methods` 等页面。

GitMD-style 输出是 GitHub RAW 原始语料的规范化采集件，不是最终 Wiki 知识页。
