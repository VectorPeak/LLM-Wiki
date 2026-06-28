# 【RAG实战-11】Embedding model和Rerank model怎么选

> 🎁 下面把 2024-2025 年开源社区里最常被拿来做 **Embedding** 和 **Rerank** 的模型做个快速横评，**方便你按场景直接挑**。

## 1. 常用 Embedding 模型（双塔 / 稠密向量）

| 家族 | 语言覆盖 | 典型版本 | 亮点&劣势 |
|---|---|---|---|
| BGE | 中-英+多语 | bge-base-en/v1.5、bge-large-zh、bge-m3 | 中文效果出色，8K 上下文；reranker；MTEB 榜单（GitHub）（右侧截断） |
| E5 | 英语 / 多语 | e5-base-v2、multilingual-e5-*、e5-mistral-7B-instruct | 微调成本低，社区基线；长文本（Hugging Face）（右侧截断） |
| GTE | 中-英 / 多语 | gte-base-en-v1.5、gte-multilingual-base、gte-Qwen2-7B-instruct | 8K 上下文，在 MTEB 有官方 reranker 发布（Hugging Face）（右侧截断） |
| Instructor | 英语 | Instructor-base / XL | Instruction-tuning，任务、做分类/排序也很灵（Community）（右侧截断） |
| Jina Embeddings v2 | 英 / 中 / 多语版本 | jina-embeddings-v2-base-zh/en | 8K 长上下文、推理快，ColBERT 做长文检索（右侧截断） |
| MiniLM / all-MiniLM | 英语 | all-MiniLM-L6-v2 | 33M 参数的轻量模型，做边端检索常用（右侧截断） |

> 😎 **怎么选**
>
> **一般情况下无脑 `bge-m3`**
>
> - **中文或中英混合**：`bge-m3` 或 `bge-large-zh`
> - **多语言**：`gte-multilingual-base` 或 `bge-m3`
> - **资源紧张 / 边缘设备**：`e5-small` 或 `MiniLM`
> - **长文 ≥8K token**：Jina Embeddings v2

## 2. 常用 Rerank 模型（交叉编码 / Late Interaction / 稀疏）

| 类型 | 代表模型 | 特点 |
|---|---|---|
| 交叉编码 Cross-Encoder | `BAAI/bge-reranker-base` | 挺好。慢了点 |
| 交叉编码 Cross-Encoder | cross-encoder/ms-marco-MiniLM-L6-v2（Sentence-Transformers） | 英文检索圈最常用“万金油”精排，推理只需 2-3 ms（Hugging Face）（右侧截断） |
| 交叉编码 Cross-Encoder | gte-multilingual-reranker-base | 多语+中文官方精排，直接接 GTE embedding（Hugging Face）（右侧截断） |
| Late-Interaction | jina-colbert-v2 | ColBERT 结构，长文检索时精度/速度折中好（Hugging Face）（右侧截断） |
| 稀疏/混合 | SPLADE-v2 | 生成词项稀疏向量，可和稠密向量做 hybrid 检索（右侧截断） |

> 😎 **组合推荐**
>
> 1. **经典流水线**：`BGE-base` 检索 top100 -> `bge-reranker-base` 精排
> 2. **多语场景**：`gte-multilingual-base` + `gte-multilingual-reranker`
> 3. **GPU 紧张**：`e5-small` + `MiniLM-L6-cross-encoder`（batch 推理）
> 4. **长文/8K**：`jina-embeddings-v2` + `jina-colbert-v2`，段内匹配更稳

## 3. 评估与资源

- **MTEB（Massive Text Embedding Benchmark）** 提供 58 个任务的统一榜单，随时查看最新模型排行（Hugging Face）。
- Hugging Face 上所有上述模型都可通过 `from sentence_transformers import SentenceTransformer` 一行加载；LangChain / LlamaIndex 已内置 BGE、GTE、E5 等适配。
- 若想跑本地向量库，可配 Milvus、Weaviate、Qdrant；稀疏向量（SPLADE）可直接用 Elasticsearch / OpenSearch 的倒排索引。

> 😎 **Embedding** 端现在最火的是 BGE、E5、GTE、Jina v2；
> **Rerank** 端则以同门的 **BGE-Reranker**、**MiniLM Cross-Encoder**、**GTE-Reranker** 和 **ColBERT / SPLADE** 为主流。
>
> 按 **语种、上下文长度和部署资源** 选一对“向量 + 精排”即可快速落地。
