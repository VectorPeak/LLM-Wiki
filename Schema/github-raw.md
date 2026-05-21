# GitHub RAW 采集规则

本文件规定 Codex 收到 GitHub 项目链接时，如何把它存入 `RAW/04.GitHub` 原始语料库。

核心原则：GitHub 仓库不是直接进入 `Wiki` 的知识节点，而是先被保存为可追溯、可复查的 RAW 来源。GitHub 项目默认由 Codex 在本地参考 GitMD 的输出格式生成结构化 Markdown 语料，不调用 `gitmd.org`。

## 适用范围

当使用者给出以下输入时，使用本规则：

- GitHub 仓库 URL，例如 `https://github.com/karpathy/nanoGPT`
- `owner/repo` 形式，例如 `karpathy/micrograd`
- GitHub issue、release、README、架构说明等仓库相关资料

默认目标目录：

```text
D:\LLMWiki\LLMWiki\RAW\04.GitHub\
```

## 默认流程

1. 确认仓库 URL、owner、repo、默认分支、当前访问时间。
2. 读取 GitHub 仓库元数据、README、文件树、项目配置和关键入口文件。
3. 参考 GitMD 的结构生成 GitHub RAW 采集件，并保存到 `RAW/04.GitHub`。
4. 在文件 frontmatter 中记录原始 GitHub URL、格式参考、生成时间、仓库标识、提交版本和处理方式。
5. 后续 `/Ingest` 时，再从该 RAW 文件编译出 `Wiki/sources`、`Wiki/projects`、`Wiki/concepts`、`Wiki/methods` 等页面。

## GitMD 参考格式

不调用：

```text
https://gitmd.org/
```

`gitmd.org` 仅作为格式参考，不作为运行依赖。Codex 应直接使用 GitHub 原仓库和 GitHub API / MCP 可获得的信息，在本地生成同类结构化 Markdown。

操作语义：

```text
GitHub repo URL
  -> GitHub metadata / README / tree / selected files
  -> GitMD-style structured markdown generated locally
  -> RAW/04.GitHub/<owner>__<repo>.gitmd.md
```

参考 GitMD 格式的原因：

- 它读取 README、文件树和仓库元数据。
- 它先选择最能解释项目结构的关键文件，再生成 Markdown。
- 输出通常包含项目定位、问题背景、数据流、关键依赖、目录解释、阅读路径、setup 步骤和 AI agent 可读元数据。

本地生成的 GitMD-style 文件仍然是 RAW 来源，不是最终知识页。最终知识页必须在 `Wiki` 中重新编译。

## 文件命名

推荐命名：

```text
RAW/04.GitHub/<owner>__<repo>.gitmd.md
```

示例：

```text
RAW/04.GitHub/karpathy__nanoGPT.gitmd.md
RAW/04.GitHub/karpathy__micrograd.gitmd.md
RAW/04.GitHub/karpathy__llm.c.gitmd.md
```

如果同一仓库需要保留多次采集版本，追加日期：

```text
RAW/04.GitHub/karpathy__nanoGPT.2026-05-19.gitmd.md
```

## Frontmatter 模板

每个 GitHub RAW 文件开头必须包含：

```markdown
---
raw_type: github
capture_method: gitmd-style-local
owner: "karpathy"
repo: "nanoGPT"
repo_url: "https://github.com/karpathy/nanoGPT"
format_reference: "https://gitmd.org/"
captured_at: "2026-05-19"
default_branch: ""
commit: ""
license: ""
status: raw
notes:
  - "Generated locally by Codex using a GitMD-style structure; gitmd.org was not called."
---
```

字段说明：

- `raw_type`: 固定为 `github`。
- `capture_method`: 固定写 `gitmd-style-local`，表示参考 GitMD 格式由 Codex 本地生成。
- `repo_url`: 原始 GitHub 仓库链接。
- `format_reference`: 格式参考来源，可填 `https://gitmd.org/`。
- `captured_at`: 采集日期。
- `default_branch`、`commit`、`license`: 如果可查，应填写；查不到则留空。

## 本地生成读取顺序

Codex 生成 GitMD-style RAW 时，按以下顺序读取：

1. GitHub 仓库元数据、默认分支、当前 commit、license、更新时间。
2. 文件树。
3. `package.json`、`pyproject.toml`、`requirements.txt`、`Cargo.toml`、`go.mod`、`Dockerfile`、`docker-compose.yml` 等项目配置。
4. 关键入口文件，例如 `main.py`、`train.py`、`model.py`、`src/`、`app/`、`cli/`。
5. release、issue、wiki 或 docs，仅在它们对理解项目结构有必要时读取。

输出必须保持 GitMD 风格，至少包含：

- 一句话定位
- 解决的问题
- 仓库结构
- 核心文件
- 数据流或控制流
- 关键依赖
- 推荐阅读路径
- setup / run 方式
- 可沉淀的概念
- 可复用的代码模式
- 原始链接和采集日期

## 进入 Wiki 的编译规则

GitHub RAW 文件摄取后，不应只生成摘要。至少判断是否需要生成或更新以下页面：

```text
Wiki/sources/<repo>.md
Wiki/projects/<repo>.md
Wiki/entities/<author-or-org>.md
Wiki/concepts/<concept>.md
Wiki/methods/<code-pattern>.md
Wiki/questions/<question>.md
Wiki/comparisons/<comparison>.md
```

以 Karpathy 项目为例：

```text
RAW/04.GitHub/karpathy__nanoGPT.gitmd.md
  -> Wiki/sources/karpathy-nanoGPT.md
  -> Wiki/projects/nanoGPT.md
  -> Wiki/entities/Andrej Karpathy.md
  -> Wiki/concepts/Transformer.md
  -> Wiki/concepts/Language Modeling.md
  -> Wiki/methods/training-loop.md
  -> Wiki/methods/sampling.md
```

## 边界

- 不把完整仓库 clone 结果直接塞入 `RAW/04.GitHub`，除非使用者明确要求归档代码快照。
- 不把 GitMD-style RAW 直接当作 `Wiki/projects` 或 `Wiki/concepts` 页面。
- 不把 GitMD-style 生成内容中的推断当作最终事实；重要项仍需回到 GitHub 原仓库核对。
- 如果仓库当前状态、版本、release、license、维护状态会影响结论，输出前必须联网核对。
- 如果 GitMD-style RAW 和 GitHub 原仓库冲突，以 GitHub 原仓库为准。
