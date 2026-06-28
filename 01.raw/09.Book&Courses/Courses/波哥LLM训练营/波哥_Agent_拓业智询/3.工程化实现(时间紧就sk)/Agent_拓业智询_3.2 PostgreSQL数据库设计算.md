# Agent_拓业智询_3.2 PostgreSQL数据库设计算

> 核心价值：12 张表的精巧设计，JSONB 字段的妙用，支撑多智能体系统的状态存储。

## 目录

1. 概述
2. 数据库连接配置
3. 12 张表 Schema 完整设计
4. ResearchCheckpoint 表详解
5. 索引策略优化
6. Alembic 迁移管理（数据库的 git）
7. 查询优化实践
8. 数据库备份与恢复
9. 性能监控
10. 总结

## 1. 概述

本项目采用 PostgreSQL 作为主数据库，设计了 12 张表覆盖 5 大功能模块：

- 用户认证：用户表
- 聊天系统：会话、消息、附件、长期记忆
- 知识库：知识库、文档
- 行业数据：统计数据、企业数据、政策数据
- 研究系统：检查点表（核心）
- 资讯采集：资讯、招投标、采集任务

技术亮点：

- JSONB 字段存储复杂对象（ResearchState、UIState）
- UUID 主键保证分布式唯一性
- 级联删除维持数据一致性
- 索引优化查询性能
- Alembic 管理数据库迁移

## 2. 数据库连接配置

### 2.1 核心配置文件

文件位置：`/backend/app/core/database.py`

```python
"""数据库连接和会话管理"""
import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

POSTGRES_HOST = os.getenv("POSTGRES_HOST", "localhost")
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")
POSTGRES_USER = os.getenv("POSTGRES_USER", "postgres")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "postgres123")
POSTGRES_DB = os.getenv("POSTGRES_DB", "industry_assistant")

DATABASE_URL = (
    f"postgresql://{POSTGRES_USER}:"
    f"{POSTGRES_PASSWORD}@{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"
)

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
    pool_recycle=3600,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    """获取数据库会话的依赖函数（FastAPI 用）"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

关键参数说明：

1. `pool_pre_ping=True`：每次从连接池获取连接前先发送 `SELECT 1` 测试，避免使用已断开的连接
2. `pool_size=10`：连接池保持 10 个活跃连接，适合中小型应用
3. `max_overflow=20`：超过 `pool_size` 时最多再创建 20 个临时连接，总计最多 30 个并发连接
4. `pool_recycle=3600`：连接使用 1 小时后自动回收

### 2.2 FastAPI 集成

```python
from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from core.database import get_db

app = FastAPI()

@app.get("/users/{user_id}")
async def get_user(user_id: str, db: Session = Depends(get_db)):
    """使用依赖注入获取数据库会话"""
    user = db.query(User).filter(User.id == user_id).first()
    return user
```

## 3. 12 张表 Schema 完整设计

### 3.1 模块导入

文件位置：`/backend/app/models/init.py`

```python
from .user import User
from .chat import ChatSession, ChatMessage, ChatAttachment, LongTermMemory
from .knowledge import KnowledgeBase, Document
from .industry_data import IndustryStats, CompanyData, PolicyData
from .research import ResearchCheckpoint
from .news import IndustryNews, BiddingInfo, NewsCollectionTask

__all__ = [
    "User",
    "ChatSession",
    "ChatMessage",
    "ChatAttachment",
    "LongTermMemory",
    "KnowledgeBase",
    "Document",
    "IndustryStats",
    "CompanyData",
    "PolicyData",
    "ResearchCheckpoint",
    "IndustryNews",
    "BiddingInfo",
    "NewsCollectionTask",
]
```

### 3.2 用户表（User）

文件位置：`/backend/app/models/user.py`

```python
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from core.database import Base

class User(Base):
    """用户模型"""
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(100), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    sessions = relationship("ChatSession", back_populates="user", cascade="all, delete-orphan")
    knowledge_bases = relationship("KnowledgeBase", back_populates="user", cascade="all, delete-orphan")
    documents = relationship("Document", back_populates="user", cascade="all, delete-orphan")
    memories = relationship("LongTermMemory", back_populates="user", cascade="all, delete-orphan")
```

设计要点：

1. UUID 主键：

```python
id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
```

- `as_uuid=True`：Python 中自动转换为 `uuid.UUID` 对象
- 避免自增 ID 的分布式冲突

2. 唯一索引：

```python
username = Column(String(50), unique=True, index=True)
email = Column(String(100), unique=True, index=True)
```

- `unique=True`：数据库层面保证唯一性
- `index=True`：创建 B-Tree 索引加速查询

3. 级联删除：

```python
cascade="all, delete-orphan"
```

- 删除用户时自动删除其所有会话、知识库等
- `delete-orphan`：解除关联时也删除子对象

生成的 SQL：

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_superuser BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ix_users_username ON users(username);
CREATE INDEX ix_users_email ON users(email);
```

### 3.3 聊天相关表（4 张表）

#### 3.3.1 ChatSession（会话表）

```python
class ChatSession(Base):
    """聊天会话模型"""
    __tablename__ = "chat_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"))
    session_id = Column(String(64), unique=True, nullable=False, index=True)
    title = Column(String(255), default="新对话")
    model = Column(String(50), default="qwen-max")
    temperature = Column(Float, default=0.7)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="sessions")
    messages = relationship("ChatMessage", back_populates="session", cascade="all, delete-orphan")
    attachments = relationship("ChatAttachment", back_populates="session", cascade="all, delete-orphan")
```

设计要点：

- `session_id`：字符串会话标识（前端生成）
- `id`：数据库内部 UUID 主键
- `ondelete="CASCADE"`：删除用户时自动删除会话

#### 3.3.2 ChatMessage（消息表）

```python
class ChatMessage(Base):
    """聊天消息模型"""
    __tablename__ = "chat_messages"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUID(as_uuid=True), ForeignKey("chat_sessions.id", ondelete="CASCADE"))
    role = Column(String(20), nullable=False)  # user/assistant/system
    content = Column(Text, nullable=False)
    message_id = Column(String(64), index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    session = relationship("ChatSession", back_populates="messages")
```

#### 3.3.3 ChatAttachment（附件表）

```python
class ChatAttachment(Base):
    """聊天附件模型（图片、文件等）"""
    __tablename__ = "chat_attachments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUID(as_uuid=True), ForeignKey("chat_sessions.id", ondelete="CASCADE"))
    filename = Column(String(255), nullable=False)
    file_type = Column(String(50))
    file_size = Column(BigInteger)
    file_path = Column(String(500))
    created_at = Column(DateTime, default=datetime.utcnow)

    session = relationship("ChatSession", back_populates="attachments")
```

#### 3.3.4 LongTermMemory（长期记忆表）

```python
class LongTermMemory(Base):
    """长期记忆模型"""
    __tablename__ = "long_term_memories"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"))
    key = Column(String(255), nullable=False, index=True)
    value = Column(Text, nullable=False)
    category = Column(String(50))  # preference/fact/history
    importance = Column(Float, default=0.5)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="memories")
```

应用场景：

```python
memory = LongTermMemory(
    user_id=user.id,
    key="preferred_chart_type",
    value="line",
    category="preference",
    importance=0.8,
)
```

### 3.4 知识库相关表（2 张表）

文件位置：`/backend/app/models/knowledge.py`

#### 3.4.1 KnowledgeBase（知识库表）

```python
class KnowledgeBase(Base):
    """知识库模型"""
    __tablename__ = "knowledge_bases"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"))
    name = Column(String(255), nullable=False)
    description = Column(Text)
    document_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="knowledge_bases")
    documents = relationship("Document", back_populates="knowledge_base", cascade="all, delete-orphan")
```

#### 3.4.2 Document（文档表）

```python
class Document(Base):
    """文档模型"""
    __tablename__ = "documents"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    knowledge_base_id = Column(UUID(as_uuid=True), ForeignKey("knowledge_bases.id", ondelete="CASCADE"))
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"))
    filename = Column(String(255), nullable=False)
    file_type = Column(String(50))
    file_size = Column(BigInteger)
    file_path = Column(String(500))
    status = Column(String(50), default="pending")  # pending/processing/completed/failed
    chunk_count = Column(Integer, default=0)
    error_message = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    knowledge_base = relationship("KnowledgeBase", back_populates="documents")
    user = relationship("User", back_populates="documents")
```

状态流转：

```text
pending → processing → completed
               ↓
             failed
```

### 3.5 行业数据表（3 张表）

文件位置：`/backend/app/models/industry_data.py`

#### 3.5.1 IndustryStats（行业统计表）

```python
class IndustryStats(Base):
    """行业统计数据表"""
    __tablename__ = "industry_stats"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    industry_name = Column(String(100), nullable=False, index=True)
    metric_name = Column(String(100), nullable=False)
    metric_value = Column(Float, nullable=False)
    unit = Column(String(50))
    year = Column(Integer, nullable=False, index=True)
    quarter = Column(Integer)
    month = Column(Integer)
    region = Column(String(50))
    source = Column(String(200))
    created_at = Column(DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": str(self.id),
            "industry_name": self.industry_name,
            "metric_name": self.metric_name,
            "metric_value": self.metric_value,
            "unit": self.unit,
            "year": self.year,
            "quarter": self.quarter,
            "month": self.month,
            "region": self.region,
            "source": self.source,
        }
```

示例数据：

```python
stat = IndustryStats(
    industry_name="智慧交通",
    metric_name="市场规模",
    metric_value=3200.0,
    unit="亿元",
    year=2024,
    region="全国"
)
```

#### 3.5.2 CompanyData（企业数据表）

```python
class CompanyData(Base):
    """企业数据表"""
    __tablename__ = "company_data"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    company_name = Column(String(200), nullable=False, index=True)
    stock_code = Column(String(20))
    industry = Column(String(100), nullable=False)
    sub_industry = Column(String(100))
    revenue = Column(Float)       # 营收（亿元）
    net_profit = Column(Float)    # 净利润（亿元）
    gross_margin = Column(Float)  # 毛利率（%）
    market_cap = Column(Float)    # 市值（亿元）
    employees = Column(Integer)
    market_share = Column(Float)  # 市场份额（%）
    year = Column(Integer, nullable=False)
    quarter = Column(Integer)
```

#### 3.5.3 PolicyData（政策数据表）

```python
class PolicyData(Base):
    """政策数据表"""
    __tablename__ = "policy_data"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    policy_name = Column(String(500), nullable=False)
    policy_number = Column(String(100))
    department = Column(String(200))
    level = Column(String(50))  # 国家级/省级/市级
    publish_date = Column(Date)
    effective_date = Column(Date)
    category = Column(String(100))
    industry = Column(String(100))
    summary = Column(Text)
    impact_level = Column(String(20))  # 重大/一般/轻微
```

## 4. ResearchCheckpoint 表详解

### 4.1 表结构设计

文件位置：`/backend/app/models/research.py`

```python
class ResearchCheckpoint(Base):
    """研究检查点模型 - 用于保存和恢复深度研究状态"""
    __tablename__ = "research_checkpoints"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(String(64), index=True, nullable=False)  # 研究会话 ID
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=True)

    query = Column(Text, nullable=False)          # 原始查询
    phase = Column(String(32), nullable=False)    # planning/researching/analyzing/writing/reviewing/completed
    iteration = Column(Integer, default=0)        # 当前迭代次数

    state_json = Column(JSONB, nullable=False)    # 完整的 ResearchState（后端状态）
    ui_state_json = Column(JSONB)                 # 前端 UI 状态（研究步骤、搜索结果、图表等）

    final_report = Column(Text)                   # 最终报告内容
    status = Column(String(16), default="running")  # running/paused/completed/failed
    error_message = Column(Text)                  # 错误信息（如果失败）

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", backref="research_checkpoints")

    def to_dict(self, include_state: bool = False):
        result = {
            "id": str(self.id),
            "session_id": self.session_id,
            "user_id": str(self.user_id) if self.user_id else None,
            "query": self.query,
            "phase": self.phase,
            "iteration": self.iteration,
            "status": self.status,
            "error_message": self.error_message,
            "final_report": self.final_report,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
        if include_state:
            result["state_json"] = self.state_json
            result["ui_state_json"] = self.ui_state_json
        return result
```

### 4.2 JSONB 字段的妙用

为什么使用 JSONB？

1. 灵活性：存储任意结构的 Python 字典/列表
2. 查询能力：支持 JSON 路径查询（GIN 索引）
3. 性能：JSONB 是二进制格式，比 TEXT 快
4. 版本兼容：Schema 变更无需迁移

#### 4.2.1 state_json 结构示例

```python
state_json = {
    "query": "智慧交通2024年市场规模分析",
    "phase": "analyzing",
    "iteration": 2,
    "research_plan": {
        "questions": [
            "智慧交通市场规模是多少？",
            "主要企业有哪些？",
            "政策支持情况如何？"
        ],
        "approach": "top_down"
    },
    "search_history": [
        {
            "query": "智慧交通市场规模",
            "results": [...]
        }
    ],
    "analysis_results": {
        "market_size": "3200亿元",
        "growth_rate": "12.3%"
    },
    "messages": [
        {"role": "user", "content": "..."},
        {"role": "assistant", "content": "..."}
    ]
}
```

#### 4.2.2 ui_state_json 结构示例

```python
ui_state_json = {
    "research_steps": [
        {
            "phase": "planning",
            "title": "制定研究计划",
            "status": "completed",
            "timestamp": "2024-01-31T10:00:00"
        },
        {
            "phase": "researching",
            "title": "搜索资料",
            "status": "in_progress",
            "progress": 60
        }
    ],
    "search_results": [
        {
            "title": "智慧交通发展报告",
            "url": "https://...",
            "snippet": "...",
            "score": 0.95
        }
    ],
    "charts": [
        {
            "id": "chart1",
            "type": "line",
            "title": "市场规模趋势",
            "data": {
                "labels": ["2020", "2021", "2022", "2023", "2024"],
                "datasets": [{
                    "label": "市场规模",
                    "data": [1800, 2200, 2600, 2850, 3200]
                }]
            }
        }
    ],
    "knowledge_graph": {
        "nodes": [
            {"id": "n1", "label": "智慧交通", "type": "industry"},
            {"id": "n2", "label": "海康威视", "type": "company"}
        ],
        "edges": [
            {"source": "n1", "target": "n2", "relation": "领军企业"}
        ]
    }
}
```

### 4.3 JSONB 查询示例

#### 4.3.1 基本查询

```python
from sqlalchemy import cast
from sqlalchemy.dialects.postgresql import JSONB

# 查询 phase 为 "analyzing" 的检查点
checkpoints = db.query(ResearchCheckpoint).filter(
    ResearchCheckpoint.state_json["phase"].astext == "analyzing"
).all()

# 查询 iteration 大于 2 的检查点
checkpoints = db.query(ResearchCheckpoint).filter(
    cast(ResearchCheckpoint.state_json["iteration"], Integer) > 2
).all()
```

#### 4.3.2 嵌套查询

```python
# 查询包含特定问题的检查点
checkpoints = db.query(ResearchCheckpoint).filter(
    ResearchCheckpoint.state_json["research_plan"]["questions"].contains(
        ["智慧交通市场规模是多少？"]
    )
).all()

# 查询 UI 状态中有图表的检查点
checkpoints = db.query(ResearchCheckpoint).filter(
    ResearchCheckpoint.ui_state_json["charts"] != None
).all()
```

#### 4.3.3 GIN 索引优化

```python
from alembic import op

def upgrade():
    op.execute("""
        CREATE INDEX ix_research_checkpoints_state_gin
        ON research_checkpoints USING GIN (state_json);

        CREATE INDEX ix_research_checkpoints_ui_state_gin
        ON research_checkpoints USING GIN (ui_state_json);
    """)
```

### 4.4 JSONB 序列化处理

文件位置：`/backend/app/service/checkpoint_service.py`（第 307-327 行）

```python
def _clean_state_for_storage(self, state: Dict[str, Any]) -> Dict[str, Any]:
    """
    清理状态以便存储

    移除不可序列化的内容，保留可恢复的数据
    """
    clean = {}
    for key, value in state.items():
        try:
            json.dumps(value, default=str)
            clean[key] = value
        except (TypeError, ValueError):
            if isinstance(value, (list, tuple)):
                clean[key] = [str(v) for v in value]
            elif isinstance(value, dict):
                clean[key] = self._clean_state_for_storage(value)
            else:
                clean[key] = str(value)
    return clean
```

处理的问题：

- Python 对象（如 `datetime.datetime`）无法直接序列化
- 复杂嵌套结构中的非 JSON 类型
- 函数、类实例等不可序列化对象

## 5. 索引策略优化

### 5.1 索引类型选择

截图中这里是一张索引类型对比表，但表格内容不可完全辨认；可确定该节是在说明不同索引类型的适用场景。

### 5.2 复合索引设计

```python
from sqlalchemy import Index

# ChatMessage 表：session_id + created_at 复合索引
Index(
    "ix_chat_messages_session_time",
    ChatMessage.session_id,
    ChatMessage.created_at.desc()
)

# IndustryStats 表：industry_name + year 复合索引
Index(
    "ix_industry_stats_name_year",
    IndustryStats.industry_name,
    IndustryStats.year.desc()
)

# Document 表：knowledge_base_id + status 复合索引
Index(
    "ix_documents_kb_status",
    Document.knowledge_base_id,
    Document.status
)
```

优化效果：

```sql
-- 优化前（无索引）
SELECT * FROM chat_messages
WHERE session_id = 'xxx'
ORDER BY created_at DESC
LIMIT 20;
-- 执行时间：150ms

-- 优化后（复合索引）
-- 执行时间：5ms
```

### 5.3 部分索引（Partial Index）

```python
# 只索引 status='completed' 的文档
Index(
    "ix_documents_completed",
    Document.knowledge_base_id,
    postgresql_where=(Document.status == "completed")
)

# 只索引 is_active=True 的用户
Index(
    "ix_users_active",
    User.email,
    postgresql_where=(User.is_active == True)
)
```

优势：

- 减少索引大小（节省存储空间）
- 提高索引维护速度
- 精准匹配查询场景

## 6. Alembic 迁移管理（数据库的 git）

### 6.1 初始化 Alembic

```bash
cd backend
alembic init alembic
```

生成的目录结构：

```text
backend/
├── alembic/
│   ├── versions/
│   │   └── (迁移脚本)
│   ├── env.py
│   └── script.py.mako
├── alembic.ini
└── app/
    └── models/
```

### 6.2 配置 alembic.ini

```ini
[alembic]
script_location = alembic
sqlalchemy.url = postgresql://postgres:postgres123@localhost:5432/industry_assistant

[loggers]
keys = root,sqlalchemy,alembic

[logger_alembic]
level = INFO
handlers =
qualname = alembic
```

### 6.3 配置 env.py

```python
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context

from app.models import Base
from app.core.database import DATABASE_URL

config = context.config
config.set_main_option('sqlalchemy.url', DATABASE_URL)

fileConfig(config.config_file_name)
target_metadata = Base.metadata

def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix='sqlalchemy.',
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()

run_migrations_online()
```

### 6.4 创建迁移脚本

```bash
# 自动生成迁移脚本
alembic revision --autogenerate -m "Create initial tables"

# 执行迁移
alembic upgrade head

# 回滚迁移
alembic downgrade -1
```

生成的迁移脚本示例：

```python
"""Create initial tables

Revision ID: 001
Create Date: 2024-01-31 10:00:00
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '001'
down_revision = None

def upgrade():
    op.create_table(
        'users',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('username', sa.String(length=50), nullable=False),
        sa.Column('email', sa.String(length=100), nullable=False),
        sa.Column('hashed_password', sa.String(length=255), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('is_superuser', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)
    op.create_index(op.f('ix_users_username'), 'users', ['username'], unique=True)

    op.create_table(
        'research_checkpoints',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('session_id', sa.String(length=64), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('query', sa.Text(), nullable=False),
        sa.Column('phase', sa.String(length=32), nullable=False),
        sa.Column('iteration', sa.Integer(), nullable=True),
        sa.Column('state_json', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('ui_state_json', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('final_report', sa.Text(), nullable=True),
        sa.Column('status', sa.String(length=16), nullable=True),
        sa.Column('error_message', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_research_checkpoints_session_id'), 'research_checkpoints', ['session_id'], unique=False)

    op.execute("""
        CREATE INDEX ix_research_checkpoints_state_gin
        ON research_checkpoints USING GIN (state_json);
    """)

def downgrade():
    op.drop_index(op.f('ix_research_checkpoints_state_gin'))
    op.drop_index(op.f('ix_research_checkpoints_session_id'))
    op.drop_table('research_checkpoints')
    op.drop_index(op.f('ix_users_username'))
    op.drop_index(op.f('ix_users_email'))
    op.drop_table('users')
```

### 6.5 迁移版本管理

```bash
# 查看当前版本
alembic current

# 查看迁移历史
alembic history

# 升级到特定版本
alembic upgrade 001

# 回滚到初始状态
alembic downgrade base
```

## 7. 查询优化实践

### 7.1 预加载关联对象（避免 N+1 查询）

```python
from sqlalchemy.orm import joinedload

# 错误做法（N+1 查询）
users = db.query(User).all()
for user in users:
    for session in user.sessions:  # 每次都查询数据库
        print(session.title)

# 正确做法（预加载）
users = db.query(User).options(
    joinedload(User.sessions)
).all()
for user in users:
    for session in user.sessions:  # 已加载到内存
        print(session.title)
```

### 7.2 分页查询

```python
def get_checkpoints(
    db: Session,
    page: int = 1,
    page_size: int = 20,
    status: Optional[str] = None
):
    """分页查询检查点"""
    query = db.query(ResearchCheckpoint)

    if status:
        query = query.filter(ResearchCheckpoint.status == status)

    total = query.count()
    items = query.order_by(
        ResearchCheckpoint.updated_at.desc()
    ).offset((page - 1) * page_size).limit(page_size).all()

    return {
        "total": total,
        "page": page,
        "page_size": page_size,
        "items": [item.to_dict() for item in items]
    }
```

### 7.3 聚合查询

```python
from sqlalchemy import func

# 按行业统计企业数量
stats = db.query(
    CompanyData.industry,
    func.count(CompanyData.id).label('count'),
    func.sum(CompanyData.revenue).label('total_revenue'),
    func.avg(CompanyData.market_share).label('avg_market_share')
).group_by(CompanyData.industry).all()

for stat in stats:
    print(f"{stat.industry}: {stat.count}家企业，总营收{stat.total_revenue}亿元")
```

## 8. 数据库备份与恢复

### 8.1 PostgreSQL 备份

```bash
# 备份整个数据库
pg_dump -U postgres -h localhost industry_assistant > backup.sql

# 备份 Schema（不含数据）
pg_dump -U postgres -h localhost -s industry_assistant > schema.sql

# 备份单张表
pg_dump -U postgres -h localhost -t research_checkpoints industry_assistant > checkpoints_backup.sql

# 压缩备份
pg_dump -U postgres -h localhost industry_assistant | gzip > backup.sql.gz
```

### 8.2 恢复数据

```bash
# 恢复整个数据库
psql -U postgres -h localhost industry_assistant < backup.sql

# 恢复压缩备份
gunzip -c backup.sql.gz | psql -U postgres -h localhost industry_assistant
```

### 8.3 Docker 环境备份

```bash
# 备份
docker exec industry_postgres pg_dump -U postgres industry_assistant > backup.sql

# 恢复
cat backup.sql | docker exec -i industry_postgres psql -U postgres industry_assistant
```

## 9. 性能监控

### 9.1 慢查询日志

修改 `postgresql.conf`：

```conf
log_min_duration_statement = 1000
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d '
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
```

### 9.2 查询执行计划

```sql
EXPLAIN ANALYZE
SELECT * FROM research_checkpoints
WHERE state_json->>'phase' = 'analyzing'
ORDER BY updated_at DESC
LIMIT 20;
```

输出示例：

```text
Limit  (cost=0.29..12.34 rows=20 width=1234) (actual time=0.234..1.123 rows=20 loops=1)
  ->  Index Scan using ix_research_checkpoints_updated_at on research_checkpoints
      (cost=0.29..5678.90 rows=9456 width=1234) (actual time=0.233..1.115 rows=20 loops=1)
      Filter: ((state_json ->> 'phase'::text) = 'analyzing'::text)
      Rows Removed by Filter: 58
Planning Time: 0.456 ms
Execution Time: 1.234 ms
```

### 9.3 表膨胀检查

```sql
-- 查看表大小
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## 10. 总结

本章深入讲解了 PostgreSQL 数据库设计：

1. 12 张表 Schema：覆盖用户、聊天、知识库、行业数据、研究、资讯
2. JSONB 妙用：存储复杂对象，支持 JSON 查询
3. 索引优化：B-Tree、GIN、复合索引、部分索引
4. Alembic 迁移：版本化管理 Schema 变更
5. 查询优化：预加载、分页、聚合
6. 备份恢复：数据安全保障

关键文件：

- `/backend/app/models/*.py`：所有模型定义
- `/backend/app/core/database.py`：数据库连接配置

下一章预告：`3.3 Milvus 向量数据库集成`，讲解向量化流程、Collection 设计和混合检索策略。
