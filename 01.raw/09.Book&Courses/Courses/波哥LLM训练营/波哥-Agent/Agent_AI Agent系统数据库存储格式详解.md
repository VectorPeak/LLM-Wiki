# 第一周-03: AI Agent系统数据库存储格式详解

## 一、Milvus向量数据库存储格式

### 1.1 Collection结构设计

Milvus中的数据以 Collection（集合）形式组织，类似于关系数据库中的表。

```python
# Collection Schema定义示例
from pymilvus import CollectionSchema, FieldSchema, DataType

# 定义字段
fields = [
    FieldSchema(name="doc_id", dtype=DataType.VARCHAR, max_length=128, is_primary=True),
    FieldSchema(name="chunk_id", dtype=DataType.VARCHAR, max_length=128),
    FieldSchema(name="content", dtype=DataType.VARCHAR, max_length=65535),
    FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=1536),  # OpenAI embedding维度
    FieldSchema(name="metadata", dtype=DataType.JSON),
    FieldSchema(name="created_at", dtype=DataType.INT64),
    FieldSchema(name="updated_at", dtype=DataType.INT64)
]

schema = CollectionSchema(fields, description="Knowledge base embeddings")
```

### 1.2 知识库文档Collection

```json
{
  "collection_name": "knowledge_documents",
  "fields": {
    "doc_id": "DOC_20240115_001",
    "chunk_id": "CHUNK_001_P2",
    "content": "AI Agent是一种能够感知环境、做出决策并采取行动的智能系统...",
    "embedding": [0.0123, -0.0456, 0.0789, "..."],
    "metadata": {
      "source": "technical_documentation.pdf",
      "page_number": 2,
      "chunk_index": 1,
      "title": "AI Agent架构设计",
      "author": "张三",
      "tags": ["AI", "Agent", "架构"],
      "language": "zh-CN",
      "token_count": 256,
      "char_count": 512,
      "domain": "technology",
      "importance_score": 0.85,
      "last_accessed": "2024-01-15T10:30:00Z"
    },
    "created_at": 1705308600000,
    "updated_at": 1705308600000
  }
}
```

### 1.3 对话历史向量Collection

```json
{
  "collection_name": "conversation_embeddings",
  "fields": {
    "conversation_id": "CONV_USR001_20240115_001",
    "turn_id": "TURN_003",
    "user_id": "USR001",
    "user_query": "如何优化AI Agent的响应速度？",
    "agent_response": "优化AI Agent响应速度可以从以下几个方面着手...",
    "query_embedding": [0.0234, -0.0567, "..."],
    "response_embedding": [0.0345, -0.0678, "..."],
    "metadata": {
      "session_id": "SESSION_20240115_AM",
      "context_length": 3,
      "response_time_ms": 1250,
      "model_used": "gpt-4",
      "tools_used": ["web_search", "calculator"],
      "satisfaction_score": 4.5,
      "topic_tags": ["性能优化", "AI Agent"],
      "intent": "technical_inquiry",
      "sentiment": "neutral"
    },
    "created_at": 1705308900000
  }
}
```

### 1.4 用户画像向量Collection

```json
{
  "collection_name": "user_profile_embeddings",
  "fields": {
    "profile_id": "PROF_USR001_V3",
    "user_id": "USR001",
    "interest_embedding": [0.0456, -0.0789, "..."],
    "behavior_embedding": [0.0567, -0.0890, "..."],
    "metadata": {
      "interests": ["AI技术", "系统架构", "性能优化"],
      "expertise_level": "advanced",
      "preferred_language": "zh-CN",
      "interaction_style": "technical",
      "common_topics": {
        "AI": 0.35,
        "架构设计": 0.25,
        "编程": 0.20,
        "数据库": 0.20
      },
      "avg_session_duration": 1800,
      "total_interactions": 156
    },
    "updated_at": 1705308900000
  }
}
```

### 1.5 工具/API描述向量Collection

```json
{
  "collection_name": "tool_descriptions",
  "fields": {
    "tool_id": "TOOL_WEATHER_API_V2",
    "tool_name": "weather_query",
    "description": "查询全球任意城市的实时天气信息和未来预报",
    "description_embedding": [0.0678, -0.0901, "..."],
    "metadata": {
      "category": "information_retrieval",
      "api_endpoint": "https://api.weather.com/v2/query",
      "required_params": ["city", "country_code"],
      "optional_params": ["units", "lang", "days"],
      "response_format": "json",
      "rate_limit": "1000/hour",
      "avg_latency_ms": 200,
      "reliability_score": 0.99,
      "usage_examples": [
        "查询北京天气",
        "未来三天上海天气预报"
      ],
      "supported_languages": ["en", "zh", "ja", "ko"],
      "last_updated": "2024-01-10"
    },
    "created_at": 1704873600000
  }
}
```

## 二、SQL数据库存储格式

### 2.1 用户基础信息表

```sql
CREATE TABLE users (
    user_id VARCHAR(64) PRIMARY KEY,
    username VARCHAR(128) UNIQUE NOT NULL,
    email VARCHAR(256) UNIQUE NOT NULL,
    phone VARCHAR(32),
    full_name VARCHAR(256),
    avatar_url VARCHAR(512),
    language_preference VARCHAR(10) DEFAULT 'zh-CN',
    timezone VARCHAR(64) DEFAULT 'Asia/Shanghai',
    account_status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    user_role ENUM('free', 'basic', 'premium', 'enterprise') DEFAULT 'free',
    organization_id VARCHAR(64),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    total_tokens_used BIGINT DEFAULT 0,
    monthly_token_limit BIGINT DEFAULT 1000000,
    preferences JSON,
    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_org (organization_id)
);

-- 示例数据
INSERT INTO users VALUES (
    'USR001',
    'zhangsan',
    'zhangsan@example.com',
    '+86-13812345678',
    '张三',
    'https://avatars.example.com/usr001.jpg',
    'zh-CN',
    'Asia/Shanghai',
    'active',
    'premium',
    'ORG_TECH_001',
    '2024-01-01 10:00:00',
    '2024-01-15 14:30:00',
    '2024-01-15 14:00:00',
    850000,
    500000,
    '{
        "theme": "dark",
        "notification": {
            "email": true,
            "sms": false,
            "push": true
        },
        "ai_preferences": {
            "model": "gpt-4",
            "temperature": 0.7,
            "max_tokens": 2000,
            "response_style": "detailed"
        }
    }'
);
```

### 2.2 会话管理表

```sql
CREATE TABLE conversations (
    conversation_id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    title VARCHAR(512),
    summary TEXT,
    status ENUM('active', 'archived', 'deleted') DEFAULT 'active',
    model_config JSON,
    total_turns INT DEFAULT 0,
    total_tokens_used BIGINT DEFAULT 0,
    avg_response_time_ms INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ended_at TIMESTAMP NULL,
    tags JSON,
    metadata JSON,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX idx_user (user_id),
    INDEX idx_created (created_at),
    INDEX idx_status (status)
);

-- 示例数据
INSERT INTO conversations VALUES (
    'CONV_USR001_20240115_001',
    'USR001',
    'AI Agent架构设计讨论',
    '讨论了AI Agent的四层架构，包括数据层、工具层、模型层和应用层的设计',
    'active',
    '{
        "model": "gpt-4",
        "temperature": 0.7,
        "max_tokens": 2000,
        "tools_enabled": ["web_search", "code_interpreter", "dalle"]
    }',
    15,
    12500,
    1200,
    '2024-01-15 09:00:00',
    '2024-01-15 10:30:00',
    NULL,
    '["AI", "架构", "技术讨论"]',
    '{
        "source": "web_app",
        "device": "desktop",
        "browser": "Chrome 120",
        "ip_location": "北京"
    }'
);
```

### 2.3 消息记录表

```sql
CREATE TABLE messages (
    message_id VARCHAR(64) PRIMARY KEY,
    conversation_id VARCHAR(64) NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    role ENUM('user', 'assistant', 'system', 'tool') NOT NULL,
    content TEXT NOT NULL,
    tokens_used INT,
    model_used VARCHAR(64),
    tools_called JSON,
    response_time_ms INT,
    feedback_score DECIMAL(2,1),
    feedback_comment TEXT,
    is_edited BOOLEAN DEFAULT FALSE,
    parent_message_id VARCHAR(64),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSON,
    FOREIGN KEY (conversation_id) REFERENCES conversations(conversation_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX idx_conversation (conversation_id),
    INDEX idx_created (created_at),
    INDEX idx_role (role)
);

-- 示例数据
INSERT INTO messages VALUES (
    'MSG_001',
    'CONV_USR001_20240115_001',
    'USR001',
    'user',
    '请帮我设计一个AI Agent的架构',
    50,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    FALSE,
    NULL,
    '2024-01-15 09:00:00',
    '{"intent": "design_request", "complexity": "high"}'
),
(
    'MSG_002',
    'CONV_USR001_20240115_001',
    'USR001',
    'assistant',
    '我来为您设计一个工业级AI Agent架构，包含四个核心层次...',
    450,
    'gpt-4',
    '[
        {
            "tool": "web_search",
            "query": "latest AI agent architecture patterns 2024",
            "duration_ms": 500
        }
    ]',
    1200,
    4.5,
    '回答很详细，架构清晰',
    FALSE,
    'MSG_001',
    '2024-01-15 09:00:02',
    '{"confidence": 0.95, "sources": ["web", "knowledge_base"]}'
);
```

### 2.4 工具调用记录表

```sql
CREATE TABLE tool_executions (
    execution_id VARCHAR(64) PRIMARY KEY,
    message_id VARCHAR(64),
    conversation_id VARCHAR(64),
    user_id VARCHAR(64),
    tool_name VARCHAR(128) NOT NULL,
    tool_version VARCHAR(32),
    input_params JSON NOT NULL,
    output_result JSON,
    execution_status ENUM('pending', 'running', 'success', 'failed', 'timeout') NOT NULL,
    error_message TEXT,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    duration_ms INT,
    tokens_consumed INT,
    cost_cents DECIMAL(10,2),
    metadata JSON,
    FOREIGN KEY (message_id) REFERENCES messages(message_id),
    FOREIGN KEY (conversation_id) REFERENCES conversations(conversation_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX idx_tool (tool_name),
    INDEX idx_status (execution_status),
    INDEX idx_time (start_time)
);

-- 示例数据
INSERT INTO tool_executions VALUES (
    'EXEC_001',
    'MSG_002',
    'CONV_USR001_20240115_001',
    'USR001',
    'web_search',
    'v2.1',
    '{
        "query": "AI agent architecture patterns 2024",
        "max_results": 10,
        "language": "en"
    }',
    '{
        "results": [
            {
                "title": "Modern AI Agent Architecture Patterns",
                "url": "https://example.com/ai-patterns",
                "snippet": "The latest trends in AI agent design include...",
                "relevance_score": 0.92
            }
        ],
        "total_found": 156
    }',
    'success',
    NULL,
    '2024-01-15 09:00:01',
    '2024-01-15 09:00:02',
    500,
    100,
    0.05,
    '{
        "api_version": "2.1",
        "rate_limit_remaining": 995,
        "cache_hit": false
    }'
);
```

### 2.5 Agent配置表

```sql
CREATE TABLE agent_configurations (
    config_id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64),
    agent_name VARCHAR(256) NOT NULL,
    agent_type VARCHAR(64) NOT NULL,
    description TEXT,
    system_prompt TEXT NOT NULL,
    model_settings JSON,
    enabled_tools JSON,
    knowledge_bases JSON,
    behavior_rules JSON,
    is_active BOOLEAN DEFAULT TRUE,
    is_public BOOLEAN DEFAULT FALSE,
    usage_count INT DEFAULT 0,
    avg_rating DECIMAL(2,1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX idx_user (user_id),
    INDEX idx_type (agent_type),
    INDEX idx_active (is_active)
);

-- 示例数据
INSERT INTO agent_configurations VALUES (
    'AGENT_001',
    'USR001',
    '技术架构师助手',
    'technical_assistant',
    '专门用于软件架构设计和技术方案评审的AI助手',
    '你是一位经验丰富的技术架构师，擅长设计大规模分布式系统...',
    '{
        "model": "gpt-4",
        "temperature": 0.7,
        "top_p": 0.9,
        "max_tokens": 4000,
        "presence_penalty": 0.1,
        "frequency_penalty": 0.1
    }',
    '["code_interpreter", "web_search", "diagram_generator", "database_query"]',
    '["software_architecture_kb", "design_patterns_kb", "best_practices_kb"]',
    '{
        "response_style": "technical",
        "code_examples": true,
        "diagram_generation": true,
        "cite_sources": true,
        "max_iteration": 5
    }',
    TRUE,
    FALSE,
    245,
    4.7,
    '2024-01-01 10:00:00',
    '2024-01-15 14:00:00'
);
```

### 2.6 知识库元数据表

```sql
CREATE TABLE knowledge_bases (
    kb_id VARCHAR(64) PRIMARY KEY,
    owner_id VARCHAR(64) NOT NULL,
    kb_name VARCHAR(256) NOT NULL,
    description TEXT,
    kb_type ENUM('document', 'qa', 'structured', 'mixed') NOT NULL,
    source_type VARCHAR(64),
    total_chunks INT DEFAULT 0,
    total_tokens INT DEFAULT 0,
    embedding_model VARCHAR(128),
    embedding_dimension INT,
    last_sync_at TIMESTAMP,
    sync_status ENUM('idle', 'syncing', 'failed') DEFAULT 'idle',
    access_level ENUM('private', 'team', 'public') DEFAULT 'private',
    configuration JSON,
    statistics JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(user_id),
    INDEX idx_owner (owner_id),
    INDEX idx_type (kb_type)
);

-- 示例数据
INSERT INTO knowledge_bases VALUES (
    'KB_001',
    'USR001',
    'AI技术文档库',
    '包含AI、机器学习、深度学习等技术文档',
    'document',
    'pdf_upload',
    1250,
    458000,
    'text-embedding-ada-002',
    1536,
    '2024-01-15 08:00:00',
    'idle',
    'team',
    '{
        "chunk_size": 500,
        "chunk_overlap": 50,
        "split_method": "recursive",
        "metadata_extraction": true,
        "auto_sync": true,
        "sync_interval": "daily"
    }',
    '{
        "total_documents": 45,
        "avg_chunk_size": 366,
        "languages": ["zh", "en"],
        "topics": {
            "machine_learning": 0.35,
            "deep_learning": 0.25,
            "nlp": 0.20,
            "computer_vision": 0.20
        },
        "quality_score": 0.88
    }',
    '2024-01-01 10:00:00',
    '2024-01-15 08:00:00'
);
```

### 2.7 反馈与评价表

```sql
CREATE TABLE feedback (
    feedback_id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    conversation_id VARCHAR(64),
    message_id VARCHAR(64),
    feedback_type ENUM('rating', 'correction', 'suggestion', 'bug_report') NOT NULL,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    feedback_text TEXT,
    expected_output TEXT,
    actual_output TEXT,
    is_helpful BOOLEAN,
    status ENUM('pending', 'reviewed', 'resolved', 'ignored') DEFAULT 'pending',
    reviewer_id VARCHAR(64),
    review_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    metadata JSON,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (conversation_id) REFERENCES conversations(conversation_id),
    FOREIGN KEY (message_id) REFERENCES messages(message_id),
    INDEX idx_user (user_id),
    INDEX idx_type (feedback_type),
    INDEX idx_status (status)
);

-- 示例数据
INSERT INTO feedback VALUES (
    'FB_001',
    'USR001',
    'CONV_USR001_20240115_001',
    'MSG_002',
    'rating',
    5,
    '架构设计非常清晰，层次分明，对我帮助很大',
    NULL,
    NULL,
    TRUE,
    'reviewed',
    'ADMIN_001',
    '优质反馈，已用于模型优化',
    '2024-01-15 10:35:00',
    '2024-01-15 11:00:00',
    '{
        "sentiment": "positive",
        "categories": ["architecture", "clarity"],
        "used_for_training": true
    }'
);
```

### 2.8 系统审计日志表

```sql
CREATE TABLE audit_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(64),
    action_type VARCHAR(128) NOT NULL,
    resource_type VARCHAR(64),
    resource_id VARCHAR(64),
    action_details JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    session_id VARCHAR(128),
    status ENUM('success', 'failed', 'partial') NOT NULL,
    error_message TEXT,
    duration_ms INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_action (action_type),
    INDEX idx_time (created_at),
    INDEX idx_session (session_id)
);

-- 示例数据
INSERT INTO audit_logs VALUES (
    NULL,
    'USR001',
    'conversation.create',
    'conversation',
    'CONV_USR001_20240115_001',
    '{
        "title": "AI Agent架构设计讨论",
        "model": "gpt-4",
        "initial_message": "请帮我设计一个AI Agent的架构"
    }',
    '192.168.1.100',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0',
    'SESSION_20240115_AM_001',
    'success',
    NULL,
    50,
    '2024-01-15 09:00:00'
);
```

## 三、数据关联与索引策略

### 3.1 Milvus索引配置

```python
# 创建索引以优化向量搜索
index_params = {
    "index_type": "IVF_FLAT",  # 或 HNSW, ANNOY
    "metric_type": "IP",      # Inner Product 或 L2
    "params": {
        "nlist": 1024,
        "eff": 64
    }
}

# 为不同用途创建不同的索引
collection.create_index(
    field_name="embedding",
    index_params=index_params
)
```

### 3.2 SQL索引优化

```sql
-- 复合索引优化查询性能
CREATE INDEX idx_conv_user_time ON conversations(user_id, created_at DESC);
CREATE INDEX idx_msg_conv_role ON messages(conversation_id, role, created_at);
CREATE INDEX idx_tool_exec_status_time ON tool_executions(execution_status, start_time DESC);

-- 全文搜索索引
ALTER TABLE messages ADD FULLTEXT(content);
ALTER TABLE knowledge_bases ADD FULLTEXT(kb_name, description);
```
