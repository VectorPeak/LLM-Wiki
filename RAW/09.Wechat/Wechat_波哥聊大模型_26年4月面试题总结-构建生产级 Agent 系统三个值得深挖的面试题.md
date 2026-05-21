---
title: 【26年4月面试题总结】构建生产级 Agent 系统:三个值得深挖的面试题
source: https://mp.weixin.qq.com/s/DbQ8u_LQ5nbUqjy_Sw2rzA
author:
  - 波哥聊大模型
published:
created: 2026-05-07
description: 最近面试被问到几个很有意思的问题,整理下来发现它们恰好构成了一条主线:如何把一个 Demo 级的 Agent 做成生产系统。从用户交互、到节点执行、再到状态持久化,每一环都有工程上的权衡。
tags:
  - clippings
---

---

最近面试被问到几个很有意思的问题,整理下来发现它们恰好构成了一条主线:**如何把一个 Demo 级的 Agent 做成生产系统** 。从用户交互、到节点执行、再到状态持久化,每一环都有工程上的权衡。

这篇文章挑三个题展开:

1. 规划 Agent 完成后,如何让用户在中途编辑大纲?(HITL + SSE)
2. LangGraph 的搜索节点怎么并发执行?
3. Session 初始化时,如何优化 checkpoint 的加载速度?

## 一、Human-in-the-loop + SSE:规划 Agent 的人工干预

### 场景

一个 Research Agent 的典型流程是:

```
用户提问 → Planner Agent 生成大纲 → Search Agent 执行搜索 → Writer Agent 生成报告
```

问题来了:Planner 生成的大纲可能不完全符合用户预期,用户想 **在搜索开始前手动补充几条** 。也就是说,流程要从:

```
Planner → Search
```

变成:

```
Planner → [用户编辑] → Search
```

这里有两个技术难点:

- **图怎么暂停?** Search 节点不能直接跑,得等用户输入
- **SSE 怎么处理?** SSE 是单向流,服务端推给客户端,用户的编辑怎么传回来?

### LangGraph 的 interrupt 机制

LangGraph 原生支持暂停/恢复,核心是 `interrupt` + `checkpointer`:

```
from langgraph.types import interrupt, Command
from langgraph.checkpoint.postgres import PostgresSaver

def plan_review_node(state):
    # 把当前大纲抛给外部,图在这里暂停并写 checkpoint
    user_edit = interrupt({
        "type": "outline_review",
        "outline": state["outline"],
    })
    # 恢复执行时,user_edit 就是外部传回的内容
    return {"outline": user_edit}

graph = builder.compile(checkpointer=PostgresSaver(...))
```

`interrupt` 的本质是 **抛出一个特殊异常**,LangGraph 捕获后把当前 state 持久化到 checkpointer,并把 interrupt 的 payload 作为本次 `stream()` 的最后一个事件返回。

恢复时用 `Command(resume=...)`:

```
graph.stream(
    Command(resume=edited_outline),
    config={"configurable": {"thread_id": "xxx"}}
)
```

**关键点:`thread_id`** **是串联两次请求的唯一纽带**,checkpointer 靠它找到上次暂停的位置。

### SSE 层的协议设计

SSE 是单向的(服务端 → 客户端),所以"用户编辑"这个动作不能走 SSE,必须用一个新的 HTTP 请求。完整流程:

```
┌──────────┐                              ┌──────────┐
│ Frontend │                              │ Backend  │
└────┬─────┘                              └────┬─────┘
     │                                         │
     │  POST /run  { query, thread_id }        │
     ├────────────────────────────────────────>│
     │                                         │
     │  SSE: event=node_update (planner done)  │
     │<────────────────────────────────────────┤
     │                                         │
     │  SSE: event=interrupt (outline)         │
     │<────────────────────────────────────────┤
     │  SSE: [DONE] ─ 关闭连接                 │
     │                                         │
     │  [用户编辑大纲...]                      │
     │                                         │
     │  POST /resume { thread_id, outline }    │
     ├────────────────────────────────────────>│
     │                                         │
     │  SSE: event=node_update (search 1)      │
     │<────────────────────────────────────────┤
     │  SSE: event=node_update (search 2)      │
     │<────────────────────────────────────────┤
     │  SSE: event=done                        │
     │<────────────────────────────────────────┤
```

### 后端实现

```
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
import json

app = FastAPI()

asyncdef stream_graph(inputs, thread_id):
    config = {"configurable": {"thread_id": thread_id}}
    asyncfor event in graph.astream(inputs, config, stream_mode="updates"):
        # 普通节点更新
        yieldf"event: node_update\ndata: {json.dumps(event)}\n\n"
        
        # 检查是否触发了 interrupt
        if"__interrupt__"in event:
            payload = event["__interrupt__"][0].value
            yieldf"event: interrupt\ndata: {json.dumps(payload)}\n\n"
            return# 主动结束 SSE,等待用户输入

@app.post("/run")
asyncdef run(body: dict):
    return StreamingResponse(
        stream_graph({"query": body["query"]}, body["thread_id"]),
        media_type="text/event-stream",
    )

@app.post("/resume")
asyncdef resume(body: dict):
    return StreamingResponse(
        stream_graph(
            Command(resume=body["outline"]),
            body["thread_id"],
        ),
        media_type="text/event-stream",
    )
```

### 前端实现

```
const threadId = crypto.randomUUID();

asyncfunction run(query) {
const resp = await fetch("/run", {
    method: "POST",
    body: JSON.stringify({ query, thread_id: threadId }),
  });
await handleSSE(resp);
}

asyncfunction handleSSE(resp) {
const reader = resp.body.getReader();
const decoder = new TextDecoder();
let buffer = "";

while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value);
    
    const events = buffer.split("\n\n");
    buffer = events.pop();
    
    for (const raw of events) {
      const { event, data } = parseSSE(raw);
      
      if (event === "interrupt") {
        // 切换到编辑态,等待用户提交
        const edited = await showOutlineEditor(JSON.parse(data));
        await resume(edited);
        return;
      }
      
      if (event === "node_update") {
        renderUpdate(JSON.parse(data));
      }
    }
  }
}

asyncfunction resume(outline) {
const resp = await fetch("/resume", {
    method: "POST",
    body: JSON.stringify({ thread_id: threadId, outline }),
  });
await handleSSE(resp);
}
```

### 几个容易踩的坑

1. **thread\_id 必须前端生成并持久化**,否则 resume 时找不到暂停位置
2. **SSE 遇到** **interrupt** **要主动关闭**,不要挂起连接等用户——用户可能编辑十分钟,长连接不划算
3. **Checkpointer 必须开启**,`interrupt` 依赖它持久化 state
4. **前端要做幂等处理**,用户可能刷新页面,这时需要用 `thread_id` 重新拉取当前 state

## 二、LangGraph 节点并发:三种模式

### 问题

Planner 生成了 5 个搜索 query,一个一个串行搜?那一个请求得跑几十秒。LangGraph 支持并发,但方式不止一种,得看场景选。

### 模式 1:静态 Fan-out(编译期决定)

图结构里直接定义多条并行边,适合 **分支数固定** 的场景:

```
builder.add_edge("planner", "search_web")
builder.add_edge("planner", "search_arxiv")
builder.add_edge("planner", "search_internal")
builder.add_edge("search_web", "aggregator")
builder.add_edge("search_arxiv", "aggregator")
builder.add_edge("search_internal", "aggregator")
```

LangGraph 会自动并行跑三个 search 节点,全部完成后进 aggregator。

**State 合并要注意**:三个节点同时写 `results`,必须用 reducer:

```
from typing import Annotated
import operator

class State(TypedDict):
    results: Annotated[list, operator.add]  # 并发写自动合并
```

### 模式 2:Send API 动态派发(运行期决定)

Planner 生成几个 query 是动态的,这时用 `Send`:

```
from langgraph.types import Send

def dispatch_searches(state):
    # 根据 planner 产出的 queries 动态派发
    return [
        Send("search_node", {"query": q, "topic": state["topic"]})
        for q in state["queries"]
    ]

builder.add_conditional_edges(
    "planner",
    dispatch_searches,
    ["search_node"],
)
builder.add_edge("search_node", "aggregator")
```

每个 `Send` 都会启动一份 `search_node` 的独立执行,各自的 state 互不干扰,最后通过 reducer 合并到主 state。

**这是处理"N 个搜索** **query"最优雅的方式**,N 可以是 1 也可以是 100。

### 模式 3:节点内部并发(手动控制)

如果你不想暴露 N 个节点,只想让一个节点内部并发调多个 API:

```
import asyncio

async def search_node(state):
    queries = state["queries"]
    results = await asyncio.gather(
        *[call_search_api(q) for q in queries]
    )
    return {"results": results}
```

**适用场景**:

- 并发粒度很细(比如 50 个 query),不想让图结构膨胀
- 不需要每个 query 单独 checkpoint(Send 模式每个子任务都会 checkpoint)

### 三种模式怎么选?

| 维度 | 静态 Fan-out | Send API | 节点内并发 |
| --- | --- | --- | --- |
| 分支数 | 编译期固定 | 运行时动态 | 运行时动态 |
| 可观测性 | 高(每个节点独立) | 高 | 低(黑盒) |
| Checkpoint 粒度 | 每节点 | 每子任务 | 整个节点 |
| 失败重试 | 节点级 | 子任务级 | 需自己实现 |
| 适用场景 | 固定几路搜索 | N 个同类子任务 | 细粒度 I/O 并发 |

**经验法则**:

- Query 数固定 → 静态 Fan-out
- Query 数动态、需要独立重试 → Send API
- 纯 I/O 批量调用、不关心单个失败 → 节点内 `asyncio.gather`

## 三、Checkpoint 加载优化

### 问题

Session 越多,checkpoint 表越大。用户打开一个历史对话,如果加载要 2 秒,体验就崩了。怎么优化?

先看 LangGraph checkpoint 表的大致结构(以 Postgres 为例):

```
CREATE TABLE checkpoints (
    thread_id TEXTNOTNULL,
    checkpoint_ns TEXTNOTNULLDEFAULT'',
    checkpoint_id TEXTNOTNULL,
    parent_checkpoint_id TEXT,
    checkpoint JSONB NOTNULL,    -- 完整 state
    metadata JSONB NOTNULL,
    PRIMARY KEY (thread_id, checkpoint_ns, checkpoint_id)
);
```

加载最新 checkpoint 的查询:

```
SELECT checkpoint, metadata 
FROM checkpoints 
WHERE thread_id = $1 
ORDER BY checkpoint_id DESC 
LIMIT 1;
```

### 优化手段

#### 1、索引:B-tree 复合索引

默认主键已经覆盖 `(thread_id, checkpoint_ns, checkpoint_id)`,这是 B-tree 复合索引。查询按 `thread_id` 过滤 + 按 `checkpoint_id` 排序,最左前缀匹配主键,**可以直接命中索引且免排序** 。

这里有个小知识:PG 的 B-tree 叶子节点按序存储,`ORDER BY checkpoint_id DESC LIMIT 1` 等价于"沿着索引反向读第一个",O(log N) 定位 + O(1) 读取。

#### 2、懒加载:分离元数据和 State Blob

如果 state 很大(比如包含完整聊天历史 + 搜索结果),每次都反序列化整个 JSONB 很慢。拆成两张表:

```
-- 热表:只存元数据,小而快
CREATETABLE checkpoint_meta (
    thread_id TEXT,
    checkpoint_id TEXT,
    blob_ref UUID,
    created_at TIMESTAMPTZ,
    PRIMARY KEY (thread_id, checkpoint_id)
);

-- 冷表:存大 blob,按需加载
CREATETABLE checkpoint_blobs (
    blob_ref UUID PRIMARY KEY,
    data BYTEA  -- msgpack + zstd 压缩
);
```

Session 初始化时先查 meta 表拿到 `blob_ref`,blob 可以懒加载(比如只在用户真正滚动查看历史时才拉)。

#### 3、压缩:msgpack + zstd

JSONB 的存储有点冗余。改用 `msgpack` 序列化 + `zstd` 压缩,一般能压到 1/5 到 1/10:

```
import msgpack, zstandard as zstd

def serialize(state):
    return zstd.compress(msgpack.packb(state))

def deserialize(data):
    return msgpack.unpackb(zstd.decompress(data))
```

小 state 可能得不偿失(压缩开销 > I/O 节省),**建议 >10KB** **才压缩** 。

#### 4、缓存层:Redis 挡在 PG 前面

热 session 放 Redis,TTL 30 分钟:

```
async def load_checkpoint(thread_id):
    # L1: Redis
    cached = await redis.get(f"ckpt:{thread_id}")
    if cached:
        return deserialize(cached)
    
    # L2: Postgres
    row = await pg.fetchrow(
        "SELECT checkpoint FROM checkpoints "
        "WHERE thread_id=$1 ORDER BY checkpoint_id DESC LIMIT 1",
        thread_id,
    )
    if row:
        await redis.setex(f"ckpt:{thread_id}", 1800, serialize(row))
    return row
```

注意缓存一致性:每次写 checkpoint 后要同步更新或删除 Redis key。

#### 5、连接池 + 异步驱动

同步 `psycopg2` 每次建连接要几十毫秒。换 `asyncpg` + 连接池:

```
pool = await asyncpg.create_pool(
    dsn=DSN, min_size=10, max_size=50,
)
```

生产环境再套一层 **pgbouncer** (transaction pooling 模式),共享连接数。

#### 6、冷热分离 + 归档

90 天前的 checkpoint 迁到归档表,保持热表小:

```
-- 分区表按月划分
CREATE TABLE checkpoints_2026_04 PARTITION OF checkpoints
FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
```

PG 的分区表配合 `pg_partman` 可以自动滚动,老分区 detach 后归档到 S3。

### 优化效果的一般经验值

| 优化项 | 加载延迟降幅 |
| --- | --- |
| 复合索引 | 基线(没有就是几秒全表扫) |
| 懒加载 blob | 30-50% |
| 压缩 | I/O 减少,网络/磁盘慢时效果明显 |
| Redis 缓存 | 热路径降到个位数毫秒 |
| 连接池 | 节省 10-50ms 连接建立开销 |

**优先级建议**:索引是底线 → 连接池次之 → 命中率高的 session 上 Redis → state 真的很大才搞懒加载和压缩。不要过度工程。

## 总结

回头看这三个问题,其实对应 Agent 系统的三个核心能力:

- **HITL** **\+ SSE**:让 Agent 能和人协作,不是黑盒跑完
- **节点并发**:让 Agent 跑得快,不是串行等死
- **Checkpoint** **优化**:让 Agent 能记住事,不是每次从零开始

一个生产级 Agent 系统,这三块缺一不可。框架(LangGraph)帮你解决了一部分,但协议设计、数据库优化、前后端协同这些事情,还得自己思考。

面试如果能把这三块串起来讲,基本能让面试官知道你真的做过东西,而不是只跑过 demo。
