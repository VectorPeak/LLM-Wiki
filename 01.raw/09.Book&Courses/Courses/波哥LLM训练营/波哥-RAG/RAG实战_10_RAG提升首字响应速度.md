# 【RAG实战-第10天】如何提升首字响应速度

> ✍️ 原理 × 代码 一步步剖析每个瓶颈，附完整 Python 示例

## 整体视角：RAG 性能公式

- Ttotal
- Tembed(query) # 查询向量
- Tretrieval # 向量检索
- Tprompt-build # 上下文构建
- Tinfra-overhead # 网络 / 队列 / I/O

**思路：先找最长木板 -> 就地减速 -> 流水线并行。**

下面按流程拆分，以 **OpenAI 原生接口 + Milvus 数据库的形式搭建 RAG**，按照 **“为什么慢”**，再给 **“怎么快” + “可运行示例代码”** 逐步进行分析。

## 1. Embedding 阶段（OpenAI API）

| 问题 | 加速手段 |
|---|---|
| 网络往返多、一次只算一条 | **批量请求（batch）** |
| I/O 等待白白浪费 CPU | **异步并发（asyncio + semaphore）** |
| 重复文本反复算 | **Redis/KV 缓存** |
| 模型本身推理慢 | **小模型 / 量化 / 本地部署** |

- **批量请求 Embedding**：利用 OpenAI 嵌入接口支持批处理的特性，将多个文本一次性发送以减少总请求数。例如，可以把待嵌入的多个查询或文本段组合成数组传入单次 API 调用，避免逐条请求所带来的网络开销。需要注意每次请求的最大 token 限制（如模型对每个输入文本通常限制 ~8192 tokens）并在超出时拆分批次，以免报错。

- **并发调用与异步处理**：合理利用并发提高吞吐量。通过 Python 的 `asyncio` 等异步框架，可以在等待一个 Embedding 结果时并行触发其他请求。实践中 OpenAI 对并发请求有一定限制，过高并发可能引起排队延迟，经验上将并发控制在单-digit 数量比较稳妥（例如同时 5~10 个请求）并监控接口返回的速率限制信息。当高并发场景下，可以采用指数退避重试策略来应对 429/Rate Limit 错误。**异步非阻塞调用能让 CPU 空闲时间用于处理其它任务**，从而提升整体吞吐。（资源多、直接 k8s 搞无数个节点的可以忽略）

- **缓存 Embedding 结果**：针对重复出现的文本，缓存其 Embedding 以避免重复计算。例如，对于常见问题或频繁查询，可以在首次获取 Embedding 后将 `query -> embedding` 键值对存入内存或 Redis 缓存。下次遇到相同查询时直接复用缓存向量，跳过 API 调用，从而显著降低延迟。需要设计缓存键（可用查询字符串或其哈希）并考虑语义相近但不完全相同的查询不会命中缓存的情况。对于文档语料，**尽量预先计算并存储 Embedding**，避免在查询时现算。

```python
pip install openai redis tiktoken
import os, json, asyncio, hashlib, redis, tiktoken, openai
openai.api_key = os.getenv("OPENAI_API_KEY")
MODEL, DIM = "text-embedding-3-small", 1536
enc = tiktoken.encoding_for_model(MODEL)
redis_cli = redis.Redis(host="localhost", decode_responses=True)

def _key(text):
    return "emb:" + hashlib.sha1(
        " ".join(text.split()).lower().encode()
    ).hexdigest()

async def _embed_batch(batch):
    resp = await openai.Embedding.acreate(model=MODEL, input=batch)
    return [d["embedding"] for d in resp["data"]]

async def embed(texts, concurrency=5, token_cap=8191):
    # ① 批量分组
    batch, cur, out, sem = [], 0, [], asyncio.Semaphore(concurrency)

    async def run(b):
        # ② 异步 + 并发
        async with sem:
            return await _embed_batch(b)

    async def push():
        # 发起单批
        nonlocal batch, cur
        out.extend(await run(batch))
        batch, cur = [], 0

    tasks = []
    for txt in texts:
        if (vec := redis_cli.get(_key(txt))):  # ③ 缓存命中
            out.append(json.loads(vec))
            continue
        tok = len(enc.encode(txt))
        if cur + tok > token_cap and batch:
            tasks.append(asyncio.create_task(push()))
        batch.append(txt)
        cur += tok

    if batch:
        tasks.append(asyncio.create_task(push()))
    await asyncio.gather(*tasks)

    # ④ 把新算的结果写缓存
    for t, v in zip(texts, out):
        redis_cli.set(_key(t), json.dumps(v), ex=86400)
    return out
```

## 2. 向量检索阶段（Milvus）

| 痛点               | 加速手段                   |
| ---------------- | ---------------------- |
| 全库暴力扫            | **ANN 索引（HNSW / IVF）** |
| 海量数据串行查          | **批量 search + 多副本加载**  |
| query 多但每次只看少量数据 | **分区 / 过滤**            |
| CPU 饱和           | **GPU or 水平扩容**        |

- **使用近似邻居索引（ANN）**：避免对大型语料库进行逐条精确暴力搜索，可改用近似最近邻算法构建索引，例如 IVF、HNSW 等，以大幅提升检索速度。实践表明，对于百万级向量数据，HNSW 索引在保持较高召回的同时能将查询延迟降低到毫秒级。Milvus 官方也推荐在需要高性能检索时选用 HNSW 索引。如果使用 IVF 索引，可调节细分簇数量（`nlist`）和查询探测范围（`nprobe`）：增大 `nlist` 提高召回率，减少 `nprobe` 缩短查询时间，从而在速度与准确率间取得平衡。索引构建时的参数（如 HNSW 的 `efConstruction` 或 IVF 的分桶参数）也应根据数据规模调优，以保证查询阶段有良好性能。

- **优化数据分片与过滤**：利用 Milvus 的分区和过滤功能缩小检索范围，从而减少每次查询需要遍历的向量数量。如果先知道查询只涉及某部分语料（例如按来源、时间分区的数据），可将向量集合按属性切分成分区，查询时指定相应分区检索，避免全库扫描。对于规模超大的向量集合，合理分片（sharding）有助于降低单机内检索延迟。同时剔除过期或低相关的向量（例如对知识库定期清理无用数据）可减小索引规模，使查询更高效。

- **批量查询与并发连接**：Milvus 支持在一次请求中执行批量搜索（即传入多个查询向量一起检索），这相比逐一查询能减少网络开销和调度开销，适用于需要同时回答多子问题或多用户批量请求的场景。对于并发请求量高的系统，可在客户端维护连接池或使用多线程/协程并发查询 Milvus。Milvus 2.x 的无锁架构对并发查询有良好支持，但仍需确保后端资源充足（CPU/内存不成为瓶颈）。**如果 QPS 需求特别高，增加检索副本：Milvus 允许在内存中加载数据的多个副本来提高并行查询能力。通过在 `collection.load()` 时设置 `replica_number > 1`，可以启用多副本使查询负载分摊到不同 Query Node，从而提升整体吞吐。** 例如，将副本数设为 4 可显著提高 QPS 上限。同样，需要搭配增加 Milvus 后端的 QueryNode 实例数和计算资源，以充分利用副本带来的并行度。

- **系统配置与硬件加速**：调整 Milvus 的配置以匹配性能需求。例如，在保证召回的前提下将搜索参数 `efSearch`（对 HNSW）或 `nprobe`（对 IVF）设为较小值以加快查询。确保在查询前调用 `collection.load()` 将数据加载至内存，并设置合适的 `cache_config`（Milvus 会将常用数据页缓存在内存）。如果数据规模巨大或需要亚毫秒级查询延迟，可考虑 GPU 加速：使用 Milvus 的 GPU 版本或将向量数据托管到支持 GPU 的向量引擎上，以利用 GPU 的并行计算能力执行向量点积运算。不过 GPU 方案需要权衡部署成本，通常在超大规模或低延迟（如实时推荐）场景才需要。总体而言，**充分利用 Milvus 的并行和内存特性。**

```python
# pip install pymilvus==2.3.4
from pymilvus import connections, FieldSchema, CollectionSchema, DataType, Collection

connections.connect(host="127.0.0.1", port="19530")

fields = [
    FieldSchema("id", DataType.INT64, is_primary=True, auto_id=True),
    FieldSchema("vec", DataType.FLOAT_VECTOR, dim=DIM),
    FieldSchema("txt", DataType.VARCHAR, max_length=1024),
]

col = Collection("rag_docs", CollectionSchema(fields))

# ① HNSW 索引（只建一次）
if not col.indexes:
    col.create_index("vec", {"index_type": "HNSW", "metric_type": "IP",
                             "params": {"M": 16, "efConstruction": 128}})

# ② 把向量加载到内存，并开 4 副本
col.load(replica_number=4)

def search(vecs, k=5, ef=64):
    p = {"metric_type": "IP", "params": {"ef": ef}}
    res = col.search(vecs, "vec", p, k=k, output_fields=["txt"])
    return [[hit.entity.txt for hit in hits] for hits in res]
```

## 3. 系统整体优化策略

最后，从架构层面综合考虑全链路的优化，确保各模块高效协同工作：

- **异步架构与并发设计**：采用异步非阻塞架构充分利用服务器资源，提高整体吞吐量。例如使用 Python 的 `asyncio` 或多线程池，让 Embedding 计算、向量检索、LLM 生成等步骤能够流水线并行或重叠执行。对于单个查询流程，大部分步骤是顺序依赖的，但可以 **并行化独立操作**（如同时处理多个用户请求，或如上节所述在生成回答的同时预取下次检索）。针对高并发的场景，可引入 **任务队列**（如 RabbitMQ、Kafka）和工作进程批量处理请求。例如积攒一定数量的查询统一进行 Embedding 或检索操作，以摊薄单次处理开销。同时，可以部署 **多实例 LLM 服务**（如果使用自托管模型）或使用 OpenAI 多 API Key 分流，请求端做负载均衡以避免单点瓶颈。无论何种并发方案，都要监控关键指标如每秒查询数（QPS）和端到端延迟，根据负载动态扩容资源。

```python
# 全链路异步流水线
async def rag_once(question, k=3):
    q_vec = (await embed([question]))[0]          # ① embed
    docs = search([q_vec], k=k)[0]                # ② retrieval
    prompt = build_prompt(question, docs)         # ③ prompt
    print("\n[AI] ", end="", flush=True)
    await stream_chat(prompt)                     # ④ generate

# Demo
# asyncio.run(rag_once("量子计算的基本原理？"))

# 服务化（FastAPI + 线程池）
# pip install fastapi uvicorn
from fastapi import FastAPI
import uvicorn, asyncio
from concurrent.futures import ThreadPoolExecutor
pool = ThreadPoolExecutor(20)     # Milvus + OpenAI 并发

app = FastAPI()

@app.post("/rag")
async def api(req: dict):
    q = req["question"]
    loop = asyncio.get_event_loop()
    # 把阻塞 I/O 移出事件循环
    await loop.run_in_executor(pool, lambda: asyncio.run(rag_once(q)))
    return {"ok": True}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
```

- **引入缓存层（Redis 等）**：在系统中增加缓存机制，用空间换时间，避免重复计算开销。缓存可存在多个层次：**（1）Embedding 缓存**：缓存常见查询文本的向量表示，下次出现直接复用；缓存文档向量同样重要，静态语料库可以离线算好全部向量并存入 Milvus 或 KV 存储。**（2）检索结果缓存**：对于经常被查询的问题，其检索到的文档列表往往相同，可缓存这些文档 ID 列表，下次查询时直接使用缓存结果而无需访问向量库。**（3）答案缓存**：对于高度重复且答案固定的提问（如 FAQ），可以直接缓存上一次的完整回答文本。下次相同提问立即返回缓存答案，实现近乎零延迟响应。**需要注意对于有时效性的数据（如新闻、股价），缓存过久可能失准，需设置适当 TTL 或在数据更新时主动清除相关缓存。** 使用 Redis 这类内存 KV 存储可以提供毫秒级的读取性能，适合做共享缓存层。同时通过哈希 key（例如将 query 字符串规范化后哈希）索引缓存内容，并采用 LRU 等策略淘汰冷门条目。总之，缓存系统的引入能大幅减少重复调用 OpenAI API 和向量库的次数，从架构上加快响应。

```python
# Embedding缓存
EMB_TTL = timedelta(days=30)       # 静态文档可更长

async def get_embed_cached(text: str):
    key = f"emb:{_hash(text)}"
    if (vec := _get(key)):
        return vec                 # 命中缓存
    vec = (await embed([text]))[0]
    _set(key, vec, EMB_TTL)
    return vec

# 检索结果缓存
SEARCH_TTL = timedelta(days=1)     # 语料相对稳定，可按需调整

def search_cached(question: str, q_vec, k=3):
    key = f"srch:{_hash(question)}:{k}"
    if (hits := _get(key)):
        return hits
    hits = search([q_vec], k=k)[0]  # 调 Milvus
    _set(key, hits, SEARCH_TTL)
    return hits

# 答案缓存
ANS_TTL = timedelta(days=7)         # FAQ 可更长；时效数据可减小

async def answer_cached(question: str):
    key = f"ans:{_hash(question)}"
    if (ans := _get(key)):
        return ans                  # 秒级返回

    # — 缓存未命中：正常 RAG 流程 —
    q_vec = await get_embed_cached(question)
    docs = search_cached(question, q_vec, k=3)
    prompt = build_prompt(question, docs)

    # 不需要流式时可直接用 openai.ChatCompletion
    chunks = []
    async for tok in stream_chat(prompt):  # 自行实现 yield token
        chunks.append(tok)
    answer = "".join(chunks)

    _set(key, answer, ANS_TTL)
    return answer
```

> 🎁 按本文逐节落地，你的 Milvus + OpenAI RAG 可以从 **秒级** 降到 **百毫秒**，
> 如果 GPU/HNSW 再加流水线并发，甚至可做到更快的首字响应。
