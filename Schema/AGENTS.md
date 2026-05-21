# LLMWiki: Codex 维护规则

本知识库由 Codex 维护，采用 Karpathy LLM Wiki 三层结构：`RAW` 保存原始资料，`Wiki` 保存 Codex 编译后的知识节点，`Schema` 保存维护规则。Codex 的任务不是把资料简单摘要一遍，而是把原始资料持续编译成可检索、可链接、可更新的 Obsidian 知识库

## 最高优先级

1. `RAW` 是原始资料层。除非使用者明确要求，Codex 不修改、重写或删除 `RAW` 中的资料。
2. `Wiki` 是知识产物层。Codex 可以创建、更新、拆分、合并这里的页面，但必须保留来源链路。
3. `Schema` 是维护规则层。Codex 在摄取、查询、整理、健康检查之前，先读取相关规则文件。
4. 中文 Markdown 文件默认使用 UTF-8 编码。
5. 输出文件或网址链接时，必须确保链接可直接点击到达。
6. 涉及现代事实、版本、API、项目状态、新闻、论文状态、法律、价格等易变化内容时，输出前应联网核对，优先使用官方文档、论文、项目仓库、原始出处。

## 原始资料边界

`RAW` 只保存使用者放入或明确要求保存的原始资料。Codex 不得在 `RAW` 内创建派生目录或派生文件，包括但不限于 PDF 抽取文本、OCR 结果、切片、embedding 输入、临时 JSON、缓存索引和工具中间产物。

可再生的中间产物统一放在剪藏区下的工具缓存目录：

```text
D:\LLMWiki\LLMWiki\Clippings\.llmwiki-cache\
```

缓存文件可以在摄取时读取，但不能作为最终来源替代原始文件。写入 `Wiki` 的来源链路仍应指向 `RAW` 中的原始资料路径。`Clippings/.llmwiki-cache` 是工具缓存，不是剪藏语料本身。

## 目录职责

- `RAW/01.Inbox`: 临时入口，放未归类资料
- `RAW/02.Logs`: 使用者每周日志、所想、感悟、今日总结、明日目标和阶段复盘
- `RAW/03.Self-Notes`: 使用者自己的原始想法、问题、灵感和手写笔记
- `RAW/04.GitHub`: GitHub 仓库、README、issue、release note、架构说明
- `RAW/05.Research`: 论文、报告、技术长文、研究资料
- `RAW/06.Website`: 网站、网页、产品页、文档站、SEO 或站点结构资料
- `RAW/07.BookCourse`: 书籍、课程、章节笔记、教程、转录稿
- `RAW/08.Leetcode`: 算法题、数据结构、刷题笔记、题解、复杂度分析与面试编码训练
- `RAW/09.Wechat`: 微信公众号文章、技术专栏、面试题合集、行业观点和中文技术长文
- `Wiki`: 按知识类型组织，不复刻 `RAW` 的来源目录
- `Schema`: Codex 操作规程。

## 写作风格

回答和 Wiki 页面应采用务实、精准、有洞察的中文表达。解释重要概念时，先自顶向下给出全局定位，再补相关概念、对偶概念、反向概念；必要时使用联想、类比、对比，但不能牺牲准确性。涉及计算、模型、概率、算法时，适当补充 LaTeX 表达。

Codex 应主动补充使用者可能“不知道自己不知道”的背景，但避免无关扩写。语气以第三人称、分析型表达为主。

## 基本操作入口

- 摄取资料：读取 `Schema/ingest.md`。
- 查询知识库：读取 `Schema/query.md`。
- 新建或更新页面：读取 `Schema/frontmatter.md`。
- 检查结构与目录边界：读取 `Schema/structure.md`。
- 健康检查：读取 `Schema/lint.md`。
- 写作风格：读取 `Schema/style.md`。
- 来源和联网核对：读取 `Schema/source-policy.md`。

## 维护不变量

- 每个 `Wiki` 页面必须有 YAML frontmatter。
- 每次重要摄取后更新 `Wiki/index.md`、`Wiki/hot.md`、`Wiki/log.md`。
- 新资料与旧资料冲突时，不能静默覆盖旧说法；应使用 contradiction 标记并说明冲突来源。
- 优先更新已有页面，避免创建重复概念页。
- 使用 Obsidian wikilink：`[[页面名]]`。除非是外部网址或本地文件路径，不使用普通 Markdown 链接替代内部链接。
- 派生文本和工具缓存不得写入 `RAW`；如需保留，写入 `D:\LLMWiki\LLMWiki\Clippings\.llmwiki-cache\`。

## 当前 RAW 分区

当前 `RAW` 分区以磁盘实际结构为准：

- `RAW/01.Inbox`: 临时入口，放未归类资料。
- `RAW/02.Logs`: 每周日志、所想、感悟、今日总结、明日目标和阶段复盘。
- `RAW/03.Self-Notes`: 使用者自己的原始想法、问题、灵感和手写笔记。
- `RAW/04.GitHub`: GitHub 仓库、README、issue、release note、架构说明；GitHub 项目入库先读 `Schema/github-raw.md`。
- `RAW/05.Research`: 论文、报告、技术长文、研究资料。
- `RAW/06.Website`: 网站、网页、产品页、文档站、SEO 或站点结构资料。
- `RAW/07.BookCourse`: 书籍、课程、章节笔记、教程、转录稿。
- `RAW/08.Leetcode`: 算法题、数据结构、刷题笔记、题解、复杂度分析与面试编码训练。
- `RAW/09.Wechat`: 微信公众号文章、技术专栏、面试题合集、行业观点和中文技术长文。

`RAW/08.Business`、`RAW/09.Leetcode`、`RAW/10.Interview` 是旧结构引用，不再作为当前 RAW 分区使用。
