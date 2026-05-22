# Windows 平台智能知识助手项目准备

> 本文件由三版材料合并整理而成，统一组织为：项目技术知识库、面试题库、面试报告模板。
> 整理原则：尽量保留原有内容，仅按逻辑调整层级、目录和版面。

---

## 目录

- [第一部分：项目技术知识库](#第一部分项目技术知识库)
- [第二部分：面试题库](#第二部分面试题库)
- [第三部分：面试报告模板](#第三部分面试报告模板)

---

## 第一部分：项目技术知识库
> 本文件供面试官（AI Agent）使用，包含本项目的关键实现细节、高频面试题及参考答案。

> 面试过程中用于生成精准追问和评估候选人回答质量。

---

### 模块一：Hybrid Search 混合检索

#### 核心实现

- **双路并行召回**：Dense（向量语义）+ Sparse（BM25 关键词）同时执行

- **融合算法**：RRF（Reciprocal Rank Fusion）  

  公式：`Score = 1/(k + Rank_Dense) + 1/(k + Rank_Sparse)`，k 通常取 60

- **为什么用 RRF 而不是线性加权**：RRF 无需对不同路的分数值做归一化，对排名稳健，不依赖各路分数的绝对尺度

- **Dense Route**：计算 Query Embedding → Cosine Similarity → Top-N 语义候选

- **Sparse Route**：BM25 倒排索引 → Top-N 关键词候选

#### 高频面试题

**Q: 为什么要做 Hybrid Search？BM25 和向量检索各有什么优劣？**  

A: BM25（稀疏检索）擅长精确关键词匹配，对专有名词（如 API 名称、产品型号）效果好；Dense Embedding（稠密检索）擅长语义理解，处理同义词、模糊表达时优势明显。两者互补：BM25 查准率高但泛化差，Dense 泛化好但关键词精确度弱。Hybrid Search 结合两者，用 RRF 融合，平衡 Precision 和 Recall。


**Q: RRF 公式里 k=60 是怎么来的？**  

A: k 是平滑因子，防止排名靠前的文档分数过度高估。k=60 是学术论文（Cormack et al. 2009）中的经验推荐值，实践中通常无需调整。调大 k 会使分数分布更均匀（减弱头部文档优势），调小 k 会使分数差异更大。

  
**Q: 你们的 BM25 索引存在哪里？IDF 怎么算的？**  

A: BM25 索引元数据存储在 `data/db/bm25/` 目录下（当前用 pickle，可迁移至 SQLite）。IDF 基于语料库中文档频率计算：`IDF(t) = ln((N - df + 0.5) / (df + 0.5) + 1)`，N 是总文档数，df 是包含词 t 的文档数。

---

### 模块二：Reranker 精排

#### 核心实现
- **两段式架构**：粗排召回（低成本泛召回）→ 精排过滤（高成本精确排序）
- **支持三种后端**：
  1. `None`：直接返回 RRF Top-K
  2. `Cross-Encoder`：本地 Sentence-Transformers 模型，输入 `[Query, Chunk]` 对打分
  3. `LLM Rerank`：用 LLM 对候选集排序，输出 JSON ranked ids
- **Graceful Fallback**：精排失败/超时时自动回退到 RRF 排名，保证系统可用性

#### 高频面试题

**Q: Cross-Encoder 和 Bi-Encoder 的区别？为什么 Cross-Encoder 不能做粗排召回？**  

A: Bi-Encoder（如 Dense Embedding 模型）将 Query 和 Document **分别**编码为向量，再算相似度。可以预先离线计算 Document 向量，查询时只需对比一次，效率高，适合大规模召回。Cross-Encoder 将 Query 和 Document **拼接**后一起输入模型，能捕捉 Query-Document 的交互特征，精度更高，但必须对每对 (Query, Chunk) 实时推理，复杂度 O(n)，不适合大规模召回，只适合对小候选集（10-30 条）精排。


**Q: 精排阶段你们用的什么模型？用 CPU 跑 Cross-Encoder 会有延迟问题吗？**  

A: 支持 Sentence-Transformers 系列的 Cross-Encoder 模型（如 `cross-encoder/ms-marco-MiniLM-L-6-v2`）。CPU 环境下建议候选集 M ≤ 30，设置超时回退，超时后直接用 RRF 结果

---

### 模块三：Ingestion Pipeline 数据摄取流水线

#### 五阶段流程

```

Load → Split → Transform → Embed → Upsert

```
1. **Load**：MarkItDown 将 PDF 转为 canonical Markdown；抽取 metadata（`source_path`, `doc_type`, `title`, `images` 等）；**前置 SHA256 哈希去重**（已处理过的文件直接跳过）
2. **Split**：LangChain `RecursiveCharacterTextSplitter`，按 Markdown 结构（标题/段落/代码块）语义切分，产出带 `chunk_index`/`start_offset` 的 Chunk
3. **Transform**（三个 LLM 增强步骤）：
   - **ChunkRefiner**：LLM 合并逻辑相关但被物理切断的段落，去噪（页眉页脚/乱码）
   - **MetadataEnricher**：LLM 为每个 Chunk 生成 `Title`/`Summary`/`Tags`，注入 metadata
   - **ImageCaptioner**：Vision LLM（GPT-4o）为图片生成文字描述，缝合进 Chunk 正文
4. **Embed**：双路向量化（Dense embedding + BM25 sparse），按内容哈希差量计算（未变更的 Chunk 不重复调用 API）
5. **Upsert**：写入 Chroma 向量库 + BM25 索引，幂等设计

  

#### 幂等性设计
- **chunk_id 生成**：`hash(source_path + section_path + content_hash)` → 确定性哈希，相同内容永远相同 ID

- **为什么不用 UUID**：UUID 随机，重复摄取同一文件会产生重复 chunk；确定哈希保证幂等 Upsert

- **文件级去重**：SHA256 文件哈希 → 查 `ingestion_history.db`，已成功处理直接跳过

  

#### 高频面试题

**Q: ChunkRefiner 做了什么？为什么需要 LLM 来做 Chunking 优化？**  

A: RecursiveCharacterTextSplitter 是按字符边界做物理切分，可能把语义上连续的段落切断（如"问题描述"和"解决方案"分属两个 Chunk）。ChunkRefiner 让 LLM 识别这种情况并合并，同时去除页眉页脚乱码，确保每个 Chunk 是 Self-contained 的语义单元，提高检索精度。

  

**Q: MetadataEnricher 产出的 Title/Summary/Tags 存在哪里？对检索有什么用？**  

A: 存入 Chunk 的 `metadata` 字段（Chroma 的 document metadata）。检索时可以基于这些字段做 metadata filtering（如按 Tags 过滤），也可以将 Summary 拼入检索文本，提升召回率。Title 还会展示在 Dashboard 数据浏览器中。

  

**Q: 图片检索是怎么实现的？用户怎么通过文字找到图片？**  

A: Caption 文本被"缝合"进 Chunk 正文（作为 text 的一部分），参与 Embedding。用户查询时，Caption 文本会被向量检索命中。检索命中后，系统从 `image_index.db`（`image_id → 文件路径`映射）读取原始图片文件，编码为 Base64，通过 MCP 返回 `ImageContent` 给 Client，实现"搜文出图"。

---

### 模块四：可插拔架构

#### 核心设计

- 6 大组件均有抽象 Base 类：`BaseLoader` / `BaseSplitter` / `BaseTransform` / `BaseEmbedding` / `BaseVectorStore` / `BaseReranker`

- **工厂模式**：各组件通过 Factory 函数根据 YAML 配置实例化，调用方不直接 new 具体实现类

- **配置驱动**：修改 `config/settings.yaml` 即可切换后端，零代码修改


#### 新增 Provider 流程（面试经典追问）

1. 新建 `src/libs/{component}/your_provider.py`，继承对应 Base 类，实现接口方法

2. 在对应 Factory 函数中注册新 provider 名称和类映射

3. 在 `config/settings.yaml` 中配置 `provider: your_provider`

4. 只需增量修改，不需要改已有代码

#### 当前支持

- LLM：Azure OpenAI / OpenAI / Ollama / DeepSeek

- Embedding：OpenAI / Azure / Ollama

- Vector Store：Chroma（接口预留 Qdrant/Pinecone 替换）

- Reranker：Cross-Encoder / LLM Rerank / None

---

### 模块五：MCP 协议集成

#### 核心规范

- **协议**：MCP（Model Context Protocol），基于 JSON-RPC 2.0

- **传输层**：Stdio Transport（Client 以子进程方式启动 Server，双方通过 stdin/stdout 通信）

- **为什么用 Stdio**：零网络依赖，无需端口/鉴权，天然适合私有知识库；stdout 只输出合法 MCP 消息，日志走 stderr

#### 暴露的 Tools

| 工具名 | 功能 | 关键参数 |

|--------|------|---------|

| `query_knowledge_hub` | 主检索入口，Hybrid Search + Rerank | `query`, `top_k?`, `collection?` |

| `list_collections` | 列举可用文档集合 | 无 |

| `get_document_summary` | 获取文档摘要与元信息 | `doc_id` |

  

#### Citation 设计

每个检索结果携带结构化引用：来源文件名、页码、chunk 内容摘要，方便 Client 展示"回答依据"，增强用户对 AI 输出的信任。

  

#### 高频面试题

**Q: MCP 和普通 REST API 有什么区别？**  

A: MCP 是专为 AI Agent 设计的上下文协议，定义了标准的 `tools`/`resources`/`prompts` 接口，任何合规的 MCP Client（Copilot、Claude Desktop 等）都能即插即用，无需定制集成。REST API 需要客户端专门适配，MCP 通过协议标准化消除了这一成本。

  

**Q: Stdio Transport 有什么局限性？什么情况下需要换 HTTP Transport？**  

A: Stdio 适合本地单进程场景。局限：不支持远程调用（Client 和 Server 必须在同一机器），不支持多 Client 并发连接。如需远程访问、多用户并发或负载均衡，需切换到 HTTP+SSE Transport。

---

### 模块六：文档生命周期管理（DocumentManager）

#### 核心功能

- `list_documents(collection?)`：列出已摄入文档（含 chunk 数、图片数、摄入时间）

- `get_document_detail(doc_id)`：查看单文档所有 Chunks + metadata + 关联图片

- `delete_document(source_path, collection)`：**协调删除四路存储**：

  1. Chroma：按 `metadata.source` 删除所有 chunk 向量

  2. BM25 Indexer：移除倒排索引条目

  3. ImageStorage：删除关联图片文件

  4. FileIntegrity（`ingestion_history.db`）：移除处理记录，使文件可重新摄入

#### 高频面试题

**Q: 为什么删除文档需要同步操作四个存储？如果其中一个删除失败怎么办？**  

A: 四个存储各自独立维护索引，如果只删 Chroma 但没删 BM25 索引，下次 Hybrid Search 会从 BM25 召回已不存在于 Chroma 的 chunk，造成不一致。FileIntegrity 如果不删，重新摄取同一文件会被认为已处理而跳过。当前实现采用尽力删除策略，各存储独立尝试删除，失败时记录错误但不阻塞其他存储的删除。生产级改进可引入事务记录或两阶段提交。

---

### 模块七：可观测性与追踪系统

#### Trace 体系

- **双链路**：Ingestion Trace（Load→Split→Transform→Embed→Upsert 5阶段）+ Query Trace（QueryProcess→DenseRecall→SparseRecall→Fusion→Rerank 5阶段）

- **存储**：JSON Lines 结构化日志，零外部依赖（无需 LangSmith/LangFuse）

- **TraceContext**：显式调用模式，低侵入，记录各阶段耗时、候选数量、分数分布

#### Dashboard 6个页面

1. **系统总览**：当前组件配置 + Collection 统计

2. **数据浏览器**：文档/Chunk/图片详情查看

3. **Ingestion 管理**：文件上传、实时进度、文档删除

4. **Ingestion 追踪**：阶段耗时瀑布图

5. **Query 追踪**：Dense/Sparse 召回对比、Rerank 前后排名变化

6. **评估面板**：Ragas 指标、历史趋势

#### 动态渲染设计

Dashboard 基于 Trace 中的 `method`/`provider` 字段**动态渲染**，更换可插拔组件后 Dashboard 自动适配，无需修改代码。

  

---

### 模块八：评估体系

#### 指标体系

- **Hit Rate@K**：Top-K 结果中至少有一条命中 Golden Answer 的比例

- **MRR（Mean Reciprocal Rank）**：第一条命中结果的排名倒数均值，衡量头部排序质量

- **Ragas 指标集**：Faithfulness（回答是否基于检索内容）、Answer Relevancy（回答与问题相关性）、Context Precision（检索结果精准度）

- **可插拔**：CompositeEvaluator 支持多评估器并行执行，Ragas / 自定义指标均可挂载

#### Golden Test Set

存于 `tests/fixtures/golden_test_set.json`，EvalRunner 基于此进行回归评估，确保每次策略调整（改 Chunk Size / 换 Reranker）都有量化分数对比。

---

### 模块九：工程化实践

#### 测试体系

- **分层金字塔**：Unit（单元）→ Integration（集成）→ E2E（端到端）

- **单元测试 mock 策略**：用 `unittest.mock.patch` mock LLM 客户端，返回预设响应，避免实际 API 调用；测试关注业务逻辑而非外部依赖

- **测试覆盖**：1198+ 单元测试 + 30 E2E 全绿

- **E2E 测试**：`tests/e2e/test_mcp_client.py` 启动真实 MCP Server 子进程，发送 JSON-RPC 消息端到端验证


#### 持久化存储架构

| 存储 | 文件 | 用途 |

|------|------|------|

| Chroma | `data/db/chroma/` | Dense 向量 + metadata |

| BM25 | `data/db/bm25/` | 稀疏倒排索引 |

| ingestion_history.db | `data/db/` | 文件处理记录（SHA256） |

| image_index.db | `data/db/` | image_id → 文件路径映射 |

**设计原则**：Local-First，零外部数据库依赖，`pip install` 即可运行。

---

### 常见"露馅"警示点


面试中如候选人无法解释以下细节，需在报告中标记：

| 简历描述 | 深挖问题 | 露馅信号 |

|---------|---------|---------|

| "混合检索命中率提升 XX%" | 怎么测的？用什么指标？ | 说不清 Hit Rate@K 定义或无测试数据 |

| "RRF 融合算法" | 公式是什么？k 值怎么设的？ | 无法说出公式，或说成线性加权 |

| "设计可插拔架构" | 新增 Provider 要改哪些文件？ | 不知道抽象接口在哪定义 |

| "幂等 Upsert" | chunk_id 怎么生成的？ | 说是 UUID，或说不清楚 |

| "MCP 协议实现" | Stdio Transport 是怎么工作的？ | 不知道 stdout/stderr 分工 |

| "TDD 开发，1200+ 测试" | 单元测试怎么 mock LLM？ | 不知道 mock 策略 |

| "多模态检索" | Caption 文本怎么参与检索？ | 说不清与正文的关系 |

| "跨存储协调删除" | 删一个文档要操作几个存储？ | 只说 Chroma 或说不知道 |


## 第二部分：面试题库
> 本文件供面试官（AI Agent）在面试时随机选题使用。

> SKILL.md 中指定的随机规则（基于 `[DICE]` 掷骰）从本文件各题池中抽取当场问题。

> **每次面试不得连续使用同一道题作为开场，严禁每场都从编号最小的题开始。**

---

  

### 方向 1 题库：项目综述

  

#### 【开场题池】（共 12 道）

  

选取规则：`[DICE] × 2 - 1` 对应的题（骰子 1→1, 2→3, 3→5, 4→7, 5→9, 6→11）

  

1. 介绍一下这个项目整体解决什么问题，架构分哪几层？

2. 从用户发起一次查询，到拿到结果，整个链路经过哪些组件？

3. 这个系统里 MCP 协议起什么作用？为什么不直接暴露 REST API？

4. 如果让你给一个没接触过 RAG 的同学介绍这个项目，你会怎么说？

5. 这个项目里你认为最复杂的模块是哪个？为什么？

6. 和传统文档检索系统相比，这个系统的核心差异点是什么？

7. 这个系统里有哪几类存储？它们各自负责什么？为什么不能只用一个？

8. 如果项目中某个 LLM Provider 挂了，系统会怎么表现？有降级机制吗？

9. 这个项目的测试覆盖率是怎么保证的？测试分几层？

10. 从工程化角度，这个项目里最体现软件设计原则的地方是哪里？

11. 如果要把这个系统部署给多个团队使用（多租户），现有架构需要做什么改动？

12. 这套系统在什么情况下检索效果最差？你们做过什么来缓解这种情况？

  

#### 【追问候选池】（共 10 道）

  

选取规则：仅作为即兴追问的灵感来源，不直接选取——追问必须基于候选人实际回答重新构造

  

1. Ingestion 链路的 5 个阶段分别做了什么？哪个阶段最耗时？

2. Hybrid Search 的两路是怎么融合的？为什么用 RRF 而不是直接加权平均？

3. MCP 的 Stdio Transport 是什么？为什么选这种传输方式？

4. 项目里的幂等性设计体现在哪里？具体怎么实现的？

5. 可插拔架构是怎么实现的？举一个你新增 Provider 的例子。

6. 系统里用了哪些存储？（Chroma / BM25 / SQLite）各自存什么，数据流是怎么打通的？

7. 评估体系里 Hit Rate@K 和 MRR 各衡量什么？你一般关注哪个更多？

8. Trace 是怎么工作的？Ingestion 的 5 阶段各记录了哪些数据？

9. 图片是怎么进入检索链路的？命中图片时用户侧会看到什么？

10. 这个系统里有没有什么"过度设计"或可以简化的地方？现在回头看你会怎么改？

  

---

  

### 方向 2 题库：简历深挖（包装识别）

  

#### 【P1 — 量化指标追问池】（简历有数字时必进，共 6 道）

  

选取规则：由 `[DICE]` 直接选取（超出长度则循环）

  

1. 你提到检索准确率提升了 X%，这个是怎么测量的？测试集有多少条？是人工标注的还是自动生成的？

2. X ms 的延迟是在什么硬件环境下测的？并发量是多少？P50 还是 P99？

3. 这个数字是在什么 baseline 下对比的？对比方案是什么？变量控制了吗？

4. 这个指标是在生产环境还是测试环境测的？两者一般会有多大差异？

5. 你提到的 X 条文档 / X 个 chunk，处理这些内容大概花了多少时间？每条文档平均多少 chunk？

6. 如果我现在跑你们的测试集，能复现这个数字吗？测试代码在哪？

  

#### 【P2 — 强动词追问池】（简历有"主导/设计/独立完成"时，共 8 道）

  

选取规则：由 `[DICE]` 直接选取（超出长度则循环）

  

1. 你说你主导了 Ingestion Pipeline 的设计，当时有哪些方案备选，为什么选现在这个？

2. 你独立完成了 Hybrid Search，有没有遇到什么难点？是怎么解决的？

3. 你说你设计了文档管理模块，那删除一个文档时需要操作几个存储？为什么不能只删 Chroma？

4. 当时 ChunkRefiner 的 Prompt 是你写的吗？怎么迭代调优的？最大挑战是什么？

5. 你说你设计了可插拔架构，那新增一个 Embedding Provider 具体需要改哪些文件？

6. 你说你做了评估体系，Golden Test Set 是怎么建立的？人工标注了多少条？

7. 你说你实现了 MCP 集成，Citation 结构是你设计的吗？里面有哪些字段？为什么这样设计？

8. 你说你做了 Dashboard，Trace 数据是怎么存储的？为什么不用 LangSmith 这类现成工具？

  

#### 【P3 — 技术词汇追问池】（简历有技术关键词时，共 10 道）

  

选取规则：由 `[DICE]` 直接选取（超出长度则循环）

  

1. 你提到 RRF，k=60 这个参数是怎么来的？你有调过吗？调大调小各有什么效果？

2. 你说用了 Cross-Encoder 精排，它和 Bi-Encoder 的本质区别是什么？项目里用的是哪个具体模型？

3. chunk_id 是怎么生成的？为什么不用 UUID？如果同一文档内容改了一行，chunk_id 会变吗？

4. Chroma 里 DocumentManager 删文档时要做哪些事？只删 Chroma 会造成什么问题？

5. 你提到 Vision LLM 做 Image Caption，Caption 是怎么进检索链路的？用的是什么模型？

6. 你提到差量 Embed，具体是怎么判断一个 chunk 是否需要重新 Embed 的？

7. 你的测试里怎么 mock LLM 调用？patch 的是哪一层？

8. BM25 的 b 参数和 k1 参数分别控制什么？你们有调过这两个参数吗？

9. MetadataEnricher 产出的 Tags 在检索时是怎么用的？能做 filtering 吗？

10. Ragas 的 Faithfulness 指标具体是怎么算的？它衡量的是什么能力？

  

#### 【无简历题库】（无简历时随机选 2-3 道，共 8 道）

  

选取规则：由 `[DICE]` 直接选取（超出长度则循环）

  

1. 如果有人在简历上写"主导设计了 Hybrid Search 提升命中率 30%"，你觉得面试时应该怎么验证他是否真正懂？

2. Ingestion Pipeline 里哪个阶段最容易出 bug？为什么？你遇到过什么问题？

3. 如果要给这个项目的某一个模块写简历项目经历，你会选哪个？会怎么写量化指标？

4. 这个系统里有什么设计你觉得可以改进的？如果你重新做会怎么架构？

5. 如果 Reranker 服务挂了，系统会有什么降级策略？用户能感知到吗？

6. 你觉得这套系统最大的技术风险是什么？如何缓解？

7. 如果产品要求支持中英文混合查询，现有架构需要做什么改动？

8. chunk_size 和 chunk_overlap 这两个参数你会怎么调？调的依据是什么？

  

---


### 方向 3 题库：技术深挖（共 55 道）

  

> **选取规则：**

> 1. 若有简历，根据简历关键词匹配对应主题组，汇总所有候选题

> 2. 无简历则使用全部 55 道题作为候选池

> 3. 按 `[DICE]` 选主题组（1→A, 2→B, 3→C, 4→D, 5→E, 6→F），再从该组中选第 `[DICE]` 道题

> 4. 严禁与同会话上场面试重复超过 1 题

  

#### 【A — 检索架构】关键词：Hybrid Search / RRF / BM25 / 向量检索 / 混合检索


A1. RRF 公式是什么？k 值怎么选？为什么不用线性加权？

A2. BM25 相比 TF-IDF 改进了什么？BM25 里的 b 参数和 k1 参数各控制什么？

A3. IDF 里的文档频率存在哪里？重新摄取文档时怎么更新 BM25 索引？

A4. 向量检索用的是 Cosine Similarity，为什么不用欧式距离？它们在归一化向量上有什么区别？

A5. 如果用户查询全是专有名词（如产品代号），纯向量检索会有什么问题？你们怎么解决的？

A6. Top-K 的 K 怎么定？召回太少和召回太多分别会有什么影响？

A7. Hybrid Search 里 Dense 和 Sparse 两路的召回数量一样吗？如果不一样，RRF 还有效吗？

A8. 如果两路检索结果完全不重叠，RRF 融合后会是什么结果？这是好事还是坏事？

A9. 向量检索的相似度阈值你们设了吗？设阈值有什么风险？

A10. BM25 对中文分词有什么依赖？不做分词处理会有什么问题？

  

#### 【B — 精排 Reranker】关键词：Rerank / Cross-Encoder / 精排 / 二阶段检索

  

B1. Cross-Encoder 和 Bi-Encoder 的区别？为什么 Cross-Encoder 不能做粗排召回？

B2. 精排候选集多大合适？K 开太大会有什么问题？

B3. LLM Rerank 相比 Cross-Encoder 有什么优劣？什么场景下你会选 LLM Rerank？

B4. 精排失败时系统怎么降级？Graceful Fallback 是在哪里实现的，用的什么机制？

B5. Cross-Encoder 推理时输入是什么格式？Query 和 Chunk 是怎么拼接的？

B6. 如果 Reranker 模型在语言上有偏差（如英文模型处理中文），会有什么表现？如何解决？

B7. 精排后分数低于某个阈值的 chunk 会被过滤掉吗？有没有这个机制？

B8. 你们使用的具体是哪个 Cross-Encoder 模型？选它的理由是什么？

  

#### 【C — 数据摄取 Ingestion】关键词：Ingestion / Pipeline / ChunkRefiner / Metadata / 摄取流水线

  

C1. ChunkRefiner 做了什么？为什么不直接调 Splitter 参数而要用 LLM？

C2. MetadataEnricher 产出的 Title/Summary/Tags 存在哪里？检索时有用到吗？怎么用的？

C3. SHA256 文件去重和 chunk_id 哈希去重各自防的是什么场景？为什么要双重保险？

C4. Embed 阶段的"差量计算"是怎么做的？未变更 chunk 怎么识别并跳过 API 调用？

C5. 图片 Caption 是怎么进检索链路的？用户命中图片 chunk 后，图片怎么返回给用户？

C6. PDF 解析用的什么库？MarkItDown 转换的结果格式是什么？有没有遇到过图表或复杂排版的问题？

C7. RecursiveCharacterTextSplitter 是按什么规则切分的？chunk_overlap 的作用是什么？

C8. Transform 阶段的三个步骤（ChunkRefiner / MetadataEnricher / ImageCaptioner）是并行执行还是串行？为什么？

C9. 如果 LLM 增强步骤失败了（如 ChunkRefiner 调用超时），整个摄取任务会怎么处理？

C10. 如果发现源文件更新了，怎么做增量更新？直接重跑现有逻辑会有什么问题？

C11. chunk_index 和 start_offset 这两个字段是用来做什么的？检索时用到了吗？

C12. ImageCaptioner 用的是什么 Vision 模型？如果图片是表格或代码截图，Caption 效果怎么样？

  

#### 【D — 架构 & MCP 协议】关键词：可插拔 / 工厂模式 / MCP / 插件架构

  

D1. 可插拔架构怎么实现的？新增一个 Embedding Provider 需要改哪些文件？

D2. `query_knowledge_hub` 这个 MCP tool 的输入输出格式是什么？Citation 结构包含哪些字段？

D3. MCP 用的是什么传输协议？Stdio Transport 和 HTTP Transport 有什么区别？

D4. 如果要横向扩展这个系统支持多租户，你觉得哪里需要改动？最难的点是什么？

D5. 工厂模式里，注册新 Provider 的映射关系存在哪里？是硬编码还是动态注册？

D6. MCP 的 `list_collections` 和 `get_document_summary` 这两个工具各自什么场景下被 Client 调用？

D7. 如果 MCP Client 传来一个不存在的 collection 名，系统怎么处理？有没有参数校验？

D8. Base 抽象类里定义了哪些必须实现的接口方法？有没有带默认实现的方法？

D9. 配置文件 `settings.yaml` 是在哪里被加载的？是单例模式还是每次请求都重新读？

D10. MCP Server 是以什么方式启动的？Client 怎么知道如何连接到它？

  

#### 【E — 存储 & 幂等性】关键词：Chroma / BM25 / chunk_id / 幂等 / SHA256 / 存储

  

E1. chunk_id 是怎么生成的？为什么不用 UUID？如果文件改了一行，受影响的 chunk_id 会变吗？

E2. 删除文档时需要操作几个存储？只删 Chroma 会有什么问题？为什么这几个存储不能合并？

E3. BM25 索引存在哪里？当前的存储方式（pickle）有什么局限？生产环境下可以怎么改进？

E4. `ingestion_history.db` 里存的是什么？它和 Chroma 里的 chunk 记录有什么区别？

E5. Chroma 的 collection 是什么概念？多 collection 时 Hybrid Search 是跨 collection 还是指定 collection？

E6. 如果两个文件内容完全一样（只是文件名不同），chunk_id 会相同吗？会有冲突吗？

E7. `image_index.db` 存的是什么？为什么不直接在 Chroma metadata 里存图片路径就够了？

E8. Chroma 的持久化是怎么实现的？换一台机器时数据怎么迁移？

  

#### 【F — 测试 & 可观测性】关键词：TDD / 测试 / 评估 / Dashboard / Trace / Ragas

  

F1. 测试分几层？Unit / Integration / E2E 各测什么、分别不测什么？

F2. 单元测试怎么 mock LLM 调用？patch 的是哪一层？不 mock 的话有什么问题？

F3. Hit Rate@K 和 MRR 怎么计算？分别能反映检索系统的什么能力？哪个更难提升？

F4. Ragas Faithfulness 和 Answer Relevancy 分别衡量什么？要提升 Faithfulness 应该调哪里？

F5. Trace 是怎么实现的？Ingestion 的 5 个阶段 Trace 各记录了哪些数据？

F6. Dashboard 里的 Query Trace 能看到什么信息？Dense/Sparse 召回结果是怎么对比展示的？

F7. Golden Test Set 是怎么建立的？有多少条？是手工标注还是自动生成的？

F8. E2E 测试是怎么跑的？它启动了真实的 MCP Server 吗？如何保证测试环境的稳定性？

F9. Context Precision 指标和 Hit Rate@K 的区别是什么？

F10. 如果一次策略变更（比如换了 Reranker 模型）导致评估分数下降，你们的处理流程是什么？

  

#### 【G — 系统设计 & 扩展性（通用题，无简历时重点使用）】

  
G1. 从系统设计角度，RAG 和 Fine-tuning 的核心权衡是什么？什么场景应该选 RAG？

G2. 这个系统的性能瓶颈在哪里？如果要优化 P99 延迟，你会从哪里下手？

G3. 如果要支持实时增量摄取（文档修改后立即生效），现有架构需要改什么？

G4. Chroma 和 Elasticsearch 作为向量存储有什么区别？你会在什么规模下考虑换掉 Chroma？

G5. 如果用户的查询是一段很长的文字（超过 512 tokens），Embedding 模型会怎么处理？有没有截断风险？

G6. 这套系统目前不支持什么功能？如果要支持「对话式多轮 RAG」，需要改哪些地方？

G7. 如果要把 BM25 换成 Elasticsearch 做稀疏检索，改动量有多大？可插拔架构是否覆盖了这个场景？


## 第三部分：面试报告模板

  

> 本文件在 Phase 3 报告生成时读取。包含：①完整报告 Markdown 模板 ②12 道题预置参考答案 ③评分细则。

  

---



### 一、报告 Markdown 模板

  

生成规则：

- 表格"参考答案"列使用 `[→ 查看](#a-锚点关键词)` 锚链接，指向本文件第二节对应答案

- 只为**本次实际问到的题目**复制对应答案块，未问到的不放入报告

- 严格按评分细则打分，不得因情绪照顾调分

  

```markdown

# 模拟面试报告

  

**项目**：Modular RAG MCP Server

**面试时间**：{datetime}

**评分**：{score}/10

  

---

  

## 一、面试记录

  

> ✅ 答对核心要点 | ⚠️ 方向正确但细节缺失 | ❌ 未能答出或方向错误

  

### 方向 1：项目综述

  

| 轮次 | 问题 | 候选人回答摘要 | 评估 | 参考答案 |

|-----|------|-------------|------|---------|

| 1 | {问题原文} | {2-3 句摘要} | ✅/⚠️/❌ | [→ 查看](#a-{锚点}) |

| 2 | ... | ... | ... | [→ 查看](#a-{锚点}) |

| 3 | ... | ... | ... | [→ 查看](#a-{锚点}) |

  

### 方向 2：简历深挖

  

| 轮次 | 问题 | 候选人回答摘要 | 评估 | 露馅 | 参考答案 |

|-----|------|-------------|------|-----|---------|

| 1 | {问题原文} | {摘要} | ✅/⚠️/❌ | 是/否 | [→ 查看](#a-{锚点}) |

| 2 | ... | ... | ... | ... | [→ 查看](#a-{锚点}) |

| 3 | ... | ... | ... | ... | [→ 查看](#a-{锚点}) |

  

### 方向 3：技术深挖

  

| 轮次 | 问题 | 候选人回答摘要 | 评估 | 参考答案 |

|-----|------|-------------|------|---------|

| 1 | {问题原文} | {摘要} | ✅/⚠️/❌ | [→ 查看](#a-{锚点}) |

| 2 | ... | ... | ... | [→ 查看](#a-{锚点}) |

| 3 | ... | ... | ... | [→ 查看](#a-{锚点}) |

  

---

  

## 二、参考答案

  

> 仅复制本次实际问到的题目对应答案块，保留 <a id> 锚点。

  

{从下方"预置参考答案库"按需复制}

  

---

  

## 三、简历包装点评

  

### 包装合理 ✅

- **"{简历描述}"**：{说明候选人能自圆其说之处，具体指出哪句回答支撑了该判断}

  

### 露馅点 ❌

- **"{简历描述}"** → {面试中的具体表现}。**严重性：高/中/低**（{说明原因}）

  

### 改进建议

- {针对每个露馅点的具体、可操作建议，如"建议背下 RRF 公式并能解释 k 参数含义"}

  

---

  

## 四、综合评价

  

**优势**：

- {具体到哪道题答得好、好在哪个关键点}

  

**薄弱点**：

- {具体技术点 + 答错/答浅的表现描述}

  

**面试官建议**：

{针对每个薄弱点的具体改进方向，避免笼统表述}

  

---

  

## 五、评分

  

| 维度 | 分数（满分 10）| 评分依据（必须说明具体扣分原因） |

|-----|--------------|--------------------------------|

| 项目架构掌握 | x | {哪些点答到了，哪些点缺失} |

| 简历真实性 | x | {几处包装合理，几处露馅，差距} |

| 算法理论深度 | x | {RRF/Cross-Encoder/评估指标等作答情况} |

| 实现细节掌握 | x | {chunk_id/可插拔三步骤/MCP Tool 参数等} |

| 表达清晰度 | x | {回答完整性、逻辑清晰度、因果说明} |

| **综合** | **x** | {加权说明} |

```

  

---
  

### 二、预置参考答案库

  

> 按需复制到报告"二、参考答案"节，保留 `<a id>` 锚点不变。

  

---

  

#### <a id="a-项目架构"></a>Q: 介绍项目整体架构和你具体负责的部分

  
**参考答案**：

系统分三大层次：

1. **Ingestion 层**：5 阶段流水线（Load → Split → Transform → Embed → Upsert），文档解析、分块、LLM 增强、向量化后写入存储

2. **检索层**：Hybrid Search（BM25 + Dense Embedding 并行召回）→ RRF 融合 → Cross-Encoder 精排

3. **服务层**：MCP Server 封装，Stdio Transport 对外暴露 3 个 Tool，AI Client 可直接调用

  

核心亮点：全链路可插拔（6 大组件均有 Base 抽象类 + Factory 模式），配置文件驱动零代码切换后端。

  

---

  

#### <a id="a-ingestion链路"></a>Q: Ingestion 链路有哪些阶段？

  

**参考答案**：

共 5 个阶段：

1. **Load**：MarkItDown 将 PDF 转为 Markdown，前置 SHA256 文件哈希去重（已处理文件直接跳过）

2. **Split**：LangChain `RecursiveCharacterTextSplitter` 按 Markdown 结构语义切分，产出带 `chunk_index`/`start_offset` 的 Chunk

3. **Transform**（3 个 LLM 增强步骤）：ChunkRefiner（合并语义断裂段落、去噪）→ MetadataEnricher（生成 Title/Summary/Tags）→ ImageCaptioner（Vision LLM 生成图片描述，缝合进 Chunk 正文）

4. **Embed**：BM25 + Dense Embedding 双路向量化，按内容哈希差量计算（未变更 Chunk 不重复调 API）

5. **Upsert**：幂等写入 Chroma 向量库 + BM25 倒排索引

  

---

  

#### <a id="a-mcp协议"></a>Q: MCP 是什么规范？暴露了哪些 Tool？

  

**参考答案**：

MCP（Model Context Protocol）是 Anthropic 提出的开放协议，基于 JSON-RPC 2.0，定义 AI Client 与外部工具/数据源之间的标准通信接口。任何合规 Client（Copilot、Claude Desktop）即插即用。

  

本项目采用 **Stdio Transport**：Client 以子进程启动 Server，stdin/stdout 通信，日志走 stderr，零网络依赖。

  

对外暴露 3 个 Tool：

  

| Tool | 功能 | 关键参数 |

|------|------|---------|

| `query_knowledge_hub` | 主检索入口（Hybrid Search + Rerank） | `query`, `top_k?`, `collection?` |

| `list_collections` | 列举可用文档集合 | 无 |

| `get_document_summary` | 获取文档摘要与元信息 | `doc_id` |

  

每条检索结果携带结构化 Citation（来源文件名、页码、chunk 摘要），可选返回 Base64 图片。

  

---

  

#### <a id="a-rrf公式"></a>Q: RRF 融合公式是什么？k 值含义？为什么不用线性加权？

  

**参考答案**：

  

$$Score_{RRF}(d) = \frac{1}{k + Rank_{Dense}(d)} + \frac{1}{k + Rank_{Sparse}(d)}$$

  

- **k 的含义**：平滑因子，防止排名头部文档分数被过度高估。k = 60 是 Cormack et al. 2009 论文的经验推荐值；调大 k → 分布更均匀，调小 k → 差异更大。

- **为什么不用线性加权**：BM25 分数无上界，余弦相似度在 [-1,1]，两路量纲不同，线性加权必须先归一化且引入额外超参。RRF 只依赖排名（序数信息），天然无需归一化，鲁棒性更强。

  

---

  

#### <a id="a-cross-encoder"></a>Q: Cross-Encoder 和 Bi-Encoder 的区别？为什么不能做粗排召回？

  

**参考答案**：

  

| | Bi-Encoder | Cross-Encoder |

|--|-----------|--------------|

| 编码方式 | Query 和 Document **分别**编码为向量，算相似度 | Query 和 Document **拼接**一起输入模型，联合建模 |

| Document 向量 | 可**离线预计算**，查询时 O(1) | 每对 (Query, Chunk) 必须**实时推理**，O(n) |

| 精度 | 较低（无交互） | 更高（充分建模交互特征） |

| 适合场景 | 粗排召回（大规模） | 精排（10-30 条小候选集） |

  

**Cross-Encoder 不能做粗排**：5000+ 文档场景每次查询需推理 5000 次，延迟不可接受、成本极高。必须先用 Bi-Encoder 粗召回 Top-N，再用 Cross-Encoder 精排。

  

---

  

#### <a id="a-chunkrefiner"></a>Q: ChunkRefiner 做了什么？为什么需要额外的 LLM 步骤？

  

**参考答案**：

`RecursiveCharacterTextSplitter` 按字符边界物理切分，会将语义连续的段落切断（如"问题背景"和"解决方案"分入不同 Chunk），导致检索命中的 Chunk 缺乏上下文。

  

ChunkRefiner 的工作：

1. **合并语义断裂的段落**：LLM 判断相邻 Chunk 是否逻辑连续，若是则合并

2. **去噪清理**：移除 PDF 转换产生的页眉页脚乱码、重复标题

  

使每个 Chunk 成为 **Self-contained 的语义单元**，提升检索精度和 LLM 生成质量。

  

---

  

#### <a id="a-hit-rate"></a>Q: Hit Rate@K 是怎么计算的？

  

**参考答案**：

  

$$HitRate@K = \frac{\text{Top-K 结果中至少命中一条 Golden Answer 的查询数}}{\text{总查询数}}$$

  

对 Golden Test Set 中每条 `(query, expected_chunks)`，取 Top-K 检索结果，至少一条匹配则 hit=1，否则 hit=0。Hit Rate@K = 命中次数 / 总 case 数。

  

**@K 含义**：只要正确文档出现在 Top-K 内即算命中，不要求排第一。@10 = 正确文档在 Top-10 内即可。

  

---

  

#### <a id="a-可插拔架构"></a>Q: 新增一个 Embedding Provider 需要改哪些文件？

  

**参考答案**：

只需改 **3 处**，已有代码零修改（开闭原则）：

  

1. **新建** `src/libs/embedding/your_provider.py`：继承 `BaseEmbedding`，实现 `embed_texts()` 等接口方法

2. **修改** `src/libs/embedding/factory.py`：在 `provider_map` 中注册 `"your_provider": YourProviderClass`

3. **修改** `config/settings.yaml`：将 `embedding.provider` 改为 `"your_provider"`

  

其他组件（LLM / Reranker / VectorStore / Loader / Splitter）遵循同一套三步流程。

  

---

  

#### <a id="a-幂等性"></a>Q: chunk_id 是怎么生成的？为什么不用 UUID？

  

**参考答案**：

`chunk_id = hash(source_path + section_path + content_hash)`

  

确定性哈希（SHA256 截断），相同来源+位置+内容的 Chunk 永远生成相同 ID。

  

**为什么不用 UUID**：UUID 随机，重复摄取同一文件会产生新 ID，导致向量库出现重复 Chunk。确定性哈希保证**幂等 Upsert**：相同内容多次写入只有一条，内容变更时 ID 变化自然触发更新。

  

文件级去重：前置 SHA256 文件哈希查 `ingestion_history.db`，已处理文件直接跳过。

  

---

  

#### <a id="a-多模态检索"></a>Q: 图片的 Caption 如何参与检索？检索命中后图片怎么返回？

  

**参考答案**：

1. **摄取**：ImageCaptioner（Vision LLM，如 GPT-4o）为图片生成 Caption，文本**缝合进 Chunk 正文**，参与 Embedding 向量化

2. **检索**：用户文字查询时，Caption 文本被向量检索命中；BM25 也索引 Caption 关键词

3. **返回**：从 `image_index.db`（`image_id → 文件路径`映射）读取图片，Base64 编码，通过 MCP 返回 `ImageContent` 给 Client，实现"**搜文字出图**"

  

整个链路复用纯文本检索路径，无需额外特殊处理。

  

---

  

#### <a id="a-测试体系"></a>Q: 测试分几层？单元测试怎么 mock LLM？

  

**参考答案**：

三层金字塔：

- **Unit（单元测试）**：1198+ 个，只测业务逻辑，用 `unittest.mock.patch` 替换 LLM 客户端返回预设响应，避免真实 API 调用

- **Integration（集成测试）**：验证模块间协作（Ingestion Pipeline / Chroma 存储读写），使用真实组件

- **E2E（端到端测试）**：`test_mcp_client.py` 启动真实 MCP Server 子进程，发送 JSON-RPC 消息验证完整链路；`test_dashboard_smoke.py` 用 Streamlit AppTest 无头渲染验证

  

---

  

#### <a id="a-评估体系"></a>Q: Hit Rate@K 和 MRR 怎么计算？Ragas Faithfulness 衡量什么？

  

**参考答案**：

- **Hit Rate@K**：见 [→ 查看](#a-hit-rate)

  

- **MRR（Mean Reciprocal Rank）**：

  

$$MRR = \frac{1}{|Q|} \sum_{i=1}^{|Q|} \frac{1}{rank_i}$$

  

$rank_i$ 是第 $i$ 条查询中第一条正确结果的排名。第一条命中得 1 分，第 2 位得 0.5 分，衡量**头部排序质量**。

  

- **Ragas Faithfulness**：衡量 LLM 回答是否**完全基于检索到的 Context**，防止幻觉。分数接近 1 = 回答有据可查，接近 0 = 大量幻觉。

  

---

  

#### <a id="a-document-manager"></a>Q: 删除一个文档需要操作哪几个存储？失败怎么办？

  

**参考答案**：

必须**协调删除四路存储**：

1. **Chroma 向量库**：按 `metadata.source` 删除所有 Chunk 向量

2. **BM25 倒排索引**（`data/db/bm25/`）：移除所有词条的倒排条目

3. **ImageStorage**（`data/images/`）：删除关联图片文件

4. **FileIntegrity**（`ingestion_history.db`）：删除 SHA256 处理记录，使文件可重新摄取

  

**为什么必须四路同步**：只删 Chroma 不删 BM25 → 下次 Hybrid Search 从 BM25 召回已不存在的 Chunk，数据不一致；不删 FileIntegrity → 重传同一文件被认为"已处理"而跳过。

  

**失败策略**：尽力删除（best-effort），各存储独立尝试，失败记录错误日志但不阻塞其他存储。生产级可引入两阶段提交。

  

---

  

#### <a id="a-可观测性"></a>Q: Trace 是怎么实现的？Ingestion 的 5 个阶段各是什么？

  

**参考答案**：

**Trace 实现**：显式调用模式（非 AOP 拦截），各阶段手动向 TraceContext 写入耗时、数量、分数分布，存为 JSON Lines 结构化日志，零外部依赖（无需 LangSmith/LangFuse）。

  

**Ingestion 5 阶段**：Load → Split → Transform → Embed → Upsert

  

**Query Trace 5 阶段**：QueryProcess → DenseRecall → SparseRecall → Fusion → Rerank

  

Dashboard 展示：Query 追踪页面（Dense/Sparse 召回对比、Rerank 前后排名变化）、Ingestion 追踪（阶段耗时瀑布图）。

  

---

  

### 三、评分细则

  

**分档标准（严格执行，不得调整）**：

  

| 分档 | 标准 |

|-----|------|

| 9-10 | 所有核心问题答出关键细节，无露馅，表达清晰且有深度延伸 |

| 7-8 | 大部分问题答出主干，偶有细节遗漏（1-2 处），无严重露馅 |

| 5-6 | 架构层面基本掌握，但算法/实现细节有 3 处以上明显缺失，或有 1 处严重露馅 |

| 3-4 | 仅能描述表面概念，追问即露馅，简历存在明显虚报 |

| 1-2 | 核心技术点均无法解释，简历与实际能力严重不符 |

  

**5 个评分维度**：

  

| 维度 | 重点考察内容 |

|-----|------------|

| 项目架构掌握 | 三层架构、模块分工、可插拔设计能否清楚表达 |

| 简历真实性 | 量化指标有无测量方法支撑，强动词能否说清决策过程 |

| 算法理论深度 | RRF 公式、Cross-Encoder 原理、Hit Rate/MRR 计算 |

| 实现细节掌握 | chunk_id 生成、可插拔三步骤、MCP Tool 参数、四路删除 |

| 表达清晰度 | 回答完整性、逻辑链完整、能说清"为什么"而非只说"是什么" |

