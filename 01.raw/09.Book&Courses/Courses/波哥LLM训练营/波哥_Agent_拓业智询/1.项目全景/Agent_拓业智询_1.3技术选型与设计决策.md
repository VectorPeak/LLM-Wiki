# 1.3 技术选型与设计决策

## 一、技术选型总览

### 1.1 技术栈全景

| 层次 | 技术选择 | 替代方案 | 选择理由 |
| --- | --- | --- | --- |
| 前端框架 | React 18 + TypeScript | Vue 3 / Svelte | 生态成熟，TypeScript 类型安全 |
| UI 组件库 | Ant Design 5.x | Material-UI / Chakra | 企业级设计，中文友好 |
| 图表库 | ECharts 5.x | Chart.js / D3.js | 功能强大，百度开源 |
| 后端框架 | FastAPI | Django / Flask | 高性能异步，自动文档生成 |
| 多智能体框架 | LangGraph | CrewAI / AutoGen | 状态机清晰，可控性强 |
| 主力 LLM | DeepSeek V3.2 | GPT-4 / Claude | 性价比高，中文能力强 |
| 快速 LLM | Qwen Plus | Kimi / ChatGLM | 响应快，成本低 |
| 搜索 API | Bocha API | Tavily / Serper | 支持摘要，中文优化 |
| 向量数据库 | Milvus 2.x | Pinecone / Weaviate | 开源免费，性能优秀 |
| 嵌入模型 | text-embedding-v4 | OpenAI ada-002 | 1024 维，中文效果好 |
| 关系数据库 | PostgreSQL 15 | MySQL / MongoDB | JSONB 支持，功能丰富 |
| 缓存 | Redis 7 | Memcached | 数据结构丰富，持久化 |
| 容器化 | Docker + Compose | Kubernetes | 简单够用，快速部署 |

## 二、核心决策解析

### 2.1 为什么选择 LangGraph 而非 CrewAI / AutoGen？

对比分析：

| 框架 | 优势 | 劣势 | 适用场景 |
| --- | --- | --- | --- |
| LangGraph | 状态机明确，可控性强，支持条件路由和循环 | 需要手动构图，学习曲线稍陡 | 复杂工作流，需要精细控制 |
| CrewAI | 上手简单，Agent 定义直观 | 黑盒较多，难以调试复杂流程 | 简单多 Agent 协作 |
| AutoGen | 微软出品，与 Azure 集成好 | 文档较少，社区小 | 企业内部，依赖 Azure |

我们的选择：LangGraph

原因：

1. 透明可控：状态机图一目了然，容易 Debug。
2. 灵活路由：支持复杂的条件分支，例如审核后的三种路由。
3. 状态持久化：原生支持检查点机制。
4. 流式输出：可以在任何节点实时推送消息。

代码示例：

```python
# LangGraph 的优势：清晰的条件路由
workflow.add_conditional_edges(
    "review",
    self._should_revise,  # 自定义路由函数
    {
        "revise": "revise",          # 仅文字修订
        "re_research": "research",   # 需要补充搜索
        "complete": END              # 通过审核，结束
    }
)
```

文件位置：`/backend/app/service/deep_research_v2/graph.py`（行号：220-227）

### 2.2 为什么混合使用 DeepSeek 和 Qwen？

模型性能对比：

| 维度 | DeepSeek V3.2 | Qwen Plus | GPT |
| --- | --- | --- | --- |
| 推理能力 | ★★★★★ | ★★★★ | ★★★★★ |
| 中文能力 | ★★★★★ | ★★★★★ | ★★★★ |
| 响应速度 | ★★★ | ★★★★★ | ★★★ |
| JSON 模式 | ★★★★★ | ★★★★ | ★★★★★ |
| 成本 | ¥0.001 / 1K tokens | ¥0.0004 / 1K tokens | ¥0.07 / 1K tokens |

我们的策略：

1. DeepSeek V3.2 用于重推理任务：
   - ChiefArchitect：需要深度理解用户问题，规划大纲。
   - CodeWizard：需要生成正确的 Python 代码。
   - LeadWriter：需要专业的写作能力。
   - CriticMaster：需要批判性思维。
2. Qwen Plus 用于快速任务：
   - DeepScout：搜索阶段信息提取，速度优先。
   - 简单的信息查询和格式转换。

成本节约：

假设一次研究调用：

- Architect：4K tokens × 1 次 = 4K
- Scout：4K tokens × 6 次 = 24K（使用 Qwen Plus）
- Wizard：8K tokens × 2 次 = 16K
- Writer：16K tokens × 1 次 = 16K
- Critic：4K tokens × 1 次 = 4K

总计：`(4K + 16K + 16K + 4K) × ¥0.001 + 24K × ¥0.0004 = ¥0.0496`

如果全用 GPT-5：`64K × ¥0.07 = ¥4.48`

节省 90% 成本。

文件位置：`/backend/app/config/llm_config.py`（行号：37-81）

### 2.3 为什么选择 Milvus 而非 Pinecone？

对比分析：

| 特性 | Milvus | Pinecone | Weaviate |
| --- | --- | --- | --- |
| 开源 | 是 | 否 | 是 |
| 部署方式 | 自托管 | SaaS | 自托管 / SaaS |
| 成本 | 免费 | $70 / 月起 | 免费（限额） |
| 性能 | 优秀（GPU 加速） | 优秀 | 良好 |
| 向量维度 | 无限制 | 20,000 维 | 65,536 维 |
| 中文支持 | ★★★★★ | ★★★ | ★★★★ |

我们的选择：Milvus

原因：

1. 成本控制：完全免费，数据存储在自己服务器。
2. 性能优秀：支持 GPU 加速，百万级向量检索 `<100ms`。
3. 功能丰富：支持混合检索（向量 + 标量过滤）。
4. 社区活跃：中国开源项目，中文文档完善。

使用示例：

```python
# Milvus 混合检索（向量相似度 + 元数据过滤）
results = milvus_collection.search(
    data=[query_vector],
    anns_field="embedding",
    param={"metric_type": "COSINE", "params": {"nlist": 128}},
    limit=10,
    expr='kb_id == 123 and doc_type == "pdf"'  # 标量过滤
)
```

文件位置：`/backend/app/service/milvus_service.py`（行号：100-150）

### 2.4 为什么选择 FastAPI 而非 Django？

对比分析：

| 特性 | FastAPI | Django | Flask |
| --- | --- | --- | --- |
| 性能 | ★★★★★（异步） | ★★★ | ★★★★ |
| 异步支持 | 原生支持 | 3.1+ 支持（不完善） | 需扩展 |
| 类型检查 | Pydantic 自动 | 需手动 | 需手动 |
| 文档生成 | 自动（Swagger） | 需手动 | 需插件 |
| 学习曲线 | 平缓 | 陡峭 | 平缓 |
| 生态成熟度 | 快速增长 | 非常成熟 | 成熟 |

我们的选择：FastAPI

原因：

1. 异步优先：LLM 调用、搜索 API、数据库查询都是 IO 密集型，异步能显著提升性能。
2. 自动文档：Swagger UI 开箱即用，方便前后端联调。
3. 类型安全：Pydantic 自动验证，减少运行时错误。
4. SSE 支持：原生支持流式响应，完美适配实时进度推送。

性能示例：

```python
# FastAPI 异步处理
@router.post("/research/start")
async def start_research(request: ResearchRequest):
    # 并发调用多个服务
    results = await asyncio.gather(
        llm_service.call(prompt),
        search_service.search(query),
        db_service.query(sql)
    )
    return results
```

对比 Django 同步处理：

```python
# Django 同步处理（阻塞）
@api_view(["POST"])
def start_research(request):
    result1 = llm_service.call(prompt)       # 阻塞 1 秒
    result2 = search_service.search(query)   # 阻塞 1 秒
    result3 = db_service.query(sql)          # 阻塞 1 秒
    return results                           # 总耗时 3 秒
```

FastAPI 异步版本只需 1 秒。

### 2.5 为什么使用 ECharts 而非 D3.js？

对比分析：

| 特性 | ECharts | Chart.js | D3.js |
| --- | --- | --- | --- |
| 上手难度 | 简单 | 简单 | 困难 |
| 图表类型 | 50+ | 8 种 | 无限（自己画） |
| 交互性 | 强 | 中 | 强 |
| 中文文档 | ★★★★★ | ★★★ | ★★★ |
| 移动端适配 | 优秀 | 良好 | 需手动 |
| 数据量 | 百万级 | 万级 | 百万级 |

我们的选择：ECharts

原因：

1. 配置式开发：LLM 直接生成 JSON 配置，无需写绘图代码。
2. 图表丰富：支持桑基图、关系图、地图等高级图表。
3. 性能优秀：Canvas 渲染，支持大数据量。
4. 响应式：自动适配移动端。

LLM 生成 ECharts 配置示例：

```json
{
  "title": {"text": "市场规模趋势"},
  "xAxis": {"type": "category", "data": ["2020", "2021", "2022"]},
  "yAxis": {"type": "value"},
  "series": [{
    "type": "line",
    "data": [3200, 4100, 5200],
    "smooth": true
  }]
}
```

前端直接渲染，无需额外处理。

Prompt 位置：`/backend/app/service/deep_research_v2/agents/data_analyst.py`（行号：143-242）

## 三、架构设计决策

### 3.1 为什么采用多智能体而非单一 Agent？

单一 Agent 的问题：

```text
用户问题 -> 超长 Prompt（包含所有任务） -> LLM -> 一次性输出所有内容

问题：
1. Prompt 过长，超出上下文窗口
2. LLM 容易遗漏细节
3. 难以质量把控
4. 无法并行处理
5. 出错后全部重来
```

多智能体的优势：

```text
用户问题 -> 拆解任务 -> 6 个专业 Agent 分工
                         |
Architect：规划大纲（专注规划，Prompt 精简）
                         |
Scout：并行搜索 6 个章节（专注搜索，可并发）
                         |
DataAnalyst：提取数据（专注数据，准确率高）
                         |
Wizard：生成图表（专注代码，有沙箱保护）
                         |
Writer：撰写报告（专注写作，文风统一）
                         |
Critic：审核修订（专注审核，对抗式检查）

优势：
1. 每个 Agent Prompt 简洁，效果更好
2. 可以针对性选择模型（快速模型 vs 强推理模型）
3. 出错后只需重试特定 Agent
4. 支持并行处理（如搜索阶段）
5. 容易扩展新功能（新增 Agent 即可）
```

### 3.2 为什么使用检查点而非直接重新执行？

没有检查点的问题：

```text
用户研究进行到 80% -> 网络断开 -> 从头开始

问题：
1. 浪费已消耗的 LLM tokens
2. 用户体验差（30 分钟白等）
3. 重复调用搜索 API（浪费配额）
```

检查点的优势：

```text
研究过程中自动保存状态：
- Planning 完成 -> 保存检查点 1（大纲已生成）
- Researching 完成 -> 保存检查点 2（facts 已收集）
- Analyzing 完成 -> 保存检查点 3（图表已生成）
- Writing 完成 -> 保存检查点 4（报告已撰写）

如果中断，从最近检查点恢复：
- 已完成的工作不丢失
- 只需重做未完成部分
- 支持用户主动取消后继续

优势：
1. 节省成本（不重复调用 LLM / 搜索 API）
2. 体验友好（支持暂停 / 继续）
3. 容错性强（网络故障自动恢复）
```

文件位置：`/backend/app/service/checkpoint_service.py`

### 3.3 为什么采用 SSE 而非 WebSocket？

对比分析：

| 特性 | SSE | WebSocket |
| --- | --- | --- |
| 通信方向 | 服务器 -> 客户端（单向） | 双向 |
| 协议 | HTTP | WS（需升级） |
| 自动重连 | 浏览器原生支持 | 需手动实现 |
| 实现复杂度 | 简单 | 中等 |
| 适用场景 | 实时推送、日志流 | 聊天、游戏 |

我们的选择：SSE

原因：

1. 单向通信足够：研究过程只需服务器推送进度，客户端不需要频繁发送消息。
2. 实现简单：后端只需 `yield`，前端用 `EventSource` 即可。
3. 自动重连：浏览器断线自动重连，无需手动处理。
4. HTTP 友好：不需要额外的 WS 代理配置。

SSE 代码示例：

```python
# 后端：FastAPI SSE
async def event_generator():
    for i in range(10):
        yield f"data: {json.dumps({'progress': i * 10})}\n\n"
        await asyncio.sleep(1)

@router.get("/stream")
async def stream():
    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream"
    )
```

```javascript
// 前端：EventSource
const eventSource = new EventSource('/api/stream');
eventSource.onmessage = (e) => {
  const data = JSON.parse(e.data);
  updateProgress(data.progress);
};
```

文件位置：`/backend/app/router/research_router.py`（行号：50-120）

### 3.4 为什么代码执行只给 CodeWizard？

安全考虑：

如果所有 Agent 都能执行代码，风险太大：

```text
坏情况：
Scout 生成恶意搜索代码 -> 窃取环境变量
Writer 生成文件操作代码 -> 删除重要文件
Critic 生成网络请求代码 -> SSRF 攻击
```

我们的设计：

```text
只有 CodeWizard 能执行代码，且有严格的沙箱限制：
✅ 白名单模块：pandas, numpy, matplotlib（数据分析安全）
❌ 禁止模块：os, sys, subprocess, requests（危险操作）
✅ 隔离环境：独立的全局作用域，不能访问真实文件系统
✅ 自愈机制：代码执行失败后，LLM 自动修复（最多 3 次）
✅ 输出限制：只能生成图表，不能执行其他操作
```

文件位置：`/backend/app/service/deep_research_v2/agents/wizard.py`（行号：299-339，1074-1302）

### 3.5 为什么采用假设驱动研究？

传统关键词搜索的问题：

```text
用户问题："AI 行业分析"
-> 关键词搜索：["AI", "人工智能", "市场规模"]
-> 信息堆砌：找到什么就写什么，缺乏主线

问题：
1. 研究方向不明确
2. 容易遗漏关键词问题
3. 信息碎片化，缺乏逻辑
```

假设驱动的优势：

```text
用户问题："AI 行业分析"
-> Architect 生成假设：
   H1: "AI 市场将保持高增长"
   H2: "LLM 是最大细分领域"
   H3: "政策支持是关键驱动力"
-> Scout 验证假设：
   搜索时寻找证据支持 / 反驳假设
   标注每个事实对假设的支撑程度
-> 动态调整：
   H1 被验证 -> 深入挖掘增长数据
   H2 被否定 -> 调整研究重点

优势：
1. 研究有明确方向
2. 信息收集更有针对性
3. 报告逻辑更严密（假设 -> 验证 -> 结论）
4. 支持动态调整研究路径
```

文件位置：`/backend/app/service/deep_research_v2/agents/architect.py`（行号：136-154）

## 四、数据库设计决策

### 4.1 为什么 PostgreSQL 而非 MySQL？

对比分析：

| 特性 | PostgreSQL | MySQL |
| --- | --- | --- |
| JSONB | 原生支持，可索引 | JSON 支持弱 |
| 全文检索 | 内置（tsvector） | 需插件 |
| 窗口函数 | 完整支持 | 8.0+ 支持 |
| 并发性能 | MVCC，无锁读 | 表锁 / 行锁 |
| 扩展性 | 丰富（PostGIS、pg_vector） | 较少 |

我们的选择：PostgreSQL

原因：

1. JSONB 支持：状态对象、检查点数据都存储为 JSONB，方便查询和索引。
2. 全文检索：新闻标题和摘要的中文检索。
3. 窗口函数：复杂的数据分析查询。
4. pg_vector 扩展：未来可能集成向量检索到 PostgreSQL。

JSONB 使用示例：

```sql
-- 存储检查点数据
CREATE TABLE checkpoints (
    session_id VARCHAR(50) PRIMARY KEY,
    state JSONB,   -- 完整的 ResearchState 对象
    ui_state JSONB, -- 前端 UI 状态
    created_at TIMESTAMP DEFAULT NOW()
);

-- JSONB 查询示例
SELECT * FROM checkpoints
WHERE state->>'phase' = 'writing'
  AND (state->>'quality_score')::float > 7.0;

-- JSONB 索引
CREATE INDEX idx_checkpoint_phase ON checkpoints ((state->>'phase'));
```

文件位置：`/backend/app/models/research.py`

### 4.2 为什么向量数据库和关系数据库分离？

混合存储的理由：

```text
Milvus（向量数据库）：
✅ 专注：高效的向量检索
✅ 性能：百万级向量 <100ms
✅ 索引：HNSW、IVF 等专业算法
❌ 关系查询：不支持 JOIN、WHERE 复杂条件

PostgreSQL（关系数据库）：
✅ 专注：结构化数据的复杂查询
✅ 事务：ACID 保证数据一致性
✅ JOIN：多表关联查询
❌ 向量检索：即使用 pg_vector，性能也不如 Milvus

所以采用混合架构：
- Milvus 存储向量和简单元数据（kb_id、doc_id、chunk_index）
- PostgreSQL 存储复杂元数据（用户信息、文档详情、权限）
- 检索时：Milvus 返回 doc_id 列表 -> PostgreSQL JOIN 详情
```

示例查询：

```python
# 1. Milvus 检索相似文档块
similar_chunks = milvus.search(query_vector, top_k=10)
doc_ids = [chunk["doc_id"] for chunk in similar_chunks]

# 2. PostgreSQL 获取文档详情
docs = db.execute(
    "SELECT * FROM documents WHERE id IN %s",
    (tuple(doc_ids),)
).fetchall()

# 3. 合并结果
results = []
for chunk in similar_chunks:
    doc = next(d for d in docs if d["id"] == chunk["doc_id"])
    results.append({
        "content": chunk["content"],
        "score": chunk["score"],
        "filename": doc["filename"],
        "upload_time": doc["uploaded_at"]
    })
```

## 五、安全设计决策

### 5.1 为什么使用 JWT 而非 Session？

对比分析：

| 特性 | JWT | Session |
| --- | --- | --- |
| 存储位置 | 客户端（localStorage） | 服务器（内存 / Redis） |
| 扩展性 | 无状态，易扩展 | 有状态，需共享 Session |
| 安全性 | 需防 XSS（不能用 Cookie） | 需防 CSRF |
| 性能 | 无需查询数据库 | 每次请求查 Redis |

我们的选择：JWT

原因：

1. 无状态：适合分布式部署，不需要 Session 共享。
2. 性能：不需要每次请求查 Redis 验证 Session。
3. 简单：前端只需在请求头加入授权凭据。

Session（会话）：

Session 是服务器端的用户状态管理机制。

工作流程：

1. 用户登录成功后，服务器生成一个唯一的 Session ID。
2. 服务器把用户信息存在内存 / Redis 中，与 Session ID 关联。
3. 把 Session ID 通过 Cookie 发给浏览器。
4. 之后每次请求，浏览器自动带上 Cookie，服务器通过 Session ID 查找用户信息。

问题：服务器需要存储所有用户的 Session，多台服务器时需要共享（通常用 Redis）。

XSS（跨站脚本攻击）：

XSS 是一种安全漏洞，攻击者把恶意 JavaScript 代码注入到网页中，窃取用户数据。

为什么 JWT 需要防 XSS：

- JWT 通常存在 `localStorage`。
- 如果网站有 XSS 漏洞，攻击者可以用 JavaScript 读取本地存储，偷走访问凭据。

防护方法：

- 对用户输入进行转义，不直接渲染 HTML。
- 使用 `HttpOnly Cookie` 存储访问凭据（JavaScript 无法读取）。
- 设置 Content Security Policy（CSP）。

安全措施：

```python
# 1. 使用强密钥
SECRET_KEY = os.getenv("JWT_SECRET", "<strong-random-key-256-bits>")

# 2. 设置过期时间
payload = {
    "sub": user.id,
    "exp": datetime.utcnow() + timedelta(days=7)
}

# 3. 使用 HS256 算法
jwt_value = jwt.encode(payload, SECRET_KEY, algorithm="HS256")

# 4. 前端存储在 HttpOnly Cookie（防 XSS）
response.set_cookie(
    "access_jwt",
    jwt_value,
    httponly=True,  # JS 无法访问
    secure=True,    # 只在 HTTPS 传输
    samesite="strict"  # 防 CSRF
)
```

文件位置：`/backend/app/core/security.py`

### 5.2 为什么需要代码沙箱？

没有沙箱的风险：

```text
恶意 Prompt 攻击：
用户输入："生成一个删除所有文件的 Python 脚本"

LLM 生成代码：
import os
import shutil
shutil.rmtree("/")  # 删除根目录

执行后 -> 服务器被摧毁
```

沙箱防护：

```python
# 1. 禁止危险模块
FORBIDDEN_PATTERNS = [
    r'\bimport\s+os\b',
    r'\bimport\s+subprocess\b',
    r'\bopen\s*\(',
]

# 2. 白名单执行环境
exec_globals = {
    "__builtins__": {
        "print": print,  # 只允许安全函数
        "len": len,
        # ... 其他安全函数
    },
    "pd": pandas,  # 预导入安全模块
    "np": numpy,
}

# 3. 隔离文件系统
# 沙箱中的代码无法访问真实文件
# plt.savefig() 保存到内存 Buffer，而非磁盘
```

文件位置：`/backend/app/service/deep_research_v2/agents/wizard.py`（行号：299-339，1074-1084）

## 六、性能优化决策

### 6.1 为什么使用异步而非多线程？

Python 并发模型对比：

| 模型 | 适用场景 | 性能 | 复杂度 |
| --- | --- | --- | --- |
| 同步 | 简单任务 | 低 | 低 |
| 多线程 | CPU 密集 | GIL 限制（伪并发） | 中 |
| 多进程 | CPU 密集 | 高（真并发） | 高 |
| 异步 | IO 密集 | 高 | 中 |

我们的选择：异步（asyncio）

原因：

1. IO 密集型：LLM 调用、搜索 API、数据库查询都是等待网络响应。
2. 无 GIL 限制：异步在单线程运行，没有 GIL 性能瓶颈。
3. 资源节省：不需要创建大量线程 / 进程。
4. FastAPI 原生支持：框架级优化。

```text
IO 密集型任务：大部分时间在「等待」

| 发请求 |████| 等待网络响应... |████| 处理 |
             ↑
        CPU 闲着没事干，在干等

CPU 密集型任务：大部分时间在「计算」

|████████ 疯狂计算中... ████████|
             ↑
        CPU 满负荷运转

多线程在 Python 里无法利用多核 CPU 并行计算。异步没有 GIL 的问题。
理想中的多线程（4 核 CPU）：
线程1: ████████
线程2: ████████  -> 4 倍速度
线程3: ████████
线程4: ████████

Python 多线程的现实（因为 GIL）：
线程1: ██    ██    ██
线程2:   ██    ██    ██  -> 还是 1 倍速度，轮流执行
线程3:     ██    ██
```

性能对比：

```python
# 同步版本：3 秒
def sync_research():
    result1 = call_llm()   # 1 秒
    result2 = search_api() # 1 秒
    result3 = query_db()   # 1 秒
    return [result1, result2, result3]

# 异步版本：1 秒
async def async_research():
    results = await asyncio.gather(
        call_llm(),
        search_api(),
        query_db()
    )
    return results
```

### 6.2 为什么缓存搜索结果？

缓存收益分析：

```text
相同问题重复研究：
无缓存：Bocha API 调用 30 次 × ¥0.01 = ¥0.3
有缓存：第一次 ¥0.3，后续 ¥0（命中缓存）

缓存策略：
- Key: MD5(query)
- TTL: 15 分钟（搜索结果时效性）
- 存储：Redis（快速读取）
```

缓存实现：

```python
async def _execute_search(self, query: str) -> List[Dict]:
    # 检查缓存
    cache_key = hashlib.md5(query.encode()).hexdigest()
    if cache_key in self.search_cache:
        logger.debug(f"Cache hit for: {query}")
        return self.search_cache[cache_key]

    # 调用 API
    results = await bocha_api.search(query)

    # 保存缓存
    self.search_cache[cache_key] = results
    return results
```

文件位置：`/backend/app/service/deep_research_v2/agents/scout.py`（行号：1057-1115）

## 七、可扩展性设计

### 7.1 如何扩展新的 Agent？

设计原则：开闭原则（OCP）- 添加新功能时，应该通过新增代码实现，而不是修改现有代码。

```python
# 1. 继承 BaseAgent 基类
class NewAgent(BaseAgent):
    def __init__(self, llm_credential, llm_base_url, model):
        super().__init__(
            name="NewAgent",
            role="新角色",
            llm_credential=llm_credential,
            llm_base_url=llm_base_url,
            model=model
        )

    async def process(self, state: ResearchState) -> ResearchState:
        # 实现自己的逻辑
        self.add_message(state, "thought", {
            "agent": self.name,
            "content": "正在执行新任务..."
        })
        # ... 你的代码
        return state

# 2. 在 Graph 中注册
class DeepResearchGraph:
    def __init__(self, ...):
        # 实例化新 Agent
        self.new_agent = NewAgent(...)

    def _build_langgraph(self):
        # 添加新节点
        workflow.add_node("new_task", self._new_task_node)
        # 设置边
        workflow.add_edge("analyze", "new_task")
        workflow.add_edge("new_task", "write")
```

### 7.2 如何扩展新的数据源？

示例：添加 Twitter 搜索。

```python
# 在 DeepScout 中新增方法
class DeepScout(BaseAgent):
    async def _execute_twitter_search(self, query: str) -> List[Dict]:
        # 调用 Twitter API
        tweets = await twitter_api.search(query, count=10)

        # 格式化为统一结构
        results = []
        for tweet in tweets:
            results.append({
                "url": tweet.url,
                "title": f"@{tweet.user} 推文",
                "summary": tweet.text,
                "site_name": "Twitter",
                "date": tweet.created_at
            })
        return results

    async def _research_section(self, state, section):
        # 原有的 Bocha 搜索
        web_results = await self._execute_search(query)

        # 新增的 Twitter 搜索
        if state.get("search_twitter"):
            twitter_results = await self._execute_twitter_search(query)
            web_results.extend(twitter_results)

        # 后续分析逻辑不变
        ...
```

### 7.3 如何支持新的图表类型？

示例：添加词云图。

```python
# 在 CodeWizard 中新增 Prompt
class CodeWizard(BaseAgent):
    WORDCLOUD_PROMPT = """生成词云图代码...

要求：
1. 使用 wordcloud 和 jieba 库
2. 中文分词
3. 停用词过滤

输出 JSON:
{"code": "...", "chart_description": "..."}
"""

    async def generate_wordcloud(self, text: str) -> Dict:
        prompt = self.WORDCLOUD_PROMPT.format(text=text)
        response = await self.call_llm(prompt, json_mode=True)
        result = self.parse_json_response(response)

        # 执行代码生成词云
        execution_result = await self._execute_code(result["code"])
        return execution_result
```

## 八、常见问题

Q1：为什么不用 LangChain 而用 LangGraph？

A：LangChain 是工具集合，LangGraph 是编排框架。我们需要的是清晰的状态机编排，不是工具链接。LangGraph 提供了更好的可控性和可视化。

Q2：为什么不全用开源 LLM（如 Llama）？

A：开源 LLM 部署成本高（需 GPU 服务器），维护复杂（模型更新、优化）。闭源 API 按需付费，更灵活，且 DeepSeek 性价比已经很高。

Q3：能否支持离线部署？

A：可以，但需要替换组件：

- LLM：部署本地 Llama / Qwen 模型。
- 搜索：爬取数据建立本地索引。
- 嵌入：部署本地 BGE 模型。

Q4：多用户并发性能如何？

A：单机支持 200-300 并发研究（取决于服务器配置）。如需更高并发：

1. 使用消息队列（Celery）异步处理。
2. 水平扩展多个 Worker 节点。
3. 使用负载均衡分发请求。

## 九、技术债与未来改进

### 9.1 当前限制

1. LLM 成本：单次研究约 ¥0.05，大规模使用成本仍较高。
2. 搜索配额：Bocha API 有调用限制。
3. 单机部署：未实现分布式，可以进一步提升并发。
4. 代码沙箱：进一步建议用 Docker 容器隔离。

### 9.2 改进方向

1. 混合搜索：结合本地缓存和实时搜索，减少 API 调用。
2. 增量研究：支持在已有报告基础上补充研究。
3. 多模态：支持图片、视频等非文本数据分析。
4. 协作研究：多用户共同研究一个问题。

## 十、总结

本项目的技术选型遵循以下原则：

1. 性价比优先：在满足需求前提下，选择成本最低方案。
2. 可控性优先：开源 > 闭源，状态机 > 黑盒框架。
3. 实用性优先：够用即可，不过度设计。
4. 可扩展性优先：模块化设计，易于扩展新功能。

通过合理的技术选型，我们实现了一个高质量、低成本、易维护的多智能体 AI 研究系统。

## 相关章节

- [2.1 LangGraph 状态机基础]
- [3.1 Docker 容器化部署]
