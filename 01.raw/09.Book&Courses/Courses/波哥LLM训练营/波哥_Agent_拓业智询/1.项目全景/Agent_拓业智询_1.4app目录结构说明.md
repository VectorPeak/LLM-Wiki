# 1.4 app目录结构说明

> 本节目标：理解 Backend 应用的整体目录组织，掌握各模块的职责划分
>
> 适合人群：新手开发者、代码维护者
>
> 阅读时长：10 分钟

## 1. 目录树概览

```text
backend/app/
├── config/                 # 配置文件模块
├── core/                   # 核心工具模块
├── models/                 # 数据库模型（ORM）
├── router/                 # API 路由层（Controller）
├── schemas/                # 请求/响应模式（DTO）
├── scripts/                # 工具脚本
├── service/                # 业务逻辑层（Service）
│   └── deep_research_v2/   # 多智能体研究系统
│       └── agents/         # 各个 Agent 实现
└── app_main.py             # FastAPI 应用入口
```

## 2. 各目录详细说明

### 2.1 `config/` - 配置文件模块

作用：集中管理项目所有配置项，避免硬编码。

关键文件：

| 文件 | 大小 | 作用 |
| --- | ---: | --- |
| `llm_config.py` | 6KB | LLM 模型配置（DeepSeek、通义千问）、Agent 配置 |
| `industry_config.py` | 4.5KB | 行业数据配置（行业分类、股票映射） |
| `stock_mapping.py` | 3.7KB | 股票代码与公司名称映射表 |

示例代码：

```python
# /backend/app/config/llm_config.py
from enum import Enum


class LLMProvider(str, Enum):
    """LLM 提供商枚举"""

    DEEPSEEK = "deepseek"
    QWEN = "qwen"


class LLMConfig:
    """LLM 配置类"""

    DEFAULT_MODEL = {
        "provider": LLMProvider.DEEPSEEK,
        "model_name": "deepseek-chat",
        "temperature": 0.7,
        "max_tokens": 4000,
    }

    AGENT_MODELS = {
        "architect": {"temperature": 0.3},  # 规划师需要稳定输出
        "scout": {"temperature": 0.5},      # 侦察器需要一定创造性
        "wizard": {"temperature": 0.1},     # 代码生成需要更精确
    }
```

设计亮点：

- 环境变量隔离（开发 / 测试 / 生产）
- 类型安全（使用 `Enum`）
- 分层配置（全局默认 -> Agent 覆盖）

### 2.2 `core/` - 核心工具模块

作用：提供底层基础设施的初始化和管理。

关键文件：

| 文件 | 大小 | 核心类/函数 |
| --- | ---: | --- |
| `database.py` | 929B | `engine`、`SessionLocal`、`get_db()` |
| `redis_client.py` | 3.1KB | `RedisClient` 单例类 |
| `security.py` | 1.9KB | `get_password_hash()`、`verify_token()` |

示例代码：

```python
# /backend/app/core/database.py
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:password@localhost:5432/industry_db",
)

engine = create_engine(
    DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

Base = declarative_base()


def get_db():
    """依赖注入：获取数据库会话"""

    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

设计亮点：

- 连接池管理，避免频繁创建连接
- 依赖注入模式，便于 FastAPI 集成
- 单例模式（Redis 客户端）

### 2.3 `models/` - 数据库模型（ORM）

作用：定义所有数据库表的结构，使用 SQLAlchemy ORM。

关键文件：

| 文件 | 大小 | 对应表 | 核心字段 |
| --- | ---: | --- | --- |
| `user.py` | 1.2KB | `users` | `id`、`username`、`password_hash` |
| `chat.py` | 4KB | `chat_sessions`、`chat_messages`、`long_term_memory` | `session_id`、`content`、`metadata` |
| `knowledge.py` | 2KB | `knowledge_bases`、`knowledge_chunks` | `kb_id`、`chunk_text`、`vector_id` |
| `research.py` | 2.3KB | `research_tasks` | `task_id`、`state`、`checkpoint` |
| `industry_data.py` | 5KB | `stock_data`、`financial_metrics` | `stock_code`、`revenue`、`profit` |
| `news.py` | 4.9KB | `news_articles` | `title`、`content`、`publish_date` |

示例代码：

```python
# /backend/app/models/chat.py
from datetime import datetime
from sqlalchemy import Column, DateTime, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB

from app.core.database import Base


class ChatSession(Base):
    """聊天会话表"""

    __tablename__ = "chat_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    title = Column(String(200))
    created_at = Column(DateTime, default=datetime.utcnow)
    metadata = Column(JSONB, default={})


class LongTermMemory(Base):
    """长期记忆表"""

    __tablename__ = "long_term_memory"

    id = Column(Integer, primary_key=True)
    session_id = Column(Integer, index=True)
    summary = Column(Text)                 # LLM 压缩后的摘要
    vector_id = Column(String(100))       # Milvus 向量 ID
    token_count = Column(Integer)         # 原始对话 token 数
    compression_ratio = Column(Integer)   # 压缩比（如 96）
    created_at = Column(DateTime, default=datetime.utcnow)
```

设计亮点：

- `JSONB` 灵活字段（PostgreSQL 特性）
- 索引优化（`user_id`、`session_id`）
- 外键关联（Session -> Messages）

### 2.4 `router/` - API 路由层

作用：定义所有 HTTP 接口，处理请求/响应，调用 Service 层业务逻辑。前端一个行为对应后端什么操作，主要就在这一层。

关键文件：

| 文件 | 大小 | 路由前缀 | 核心接口 |
| --- | ---: | --- | --- |
| `auth_router.py` | 6.4KB | `/auth` | `/login`、`/register` |
| `chat_router.py` | 11KB | `/chat` | `/send`、`/history` |
| `research_router.py` | 18KB | `/research` | `/start`、`/status`、`/stream` |
| `knowledge_router.py` | 15KB | `/knowledge` | `/upload`、`/query`、`/delete` |
| `database_router.py` | 7.6KB | `/database` | `/query`、`/schema` |
| `memory_router.py` | 7.5KB | `/memory` | `/list`、`/search` |
| `news_router.py` | 7.3KB | `/news` | `/latest`、`/search` |

示例代码：

```python
# /backend/app/router/research_router.py（简化版）
from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.research import ResearchStartRequest, ResearchStatusResponse
from app.service.deep_research_v2.service import DeepResearchService

router = APIRouter(prefix="/research", tags=["深度研究"])


@router.post("/start", response_model=ResearchStatusResponse)
async def start_research(
    request: ResearchStartRequest,
    db: Session = Depends(get_db),
):
    """启动深度研究任务"""

    service = DeepResearchService(db)
    task_id = await service.start_research(
        query=request.query,
        industry=request.industry,
    )
    return {"task_id": task_id, "status": "pending"}


@router.get("/stream/{task_id}")
async def stream_research(task_id: str, db: Session = Depends(get_db)):
    """SSE 流式返回研究进度"""

    service = DeepResearchService(db)

    async def event_generator():
        async for event in service.stream_research(task_id):
            yield f"data: {event}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
    )
```

设计亮点：

- 依赖注入（数据库 Session、认证）
- 统一异常处理
- SSE 流式响应

### 2.5 `schemas/` - 请求/响应模式

作用：使用 Pydantic 定义数据传输对象（DTO），实现自动校验和文档生成。

关键文件：

| 文件 | 大小 | 定义的 Schema |
| --- | ---: | --- |
| `user.py` | 1.3KB | `UserRegister`、`UserLogin`、`UserResponse` |
| `chat.py` | 5.2KB | `ChatMessage`、`ChatHistory`、`MessageResponse` |
| `knowledge.py` | 2.6KB | `KnowledgeUpload`、`KnowledgeQuery`、`KnowledgeChunk` |
| `search.py` | 1.3KB | `SearchRequest`、`SearchResult` |
| `document.py` | 1.5KB | `DocumentUpload`、`DocumentMetadata` |

示例代码：

```python
# /backend/app/schemas/chat.py
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, validator


class ChatMessage(BaseModel):
    """发送消息请求"""

    session_id: int = Field(..., description="会话ID")
    content: str = Field(
        ...,
        min_length=1,
        max_length=5000,
        description="消息内容",
    )

    @validator("content")
    def validate_content(cls, value: str):
        if not value.strip():
            raise ValueError("消息内容不能为空")
        return value.strip()


class MessageResponse(BaseModel):
    """消息响应"""

    id: int
    role: str  # "user" / "assistant"
    content: str
    created_at: datetime

    class Config:
        orm_mode = True
```

设计亮点：

- 自动校验（`min_length`、`max_length`）
- 自定义验证器（`@validator`）
- ORM 模式转换（直接从数据库模型生成）

### 2.6 `scripts/` - 工具脚本

作用：数据初始化、测试、迁移等一次性任务。

关键文件：

| 文件 | 大小 | 作用 |
| --- | ---: | --- |
| `init_industry_data.py` | 8KB | 初始化行业基础数据 |
| `seed_industry_data.py` | 18KB | 批量导入股票 / 财报数据 |
| `test_deep_research_v2.py` | 10KB | 深度研究系统端到端测试 |

示例代码：

```python
# /backend/app/scripts/seed_industry_data.py（简化版）
import asyncio
from sqlalchemy.orm import Session

from app.core.database import SessionLocal, engine
from app.models import Base
from app.models.industry_data import StockData


async def seed_stock_data(db: Session):
    """批量导入股票数据"""

    stock_list = [
        {"code": "600519", "name": "贵州茅台", "industry": "白酒"},
        {"code": "000858", "name": "五粮液", "industry": "白酒"},
    ]

    for stock in stock_list:
        db.add(StockData(**stock))

    db.commit()
    print(f"已成功导入 {len(stock_list)} 只股票")


if __name__ == "__main__":
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        asyncio.run(seed_stock_data(db))
    finally:
        db.close()
```

使用方法：

```bash
# 初始化数据
python -m app.scripts.seed_industry_data

# 运行测试
python -m app.scripts.test_deep_research_v2
```

### 2.7 `service/` - 业务逻辑层

作用：实现核心业务逻辑，调用外部 API、数据库、AI 模型等。

关键文件：

| 文件 | 大小 | 核心功能 |
| --- | ---: | --- |
| `chat_service.py` | 15.7KB | 聊天消息处理、上下文管理 |
| `memory_service.py` | 16.2KB | 长期记忆压缩、向量检索 |
| `milvus_service.py` | 8.9KB | 向量数据库操作 |
| `text2sql_service.py` | 19KB | Text 转 SQL、Schema 感知 |
| `checkpoint_service.py` | 11KB | 检查点保存 / 恢复 |
| `scheduler_service.py` | - | APScheduler 定时任务 |
| `news_collection_service.py` | 26KB | 资讯采集、去重 |
| `chart_generator.py` | 14.7KB | 图表生成、可视化 |
| `database_explorer.py` | 7.8KB | 数据库 Schema 探索 |

特殊子目录：`/service/deep_research_v2/`

这是整个项目里最核心的模块，实现了 6 个 Agent 的协作流程：

```text
service/deep_research_v2/
├── graph.py        # LangGraph 状态机编排（792行）
├── state.py        # ResearchState 状态定义（155行）
├── service.py      # 服务入口（6.3KB）
└── agents/
    ├── base.py         # Agent 基类（10KB）
    ├── architect.py    # 规划师（13.7KB）
    ├── scout.py        # 深度侦探（53KB，最复杂）
    ├── data_analyst.py # 数据分析师（16.8KB）
    ├── wizard.py       # 代码魔法师（52KB）
    ├── writer.py       # 首席笔杆（17KB）
    └── critic.py       # 评论家（13.9KB）
```

示例代码：

```python
# /backend/app/service/deep_research_v2/service.py（简化版）
from sqlalchemy.orm import Session

from app.service.deep_research_v2.graph import DeepResearchGraph
from app.service.deep_research_v2.state import ResearchState


class DeepResearchService:
    """深度研究服务入口"""

    def __init__(self, db: Session):
        self.db = db
        self.graph = DeepResearchGraph()

    async def start_research(self, query: str, industry: str) -> str:
        """启动研究任务"""

        initial_state = ResearchState(
            query=query,
            industry=industry,
            step=0,
            max_steps=10,
        )

        final_state = await self.graph.run(initial_state)
        return final_state.task_id
```

设计亮点：

- 分层解耦（Service -> Graph -> Agents）
- 状态持久化（检查点机制）
- 异步流式（SSE 实时推送）

### 2.8 `app_main.py` - FastAPI 应用入口

文件：`/backend/app/app_main.py`

作用：

- 初始化 FastAPI 应用
- 注册所有 Router
- 配置 CORS、中间件
- 启动定时任务

核心代码：

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.router import (
    auth_router,
    chat_router,
    database_router,
    knowledge_router,
    memory_router,
    news_router,
    research_router,
)
from app.service.scheduler_service import start_scheduler

app = FastAPI(
    title="Industry Information Assistant",
    version="2.0.0",
    description="基于多智能体的行业信息助手",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router.router)
app.include_router(chat_router.router)
app.include_router(research_router.router)
app.include_router(knowledge_router.router)
app.include_router(database_router.router)
app.include_router(memory_router.router)
app.include_router(news_router.router)


@app.on_event("startup")
async def startup_event():
    """应用启动时执行"""

    print("启动定时任务调度器...")
    start_scheduler()
    print("应用启动成功")


@app.get("/health")
async def health_check():
    return {"status": "ok"}
```

## 3. 目录职责总结

### 3.1 模块职责与依赖关系

| 目录 | 职责 | 依赖方向 | 核心技术 |
| --- | --- | --- | --- |
| `config` | 配置管理 | 被所有模块依赖 | Enum、环境变量 |
| `core` | 基础设施 | 被 `models/service` 依赖 | SQLAlchemy、Redis |
| `models` | 数据模型 | 依赖 `core` | SQLAlchemy ORM、JSONB |
| `schemas` | 数据校验 | 依赖 `models` | Pydantic |
| `router` | 接口层 | 依赖 `service/schemas` | FastAPI |
| `service` | 业务逻辑 | 依赖 `core/models` | LangGraph、LLM |
| `scripts` | 工具脚本 | 独立运行 | asyncio |

### 3.2 依赖关系图

```mermaid
%%{init: {"theme": "forest", "flowchart": {"nodeSpacing": 24, "rankSpacing": 34, "padding": 16, "htmlLabels": true, "curve": "basis"}}}%%
flowchart TB
    config["config<br/>被所有模块依赖"]
    core["core<br/>基础设施层"]
    models["models"]
    schemas["schemas"]
    service["service"]
    router["router"]
    scripts["scripts<br/>独立运行"]
    api["API 接口"]

    config --> core
    core --> models
    models --> schemas
    models --> service
    schemas --> router
    service --> router
    router --> api
    core -.-> scripts
    models -.-> scripts
```

## 4. 最佳实践

### 4.1 新增功能时的文件创建顺序

假设要新增“用户收藏”功能：

```text
1. models/favorite.py            # 定义 Favorite 表
2. schemas/favorite.py           # 定义请求/响应 Schema
3. service/favorite_service.py   # 实现收藏逻辑
4. router/favorite_router.py     # 定义 API 接口
5. app_main.py                   # 注册路由
```

### 4.2 代码规范

```python
# 错误：直接在 Router 中写业务逻辑
@router.post("/favorite")
async def add_favorite(item_id: int, db: Session = Depends(get_db)):
    favorite = Favorite(item_id=item_id)
    db.add(favorite)
    db.commit()
    return favorite


# 正确：调用 Service 层
@router.post("/favorite")
async def add_favorite(item_id: int, db: Session = Depends(get_db)):
    service = FavoriteService(db)
    return await service.add_favorite(item_id)
```

## 5. 关键文件快速索引

| 功能 | 主文件位置 |
| --- | --- |
| 应用入口 | `/backend/app/app_main.py` |
| 数据库配置 | `/backend/app/core/database.py` |
| LLM 配置 | `/backend/app/config/llm_config.py` |
| 深度研究入口 | `/backend/app/service/deep_research_v2/service.py` |
| Agent 编排 | `/backend/app/service/deep_research_v2/graph.py` |
| 状态定义 | `/backend/app/service/deep_research_v2/state.py` |
| 6 个 Agent 实现 | `/backend/app/service/deep_research_v2/agents/*.py` |
| Text2SQL | `/backend/app/service/text2sql_service.py` |
| 向量检索 | `/backend/app/service/milvus_service.py` |
| 长期记忆 | `/backend/app/service/memory_service.py` |
| 定时任务 | `/backend/app/service/scheduler_service.py` |
