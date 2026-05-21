---
raw_type: github
capture_method: gitmd-style-local
owner: "jerry-ai-dev"
repo: "MODULAR-RAG-MCP-SERVER"
repo_url: "https://github.com/jerry-ai-dev/MODULAR-RAG-MCP-SERVER"
format_reference: "https://gitmd.org/"
captured_at: "2026-05-19"
default_branch: "main"
commit: "f658c5a4011c8b826707a65a3b11ce9301b0626f"
license: "MIT declared in pyproject.toml; GitHub API license field was null at capture time"
status: raw
notes:
  - "Generated locally by Codex using a GitMD-style structure; gitmd.org was not called."
  - "This file follows the GitMD-style GitHub RAW structure defined in Schema/github-raw.md."
  - "Repository metadata was checked through GitHub MCP and GitHub REST API on 2026-05-19."
---

# jerry-ai-dev/MODULAR-RAG-MCP-SERVER

## 一句话定位

`MODULAR-RAG-MCP-SERVER` 是一个 Python 编写的模块化 RAG MCP Server 项目，把文档摄取、混合检索、重排、回答生成、评估、可观测性和 MCP 工具暴露组织成一套可插拔的学习与实战工程框架。

## 原始链接

- GitHub: [jerry-ai-dev/MODULAR-RAG-MCP-SERVER](https://github.com/jerry-ai-dev/MODULAR-RAG-MCP-SERVER)
- 当前采集提交: [f658c5a4011c8b826707a65a3b11ce9301b0626f](https://github.com/jerry-ai-dev/MODULAR-RAG-MCP-SERVER/commit/f658c5a4011c8b826707a65a3b11ce9301b0626f)
- README: [README.md](https://github.com/jerry-ai-dev/MODULAR-RAG-MCP-SERVER/blob/main/README.md)
- DEV_SPEC: [DEV_SPEC.md](https://github.com/jerry-ai-dev/MODULAR-RAG-MCP-SERVER/blob/main/DEV_SPEC.md)

## 仓库元数据

- owner/repo: `jerry-ai-dev/MODULAR-RAG-MCP-SERVER`
- default branch: `main`
- captured commit: `f658c5a4011c8b826707a65a3b11ce9301b0626f`
- latest checked commit message: `feat: Modular RAG MCP Server - Complete implementation with MCP tools, ingestion pipeline, hybrid search, dashboard, evaluation system, and agent skills`
- commit author date: `2026-03-03T12:25:44Z`
- commit committer date: `2026-03-06T06:01:01Z`
- GitHub REST `pushed_at`: `2026-03-10T07:00:39Z`
- GitHub REST `updated_at`: `2026-05-19T00:35:34Z`
- stars at capture time: `910`
- forks at capture time: `193`
- open issues at capture time: `4`
- license: GitHub API did not expose a license object; `pyproject.toml` declares `MIT`.

## 解决的问题

这个仓库面向两个重叠目标：

1. 工程目标：把 RAG 系统中常见的摄取、检索、重排、生成、评估和可观测环节拆成可替换模块，并通过 MCP 协议暴露给 Copilot、Claude、Cursor 等 AI 客户端。
2. 学习目标：作为大模型应用、RAG 工程、MCP 工具开发、Skill 驱动开发和面试项目准备的完整样例。

它处理的核心矛盾是：普通 RAG demo 往往只演示向量检索和问答，但真实项目需要可替换 provider、可追踪链路、可评估效果、可接入 AI 助手、可扩展到业务文档和多模态资料。

## 关键能力

| 模块 | 作用 |
| --- | --- |
| Ingestion Pipeline | PDF 到 Markdown、Chunk、Transform、Embedding、Upsert 的数据摄取链路 |
| Hybrid Search | Dense 向量检索、BM25 稀疏检索、RRF 融合、可选 Rerank |
| MCP Server | 暴露 `query_knowledge_hub`、`list_collections`、`get_document_summary` 等工具 |
| Dashboard | README 描述为 Streamlit 六页面管理平台 |
| Evaluation | 支持 Ragas 与 custom evaluation 的评估入口 |
| Observability | 通过日志和 trace 记录摄取与查询链路 |
| Skill Workflow | 以 DEV_SPEC 和 Agent Skills 驱动编码、测试、打包、配置 |

## 仓库结构

```text
.
├─ .claude/
├─ .github/
├─ DEV_SPEC.md
├─ README.md
├─ config/
│  ├─ prompts/
│  ├─ settings.yaml
│  └─ test_credentials.yaml.example
├─ main.py
├─ pyproject.toml
├─ scripts/
│  ├─ evaluate.py
│  ├─ ingest.py
│  ├─ query.py
│  └─ start_dashboard.py
├─ src/
│  ├─ core/
│  ├─ ingestion/
│  ├─ libs/
│  ├─ mcp_server/
│  └─ observability/
└─ tests/
   ├─ e2e/
   ├─ fixtures/
   ├─ integration/
   └─ unit/
```

## 核心文件

- `README.md`: 项目定位、能力列表、分支说明、使用策略、简历包装建议、FAQ 和后续安排。
- `DEV_SPEC.md`: 大体量开发规格文档，作为 Skill 驱动开发的任务和架构依据。
- `pyproject.toml`: Python 包元数据、依赖、测试配置、ruff/mypy 配置和 CLI 入口。
- `main.py`: 当前主入口，加载 `config/settings.yaml` 并初始化日志。
- `config/settings.yaml`: LLM、Embedding、Vision LLM、VectorStore、Retrieval、Rerank、Evaluation、Observability、Ingestion 的集中配置。
- `src/core/settings.py`: 配置加载和校验。
- `src/core/types.py`: 项目核心数据结构。
- `src/ingestion/pipeline.py`: 文档摄取主流程。
- `src/ingestion/document_manager.py`: 文档管理与摄取状态管理。
- `src/core/query_engine/hybrid_search.py`: 混合检索编排。
- `src/core/query_engine/dense_retriever.py`: Dense 检索。
- `src/core/query_engine/sparse_retriever.py`: 稀疏检索。
- `src/core/query_engine/fusion.py`: RRF 等融合策略。
- `src/core/query_engine/reranker.py`: 重排环节。
- `src/core/query_engine/query_processor.py`: 查询预处理或查询流程处理。
- `src/mcp_server/server.py`: MCP server 主体。
- `src/mcp_server/protocol_handler.py`: MCP 协议处理。
- `src/mcp_server/tools/query_knowledge_hub.py`: 知识库查询工具。
- `src/mcp_server/tools/list_collections.py`: 集合列表工具。
- `src/mcp_server/tools/get_document_summary.py`: 文档摘要工具。
- `scripts/ingest.py`: 命令行摄取入口。
- `scripts/query.py`: 命令行查询入口。
- `scripts/evaluate.py`: 评估入口。
- `scripts/start_dashboard.py`: Dashboard 启动入口。

## 数据流

### 摄取链路

```text
PDF / document
  -> loader
  -> markdown or text representation
  -> chunk splitter
  -> optional chunk refinement
  -> optional metadata enrichment
  -> embedding provider
  -> vector store upsert
  -> trace / logs
```

README 强调该项目采用 Image-to-Text 思路处理图片：Vision LLM 生成图片描述，再把描述缝合进文本 chunk。这个做法的优势是复用纯文本 RAG 链路，不需要单独维护复杂的图像向量检索系统。

### 查询链路

```text
query
  -> query processor
  -> dense retrieval
  -> sparse retrieval / BM25
  -> RRF fusion
  -> optional reranker
  -> context assembly
  -> LLM response
  -> trace / logs
```

混合检索的直觉是把两类检索器的长处叠加：

- Dense retrieval 擅长语义相近但字面不一致的问题。
- Sparse retrieval / BM25 擅长专有名词、代码名、术语和精确关键词。
- RRF 用排序名次做融合，常见形式可写为：

$$
score(d) = \sum_{r \in R} \frac{1}{k + rank_r(d)}
$$

其中 \(R\) 是检索器集合，\(rank_r(d)\) 是文档 \(d\) 在检索器 \(r\) 中的名次，\(k\) 是平滑常数。

### MCP 工具链路

```text
MCP client
  -> MCP protocol handler
  -> registered tool
  -> RAG query / collection listing / document summary
  -> structured MCP response
```

这个设计把 RAG 服务从单独前端中解耦出来，使其可以被多种 AI 助手以 tool calling 形式调用。

## 关键依赖

`pyproject.toml` 中声明的主要依赖包括：

- `pyyaml`: 读取 YAML 配置。
- `langchain-text-splitters`: 文本切分。
- `chromadb`: 默认向量库。
- `mcp`: MCP 协议支持。
- `jieba`: 中文分词，适合 BM25 或中文文本处理。
- `markitdown[pdf]`: PDF/文档转 Markdown。
- `streamlit`: Dashboard。
- `ragas`: RAG 评估。
- `datasets`: 评估数据集支持。

开发依赖包括：

- `pytest`, `pytest-cov`, `pytest-asyncio`, `pytest-mock`
- `ruff`
- `mypy`
- `openai`

## 配置模型

`config/settings.yaml` 把外部依赖和检索策略集中成几个可替换模块：

- `llm`: `openai`、`azure`、`ollama`、`deepseek`
- `embedding`: `openai`、`azure`、`ollama`
- `vision_llm`: 图像描述模型配置
- `vector_store`: 默认 `chroma`，配置中也列出 `qdrant`、`pinecone`
- `retrieval`: `dense_top_k`、`sparse_top_k`、`fusion_top_k`、`rrf_k`
- `rerank`: `none`、`cross_encoder`、`llm`
- `evaluation`: `ragas`、`deepeval`、`custom`
- `observability`: log level、trace file、structured logging
- `ingestion`: chunk size、overlap、splitter、batch size、chunk refiner、metadata enricher

需要注意：配置样例中包含 `YOUR_API_KEY_HERE` 占位符，不是可用密钥。

## 推荐阅读路径

1. 先读 `README.md`，理解它既是 RAG 工程项目，也是面试和学习材料。
2. 再读 `config/settings.yaml`，把系统拆成 LLM、Embedding、VectorStore、Retrieval、Rerank、Evaluation、Observability、Ingestion 这些模块。
3. 读 `pyproject.toml`，确认项目是 Python 3.10+ 工程，依赖集中在 RAG、MCP、Streamlit、评估和测试工具。
4. 读 `src/ingestion/pipeline.py` 和 `src/ingestion/document_manager.py`，理解文档如何进入知识库。
5. 读 `src/core/query_engine/`，理解检索、融合、重排、查询处理如何组合。
6. 读 `src/mcp_server/tools/`，理解 RAG 能力如何被包装成 MCP tools。
7. 最后读 `DEV_SPEC.md`，反推项目的任务拆解、架构约束和 Skill 驱动开发方法。

## Setup / Run 方式

README 给出的主路径是：

```bash
git clone <repo-url>
cd Modular-RAG-MCP-Server
```

然后在 VS Code 中通过 Copilot 或 Claude 输入：

```text
setup
```

让项目内置的 Setup Skill 引导完成 provider 选择、API key 配置、依赖安装、配置文件生成和 Dashboard 启动。

从项目元数据看，也可以按 Python 项目常规方式理解：

```bash
python -m pip install -e ".[dev]"
python main.py
python scripts/ingest.py
python scripts/query.py
python scripts/evaluate.py
python scripts/start_dashboard.py
pytest
```

上述命令是基于仓库结构和 `pyproject.toml` 推断的常规入口，实际运行仍需根据 README、DEV_SPEC、配置文件和本地 API key 状态核对。

## 可沉淀的概念

- RAG
- MCP
- Hybrid Search
- Dense Retrieval
- Sparse Retrieval
- BM25
- RRF
- Reranker
- Cross-Encoder
- Image-to-Text Multimodal RAG
- Vector Store
- ChromaDB
- Ragas
- Golden Test Set
- Observability
- Trace
- Skill-driven Development
- DEV_SPEC-driven Development
- Provider Abstraction
- Factory Pattern
- Ingestion Pipeline

## 可复用的代码模式

- 通过 `settings.yaml` 统一配置 LLM、embedding、vector store、retrieval 和 evaluation。
- 用 provider/factory 抽象隔离 OpenAI、Azure、Ollama、DeepSeek 等服务差异。
- 用 loader/splitter/embedding/vector store 分层组织摄取链路。
- 用 dense + sparse + fusion + rerank 分层组织查询链路。
- 用 MCP tools 把后端能力暴露给 AI client，而不是为每个 client 写定制前端。
- 用 trace 和 structured logging 保存中间状态，便于定位 RAG 质量问题。
- 用 `scripts/` 提供摄取、查询、评估、Dashboard 等独立操作入口。
- 用 `tests/unit`、`tests/integration`、`tests/e2e` 分层组织测试。

## 局限与不确定性

- GitHub REST API 在采集时没有返回 license object，但 `pyproject.toml` 声明了 MIT；后续正式摄取时应把二者差异作为来源事实记录，而不是强行合并。
- README 将项目描述为完整工程，但 `main.py` 中仍有日志提示 `MCP Server will be implemented in Phase E.`；这可能是入口文件提示未同步，也可能说明部分实现状态需要通过运行测试或阅读 DEV_SPEC 进一步确认。
- README 明确说部分模块如 custom evaluator 和 cross-encoder reranker “框架已有，未测试”，因此不要把所有能力都视为生产可用。
- 该仓库定位偏学习、面试和工程方法示范，不应直接等同生产级 RAG 平台。
- 本采集件是 GitMD-compatible manual，不是 GitMD 官方导出的逐字结果。

## 后续摄取建议

后续从本 RAW 文件进入 `Wiki` 时，至少可生成或更新：

- `Wiki/sources/jerry-ai-dev-MODULAR-RAG-MCP-SERVER.md`
- `Wiki/projects/MODULAR-RAG-MCP-SERVER.md`
- `Wiki/entities/jerry-ai-dev.md`
- `Wiki/concepts/RAG.md`
- `Wiki/concepts/MCP.md`
- `Wiki/concepts/Hybrid Search.md`
- `Wiki/concepts/RRF.md`
- `Wiki/concepts/Ragas.md`
- `Wiki/methods/Skill-driven Development.md`
- `Wiki/methods/GitHub RAG project reading path.md`
