---
title: 微信_波哥_公众号文章剪藏_2026-05-27_1-2
source: /api/v1/wechat_mp/web/fetch_mp_article_detail_html
author:
  - 波哥
published: 2026-04-23
created: 2026-05-27
description: TikHub 命中的微信公众号文章候选，共 2 条，本文档收录 2 条
tags:
  - clippings
  - wechat
  - 波哥
---

## 0x01. 【26年4月面试复盘】LangGraph 的流程流转，需要定时拉状态吗？

> 发布日期：2026-04-23  
> 原文链接：[【26年4月面试复盘】LangGraph 的流程流转，需要定时拉状态吗？](https://mp.weixin.qq.com/s/kQo8-R1a8vIDnyQfPyK18g)

前几天训练营同学说面试聊到 LangGraph，面试官突然问了一句：

 "你那个 Agent 的状态流转，是怎么驱动下一步的？需要起个定时任务去拉状态吗？"

 这题看着平平无奇，其实是个钩子。答"需要定时拉"，基本就等于告诉对方——我没真用过，只是看过几篇文章。

 把这题拆开讲清楚，顺便把 LangGraph 的执行模型也讲明白。

### 先说 LangGraph 是啥
 LangChain 出的东西，核心思路一句话： **把 Agent 的运行过程画成一张图**。

 **节点**：干活的地方，可能是一次 LLM 调用、一次工具调用、一次路由判断

 **边**：节点之间怎么跳

 **状态**：节点跑完会吐出一个新状态，框架看这个状态决定下一步走哪条边

 图是有向的，而且允许带环——这点很重要，Agent 那种"想一下、查一下、再想一下"的循环逻辑就是靠环实现的。

### 回到正题：状态怎么流转
 先给结论： **不需要定时任务，是事件驱动的**。

 节点执行完会主动触发下一个节点，根本不存在"谁去拉谁"的问题。

 为什么面试官要问这个？因为很多人第一反应是把 LangGraph 想成一个状态机表——状态写在数据库里，外面起个 worker 定时扫一遍，看哪些状态该往下走。这是传统工作流引擎的思路(比如早期的 Activiti)，但 LangGraph 完全不是这么干的。

 下面从四个角度讲清楚它是怎么工作的。

#### 1. 执行模型：一个循环搞定
 LangGraph 底层是一个事件循环，参考的是 Google Pregel 那套图计算模型。一次 run 里大致是这样：
```text
拿到当前状态
  ↓
喂给当前节点执行
  ↓
节点返回新状态
  ↓
框架看新状态 + 边上的条件函数，决定下一个节点
  ↓
跳到下一个节点 → 回到第一步
  ↓
直到遇到 END 或者达到递归上限
```
整个过程是 **同步连续** 的。节点 A 刚跑完，节点 B 立刻就被调起来，中间没有任何等待、没有任何轮询。

 流式场景(比如 SSE 把中间结果推给前端)也是一样的逻辑——节点吐出 token 的时候通过回调或者生成器往外推，依然是推，不是拉。

#### 2. 状态长什么样
 状态就是一个 dict。写代码的时候一般用 TypedDict 或者 Pydantic 定义一下 schema，让字段类型清楚些。

 节点干的事也很简单：

 拿到完整状态

 改其中几个字段

 把改动返回给框架

 然后框架负责合并。合并策略由 **reducer** **函数** 决定，比较常见的几种：

 **覆盖**：新值直接替换旧值(默认行为)

 **追加**：比如消息列表，新消息 append 到后面

 **求和、合并字典** 等自定义逻辑

 这里有个容易忽略的点： **状态是活在内存里的**。一次 run 开始时创建，run 结束就释放。不落盘、不进数据库。

#### 3. 那跨会话怎么办？Checkpoint 登场
 光靠内存肯定不够用。真实场景里到处都是要"记住"的情况：

 用户刷了页面，对话得接着聊

 Agent 正在执行，进程挂了，重启要能续上

 多轮对话跨越多次 HTTP 请求

 LangGraph 为此内置了 **checkpoint** **机制**。简单说就是在每一步执行完把状态快照一份，写到后端存储里。支持的后端挺多：内存、SQLite、Postgres、Redis 都有现成的实现。

 恢复的时候，根据 thread_id (或者你自己定义的 session 标识)从 checkpoint 读出状态，继续往下跑。

 **注意这里的读取时机** ——依然不是定时拉的。是用户发来新消息、或者外部事件触发的时候，顺手读一次。按需，不是轮询。

 这个区别很关键：

 轮询 = 不管有没有事，每隔 N 秒扫一遍

 按需 = 来了请求才去读

 资源消耗完全不是一个量级。

#### 4. 需要等待的场景怎么办
 有时候 Agent 跑到一半要等外部：

 等人工审批

 等用户补充信息

 等某个异步任务的结果回调

 LangGraph 提供了 **interrupt(中断)**机制。执行引擎跑到中断点就停下，状态保留在 checkpoint 里。

 唤醒它的方式依然是事件驱动的——消息队列来消息了、webhook 被调用了、用户在前端点了"同意"，这些事件触发恢复逻辑，从中断的地方接着跑。

 整条链路从头到尾，你找不到一个地方是靠"定时扫描"往前推的。

### 面试时可以这么答
 把上面的东西浓缩成两句话：

 不需要定时任务。LangGraph 是事件驱动的——节点跑完会根据返回的状态主动触发下一个节点，一次 run 里的流转是同步连续的。要支持跨会话恢复的话，用它自带的 checkpoint 把状态落到 Redis 或 DB，但读取时机也是事件驱动的，用户发新消息时根据 session 拉一次就行，不需要轮询。

 说完这句，基本就过了。

### 顺手准备一下追问
 面试官一般会顺着再挖两下，提前备好答案：

 **"那工具调用是阻塞的吗？"** 默认同步阻塞。但 LangGraph 支持 ainvoke，节点可以写成 async 函数，I/O 密集的工具(比如调外部 API)最好写成异步的，不然事件循环会被堵住。

 **"多个 Agent 或者多个任务要并行怎么搞？"** 用 Send API。一个节点可以 fan-out 到多个下游节点并行执行，最后再汇总。典型场景是并行搜多个数据源、然后让一个汇总节点合并结果——map-reduce 那套思路。

 **"状态特别大的时候，每次** **checkpoint** **会不会很慢？"** 这个问题稍微深一点。可以聊：checkpoint 是增量的(只记变化)、可以选择性 checkpoint(不是每步都存)、大字段可以存对象存储只留引用。面试官问到这说明对你已经比较感兴趣了。

### 最后总结一下
 这道题能筛掉一大批"背过教程"的候选人，本质上是在考 **推 vs 拉** 的思维。

 老一辈工作流引擎(Activiti、Camunda 早期版本)很多是拉模型——worker 定时去数据库扫 pending 任务。好处是简单、容错强；坏处是延迟高、资源浪费。

 LangGraph 这种现代框架走的是推模型——状态变化立刻触发下一步，全程在事件循环里完成，要持久化时才按需落盘。好处是实时、省资源；坏处是一旦进程挂了，没 checkpoint 就全丢。

 理解了这层差异，这题就不是八股，而是能顺势聊到架构选型、性能权衡、故障恢复的好入口。

 记住一句话就行： **LangGraph 的流转是推出来的，不是拉出来的。

## 0x02. 【26年4月面试题总结】构建生产级 Agent 系统:三个值得深挖的面试题

> 发布日期：2026-04-16  
> 原文链接：[【26年4月面试题总结】构建生产级 Agent 系统:三个值得深挖的面试题](https://mp.weixin.qq.com/s/DbQ8u_LQ5nbUqjy_Sw2rzA)

最近面试被问到几个很有意思的问题,整理下来发现它们恰好构成了一条主线: **如何把一个 Demo 级的 Agent 做成生产系统**。从用户交互、到节点执行、再到状态持久化,每一环都有工程上的权衡。

 这篇文章挑三个题展开:

 规划 Agent 完成后,如何让用户在中途编辑大纲?(HITL + SSE)

 LangGraph 的搜索节点怎么并发执行?

 Session 初始化时,如何优化 checkpoint 的加载速度?

### 1. Human-in-the-loop + SSE:规划 Agent 的人工干预

#### 场景
 一个 Research Agent 的典型流程是:
```text
用户提问 → Planner Agent 生成大纲 → Search Agent 执行搜索 → Writer Agent 生成报告
```
问题来了:Planner 生成的大纲可能不完全符合用户预期,用户想 **在搜索开始前手动补充几条**。也就是说,流程要从:
```text
Planner → Search
```
变成:
```text
Planner → [用户编辑] → Search
```
这里有两个技术难点:

 **图怎么暂停?** Search 节点不能直接跑,得等用户输入

 **SSE 怎么处理?** SSE 是单向流,服务端推给客户端,用户的编辑怎么传回来?

#### LangGraph 的 interrupt 机制
 LangGraph 原生支持暂停/恢复,核心是 interrupt + checkpointer:
```python
from langgraph.types import interrupt, Command
from langgraph.checkpoint.postgres import PostgresSaver

def plan_review_node(state):
    # 把当前大纲抛给外部,图在这里暂停并写 checkpoint
    user_edit = interrupt({
        "type": "outline_review",
        "outline": state["outline"],
    })
    # 恢复执行时,user_edit 就是外部传回的内容
    return {"outline": user_edit}

graph = builder.compile(checkpointer=PostgresSaver(...))
```
interrupt 的本质是 **抛出一个特殊异常**,LangGraph 捕获后把当前 state 持久化到 checkpointer,并把 interrupt 的 payload 作为本次 stream() 的最后一个事件返回。

 恢复时用 Command(resume=...):
```python
graph.stream(
    Command(resume=edited_outline),
    config={"configurable": {"thread_id": "xxx"}}
)
```
**关键点: thread_id** **是串联两次请求的唯一纽带**,checkpointer 靠它找到上次暂停的位置。

#### SSE 层的协议设计
 SSE 是单向的(服务端 → 客户端),所以"用户编辑"这个动作不能走 SSE,必须用一个新的 HTTP 请求。完整流程:
```text
┌──────────┐                              ┌──────────┐
│ Frontend │                              │ Backend  │
└────┬─────┘                              └────┬─────┘
     │                                         │
     │  POST /run  { query, thread_id }        │
     ├────────────────────────────────────────>│
     │                                         │
     │  SSE: event=node_update (planner done)  │
     │<────────────────────────────────────────┤
     │                                         │
     │  SSE: event=interrupt (outline)         │
     │<────────────────────────────────────────┤
     │  SSE: [DONE] ─ 关闭连接                 │
     │                                         │
     │  [用户编辑大纲...]                      │
     │                                         │
     │  POST /resume { thread_id, outline }    │
     ├────────────────────────────────────────>│
     │                                         │
     │  SSE: event=node_update (search 1)      │
     │<────────────────────────────────────────┤
     │  SSE: event=node_update (search 2)      │
     │<────────────────────────────────────────┤
     │  SSE: event=done                        │
     │<────────────────────────────────────────┤
```
#### 后端实现
```python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
import json

app = FastAPI()

asyncdef stream_graph(inputs, thread_id):
    config = {"configurable": {"thread_id": thread_id}}
    asyncfor event in graph.astream(inputs, config, stream_mode="updates"):
        # 普通节点更新
        yieldf"event: node_update\ndata: {json.dumps(event)}\n\n"

        # 检查是否触发了 interrupt
        if"__interrupt__"in event:
            payload = event["__interrupt__"][0].value
            yieldf"event: interrupt\ndata: {json.dumps(payload)}\n\n"
            return# 主动结束 SSE,等待用户输入

@app.post("/run")
asyncdef run(body: dict):
    return StreamingResponse(
        stream_graph({"query": body["query"]}, body["thread_id"]),
        media_type="text/event-stream",)

@app.post("/resume")
asyncdef resume(body: dict):
    return StreamingResponse(
        stream_graph(
            Command(resume=body["outline"]),
            body["thread_id"],),
        media_type="text/event-stream",)
```
#### 前端实现
```python
const threadId = crypto.randomUUID();

asyncfunction run(query) {
const resp = await fetch("/run", {
    method: "POST",
    body: JSON.stringify({ query, thread_id: threadId }),
  });
await handleSSE(resp);
}

asyncfunction handleSSE(resp) {
const reader = resp.body.getReader();
const decoder = new TextDecoder();
let buffer = "";

while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value);

    const events = buffer.split("\n\n");
    buffer = events.pop();

    for (const raw of events) {
      const { event, data } = parseSSE(raw);

      if (event === "interrupt") {
        // 切换到编辑态,等待用户提交
        const edited = await showOutlineEditor(JSON.parse(data));
        await resume(edited);
        return;
      }

      if (event === "node_update") {
        renderUpdate(JSON.parse(data));
      }
    }
  }
}

asyncfunction resume(outline) {
const resp = await fetch("/resume", {
    method: "POST",
    body: JSON.stringify({ thread_id: threadId, outline }),
  });
await handleSSE(resp);
}
```
#### 几个容易踩的坑
 **thread_id 必须前端生成并持久化**,否则 resume 时找不到暂停位置

 **SSE 遇到** **interrupt** **要主动关闭**,不要挂起连接等用户——用户可能编辑十分钟,长连接不划算

 **Checkpointer 必须开启**, interrupt 依赖它持久化 state

 **前端要做幂等处理**,用户可能刷新页面,这时需要用 thread_id 重新拉取当前 state

### 2. LangGraph 节点并发:三种模式

#### 问题
 Planner 生成了 5 个搜索 query,一个一个串行搜?那一个请求得跑几十秒。LangGraph 支持并发,但方式不止一种,得看场景选。

#### 模式 1:静态 Fan-out(编译期决定)
 图结构里直接定义多条并行边,适合 **分支数固定** 的场景:
```python
builder.add_edge("planner", "search_web")
builder.add_edge("planner", "search_arxiv")
builder.add_edge("planner", "search_internal")
builder.add_edge("search_web", "aggregator")
builder.add_edge("search_arxiv", "aggregator")
builder.add_edge("search_internal", "aggregator")
```
LangGraph 会自动并行跑三个 search 节点,全部完成后进 aggregator。

 **State 合并要注意**:三个节点同时写 results,必须用 reducer:
```python
from typing import Annotated
import operator

class State(TypedDict):
    results: Annotated[list, operator.add]  # 并发写自动合并
```
#### 模式 2:Send API 动态派发(运行期决定)
 Planner 生成几个 query 是动态的,这时用 Send:
```python
from langgraph.types import Send

def dispatch_searches(state):
    # 根据 planner 产出的 queries 动态派发
    return [
        Send("search_node", {"query": q, "topic": state["topic"]})
        for q in state["queries"]
    ]

builder.add_conditional_edges(
    "planner",
    dispatch_searches,
    ["search_node"],
)
builder.add_edge("search_node", "aggregator")
```
每个 Send 都会启动一份 search_node 的独立执行,各自的 state 互不干扰,最后通过 reducer 合并到主 state。

 **这是处理"N 个搜索** **query"最优雅的方式**,N 可以是 1 也可以是 100。

#### 模式 3:节点内部并发(手动控制)
 如果你不想暴露 N 个节点,只想让一个节点内部并发调多个 API:
```python
import asyncio

async def search_node(state):
    queries = state["queries"]
    results = await asyncio.gather(
        *[call_search_api(q) for q in queries])
    return {"results": results}
```
**适用场景**:

 并发粒度很细(比如 50 个 query),不想让图结构膨胀

 不需要每个 query 单独 checkpoint(Send 模式每个子任务都会 checkpoint)

#### 三种模式怎么选?
| 维度 | 静态 Fan-out | Send API | 节点内并发 |
| :--- | :--- | :--- | :--- |
| 分支数 | 编译期固定 | 运行时动态 | 运行时动态 |
| 可观测性 | 高(每个节点独立) | 高 | 低(黑盒) |
| Checkpoint 粒度 | 每节点 | 每子任务 | 整个节点 |
| 失败重试 | 节点级 | 子任务级 | 需自己实现 |
| 适用场景 | 固定几路搜索 | N 个同类子任务 | 细粒度 I/O 并发 |

 **经验法则**:

 Query 数固定 → 静态 Fan-out

 Query 数动态、需要独立重试 → Send API

 纯 I/O 批量调用、不关心单个失败 → 节点内 asyncio.gather

### 3. Checkpoint 加载优化

#### 问题
 Session 越多,checkpoint 表越大。用户打开一个历史对话,如果加载要 2 秒,体验就崩了。怎么优化?

 先看 LangGraph checkpoint 表的大致结构(以 Postgres 为例):
```python
CREATE TABLE checkpoints (
    thread_id TEXTNOTNULL,
    checkpoint_ns TEXTNOTNULLDEFAULT'',
    checkpoint_id TEXTNOTNULL,
    parent_checkpoint_id TEXT,
    checkpoint JSONB NOTNULL,    -- 完整 state
    metadata JSONB NOTNULL,
    PRIMARY KEY (thread_id, checkpoint_ns, checkpoint_id)
);
```
加载最新 checkpoint 的查询:
```sql
SELECT checkpoint, metadata
FROM checkpoints
WHERE thread_id = $1
ORDER BY checkpoint_id DESC
LIMIT 1;
```
#### 优化手段

#### 1. 索引:B-tree 复合索引
 默认主键已经覆盖 (thread_id, checkpoint_ns, checkpoint_id),这是 B-tree 复合索引。查询按 thread_id 过滤 + 按 checkpoint_id 排序,最左前缀匹配主键, **可以直接命中索引且免排序**。

 这里有个小知识:PG 的 B-tree 叶子节点按序存储, ORDER BY checkpoint_id DESC LIMIT 1 等价于"沿着索引反向读第一个",O(log N) 定位 + O(1) 读取。

#### 2. 懒加载:分离元数据和 State Blob
 如果 state 很大(比如包含完整聊天历史 + 搜索结果),每次都反序列化整个 JSONB 很慢。拆成两张表:
```python
-- 热表:只存元数据,小而快
CREATETABLE checkpoint_meta (
    thread_id TEXT,
    checkpoint_id TEXT,
    blob_ref UUID,
    created_at TIMESTAMPTZ,
    PRIMARY KEY (thread_id, checkpoint_id)
);

-- 冷表:存大 blob,按需加载
CREATETABLE checkpoint_blobs (
    blob_ref UUID PRIMARY KEY,
    data BYTEA  -- msgpack + zstd 压缩
);
```
Session 初始化时先查 meta 表拿到 blob_ref,blob 可以懒加载(比如只在用户真正滚动查看历史时才拉)。

#### 3. 压缩:msgpack + zstd
 JSONB 的存储有点冗余。改用 msgpack 序列化 + zstd 压缩,一般能压到 1/5 到 1/10:
```python
import msgpack, zstandard as zstd

def serialize(state):
    return zstd.compress(msgpack.packb(state))

def deserialize(data):
    return msgpack.unpackb(zstd.decompress(data))
```
小 state 可能得不偿失(压缩开销 > I/O 节省), **建议 >10KB** **才压缩**。

#### 4. 缓存层:Redis 挡在 PG 前面
 热 session 放 Redis,TTL 30 分钟:
```python
async def load_checkpoint(thread_id):
    # L1: Redis
    cached = await redis.get(f"ckpt:{thread_id}")
    if cached:
        return deserialize(cached)

    # L2: Postgres
    row = await pg.fetchrow(
        "SELECT checkpoint FROM checkpoints "
        "WHERE thread_id=$1 ORDER BY checkpoint_id DESC LIMIT 1",
        thread_id,)
    if row:
        await redis.setex(f"ckpt:{thread_id}", 1800, serialize(row))
    return row
```
注意缓存一致性:每次写 checkpoint 后要同步更新或删除 Redis key。

#### 5. 连接池 + 异步驱动
 同步 psycopg2 每次建连接要几十毫秒。换 asyncpg + 连接池:
```python
pool = await asyncpg.create_pool(
    dsn=DSN, min_size=10, max_size=50,
)
```
生产环境再套一层 **pgbouncer** (transaction pooling 模式),共享连接数。

#### 6. 冷热分离 + 归档
 90 天前的 checkpoint 迁到归档表,保持热表小:
```sql
-- 分区表按月划分
CREATE TABLE checkpoints_2026_04 PARTITION OF checkpoints
FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
```
PG 的分区表配合 pg_partman 可以自动滚动,老分区 detach 后归档到 S3。

#### 优化效果的一般经验值
| 优化项 | 加载延迟降幅 |
| :--- | :--- |
| 复合索引 | 基线(没有就是几秒全表扫) |
| 懒加载 blob | 30-50% |
| 压缩 | I/O 减少,网络/磁盘慢时效果明显 |
| Redis 缓存 | 热路径降到个位数毫秒 |
| 连接池 | 节省 10-50ms 连接建立开销 |

 **优先级建议**:索引是底线 → 连接池次之 → 命中率高的 session 上 Redis → state 真的很大才搞懒加载和压缩。不要过度工程。

### 总结
 回头看这三个问题,其实对应 Agent 系统的三个核心能力:

 **HITL** **+ SSE**:让 Agent 能和人协作,不是黑盒跑完

 **节点并发**:让 Agent 跑得快,不是串行等死

 **Checkpoint** **优化**:让 Agent 能记住事,不是每次从零开始

 一个生产级 Agent 系统,这三块缺一不可。框架(LangGraph)帮你解决了一部分,但协议设计、数据库优化、前后端协同这些事情,还得自己思考。

 面试如果能把这三块串起来讲,基本能让面试官知道你真的做过东西,而不是只跑过 demo。
![图片](https://mmbiz.qpic.cn/sz_mmbiz_png/kSX2Q9RM8CTpfpHHsCWCx05L3rjn5EqykKRibwib6U5S9MeC6fF4n8KoEV8U3XxHKDCQqB443qdI43C5VPyKvMYVaCNXWaFpP3Ga2ooyJ97do/640?wx_fmt=png&from=appmsg&wxfrom=5&wx_lazy=1&tp=webp#imgIndex=0)
