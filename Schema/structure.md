# 结构规则

本知识库采用三层结构：

```text
LLMWiki/
├─ RAW/       # 原始资料层
├─ Wiki/      # Codex 编译后的知识层
└─ Schema/    # Codex 维护规则层
```

核心原则：`RAW` 按资料来源组织，`Wiki` 按知识类型组织。不要让 `Wiki` 复刻 `RAW` 的目录结构。

可再生的中间产物不属于三层结构。PDF 抽取文本、OCR 结果、切片、embedding 输入、临时 JSON 和工具缓存应放在剪藏区下的工具缓存目录：

```text
D:\LLMWiki\LLMWiki\Clippings\.llmwiki-cache\
```

## RAW: 原始资料层

`RAW` 是输入队列和证据仓库。它保留资料最初进入知识库时的形态，类似数据库里的原始日志。

`RAW` 内不放派生文件。即使 Codex 为了读取 PDF 或图片临时生成文本，也不能在 `RAW` 下创建 `_extracted_text`、`cache`、`chunks`、`ocr` 等目录。中间产物只能进入 `D:\LLMWiki\LLMWiki\Clippings\.llmwiki-cache\`，并且可以随时重建。

`Clippings/.llmwiki-cache` 虽位于 `Clippings` 下，但语义上不是剪藏资料，而是工具缓存。摄取和查询时不要把其中内容当作原始语料入口。

```text
RAW/
├─ 01.Inbox/
├─ 02.Logs/
├─ 03.Self-Notes/
├─ 04.GitHub/
├─ 05.Research/
├─ 06.Website/
├─ 07.BookCourse/
├─ 08.Leetcode/
└─ 09.Wechat/
```

- `01.Inbox`: 暂存未归类资料。摄取时应判断更合适的来源桶，但不强制移动原文件。
- `02.Logs`: 每周日志、所想、感悟、今日总结、明日目标、阶段复盘。它记录时间线和自我观察，适合沉淀为目标、模式、问题、决策和复盘页。
- `03.Self-Notes`: 使用者自己的想法。它是高价值资料，但不等同于客观事实。
- `04.GitHub`: 开源项目、仓库、issue、release、代码架构资料。
- `05.Research`: 论文、报告、研究型文章。
- `06.Website`: 网页、站点、产品、文档站相关资料。
- `07.BookCourse`: 书籍、课程、章节、教程资料。
- `08.Leetcode`: 算法题、数据结构、刷题笔记、题解、复杂度分析与面试编码训练资料。
- `09.Wechat`: 微信公众号文章、技术专栏、面试题合集、行业观点和中文技术长文。

## Wiki: 知识产物层

`Wiki` 是 Codex 的主要工作区。它把原始资料拆解成可链接的知识节点，类似从原始日志生成的物化视图。

```text
Wiki/
├─ index.md
├─ hot.md
├─ log.md
├─ overview.md
├─ sources/
├─ concepts/
├─ entities/
├─ domains/
├─ comparisons/
├─ questions/
├─ projects/
├─ methods/
├─ logs/
└─ meta/
```

- `index.md`: 全库主索引。
- `hot.md`: 最近上下文缓存，控制在约 500 字。
- `log.md`: 操作日志，新条目写在顶部。
- `overview.md`: 全库综述。
- `sources/`: 每份原始资料对应的来源摘要页。
- `concepts/`: 概念、术语、理论、模型、机制。
- `entities/`: 人、组织、产品、地点、仓库等实体。
- `domains/`: 顶层主题域和知识版图。
- `comparisons/`: 对比分析。
- `questions/`: 值得沉淀的问题与答案。
- `projects/`: 网站、GitHub 项目、产品、课程项目等长期对象。
- `methods/`: 学习法、研究法、工程方法、分析框架、操作流程。
- `logs/`: 从 `RAW/02.Logs` 编译出的周复盘、日总结、目标、情绪/认知模式和行动线索。
- `meta/`: lint 报告、仪表盘、约定说明、维护记录。

## Schema: 维护规则层

`Schema` 规定 Codex 如何维护这个知识库。它不是普通笔记，而是可执行规程。

```text
Schema/
├─ AGENTS.md
├─ structure.md
├─ frontmatter.md
├─ ingest.md
├─ query.md
├─ lint.md
├─ style.md
└─ source-policy.md
```

## 设计边界

同一个资料来源可能生成多个 Wiki 页面。例如一篇论文可以生成一个 `sources` 页、多个 `concepts` 页、一个 `methods` 页和一个 `questions` 页。反过来，一个 `concepts` 页面也可以引用多个 `RAW` 来源。

如果摄取需要先把 PDF 转成文本，转换结果只是读取辅助物，不是新的来源。`source_path` 仍记录原 PDF 在 `RAW` 中的位置；缓存文本路径最多写入维护日志或本地操作说明，不写成来源事实。

数学上可以把 `Wiki` 看成图：

$$
G = (V, E)
$$

其中每篇 Wiki 页面是节点 \(V\)，wikilink 和 `related` 字段形成边 \(E\)。`RAW` 是证据集合，`Schema` 是生成和维护这张图的规则。

## RAW/04.GitHub 采集约定

`RAW/04.GitHub` 保存 GitHub 仓库和仓库相关资料。使用者给出 GitHub 项目时，默认不直接 clone 全仓库到 RAW，也不调用 `gitmd.org`，而是按 `Schema/github-raw.md` 由 Codex 本地参考 GitMD 格式生成结构化 Markdown 原始语料。

推荐路径：

```text
RAW/04.GitHub/<owner>__<repo>.gitmd.md
```

GitMD-style 文件属于 RAW 原始语料，因为它是对 GitHub 仓库的规范化采集结果；但它仍然不是 `Wiki` 知识页。`Wiki` 应继续按知识类型拆分为 `sources`、`projects`、`concepts`、`methods` 等页面。

## 当前 RAW 分区总表

当前 `RAW` 目录以实际磁盘结构为准：

```text
RAW/
├─ 01.Inbox/
├─ 02.Logs/
├─ 03.Self-Notes/
├─ 04.GitHub/
├─ 05.Research/
├─ 06.Website/
├─ 07.BookCourse/
├─ 08.Leetcode/
└─ 09.Wechat/
```

`08.Business`、`09.Leetcode`、`10.Interview` 是旧结构引用，不再作为当前 RAW 分区使用。后续新增资料必须进入上表中的现行分区。
