# 健康检查规则

健康检查用于防止 Wiki 随内容增长而退化为散乱笔记。每完成 10 到 15 次摄取，或每周进行一次 lint。

## 检查项

1. 孤儿页：没有任何其他页面链接到它。
2. 死链：存在 `[[页面名]]`，但目标页面不存在。
3. 重复概念：多个页面讲同一个概念或高度重叠。
4. 缺失页面：多个页面反复提到某概念或实体，但没有独立页面。
5. 缺失来源：重要断言没有 `sources` 支撑。
6. 缺失 frontmatter：页面缺少必填 YAML 字段。
7. 陈旧断言：旧页面被新来源更新或反驳。
8. 交叉引用不足：页面提到实体或概念但没有 wikilink。
9. 索引过期：`index.md` 没有记录已存在页面，或记录了不存在页面。
10. 空章节：标题存在但正文为空。
11. 空目录：`Wiki` 下出现没有 Markdown 文件的目录；若该目录不在 `Schema/structure.md` 的 Wiki 类型目录清单中，标记为异常。
12. RAW 分区漂移：`raw_bucket` 或 `source_path` 指向旧分区、未知分区或当前磁盘不存在的 RAW 目录。
13. 失效来源路径：`source_path` 指向的本地 RAW 文件或目录不存在。
14. 未摄取 RAW 覆盖率：统计 RAW 文件是否被任一 Wiki 页面 `source_path` 回指；这是摄取队列信息，不默认等同错误。
15. Schema 漂移：Schema 与实际目录、frontmatter 字段、采集方法命名不一致。

## 报告位置
lint 报告写入：
```text
Wiki/meta/lint-report-YYYY-MM-DD.md
```

## 报告模板
```markdown
---
type: meta
title: "Lint Report YYYY-MM-DD"
created: YYYY-MM-DD
updated: YYYY-MM-DD
status: developing
tags:
  - meta
  - lint
related: []
sources: []
raw_bucket: ""
source_path: ""
---

# Lint Report: YYYY-MM-DD

## Summary

- Pages scanned:
- Issues found:
- Auto-fixed:
- Needs review:

## Orphan Pages

## Dead Links

## Duplicate Concepts

## Missing Pages

## Missing Sources

## Frontmatter Gaps

## Directory Gaps

## Invalid Source Paths

## RAW Partition Drift

## Index Coverage Gaps

## Uningested RAW Coverage

## Schema Drift

## Stale Claims

## Cross-Reference Gaps

## Stale Index Entries

## Empty Sections
```

## 自动修复边界

可以自动修复：

- 补齐明显缺失的 frontmatter 字段。
- 为反复出现的实体或概念创建 stub 页面。
- 给明确匹配的实体或概念补 wikilink。
- 更新 `index.md` 中明显缺失的页面记录。
- 将已确认存在的新 RAW 路径替换旧 `source_path`。
- 删除已经确认为空且不在 Schema 结构清单中的空目录。

需要使用者确认：

- 删除孤儿页。
- 删除非空目录或迁移其内容。
- 合并重复概念。
- 解决 contradiction。
- 改写高层概念定义。
- 大规模改变页面归属、概念边界或来源解释。

## 命名规则

- 文件名使用清晰中文或英文标题，避免无意义编号。
- 同一层级下避免同义文件名。
- 内部链接使用 `[[页面名]]`。
- 页面标题应与文件名一致或高度接近。
