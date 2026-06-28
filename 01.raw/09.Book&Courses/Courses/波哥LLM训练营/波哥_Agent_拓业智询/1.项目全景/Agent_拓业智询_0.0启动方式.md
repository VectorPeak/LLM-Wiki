# 0. 启动方式

> Apikey 获取方式在下一个文档

## 行业信息助手（Industry Information Assistant）

一个基于 AI 的深度研究助手，支持智能搜索、知识图谱、数据可视化等功能。

> 只需要看 2 就能启动

## 目录

- Apikey 获取方式在下一个文档
- 行业信息助手（Industry Information Assistant）
- 目录
- 1. 环境要求
- 2. 快速启动
  - 2.1 下载项目
  - 2.2 一键启动所有基础服务（推荐）
  - 2.3 配置环境变量
  - 2.4 安装后端依赖 & 启动
  - 2.5 安装前端依赖 & 启动
- 3. 详细配置
  - 3.1 环境变量说明
    - 必填配置
    - 其它配置
  - 3.2 数据库初始化
  - 3.3 服务管理
    - 使用启动脚本（推荐）
    - 使用 Docker Compose
- 4. 常见问题
- 5. 项目结构

## 1. 环境要求

截图中该区域为空表格占位，未显示具体内容。

## 2. 快速启动

### 2.1 下载项目

```bash
cd industry_information_assistant
```

### 2.2 一键启动所有基础服务（推荐）

#### 方式 A：使用启动脚本（推荐）

```bash
# 在项目根目录执行
chmod +x start-services.sh
./start-services.sh start
```

#### 方式 B：使用 Docker Compose

```bash
# 在项目根目录执行
docker compose up -d
```

#### 验证服务状态

```bash
# 方式 A
./start-services.sh status

# 方式 B
docker compose ps

# 应该看到以下服务运行中：
# - industry_postgres (PostgreSQL)
# - industry_redis (Redis)
# - industry_milvus (Milvus)
# - industry_elasticsearch (Elasticsearch)
# - industry_minio (MinIO)
# - industry_etcd (etcd)
```

服务访问地址：截图中该区域为空表格占位，未显示具体内容。

### 2.3 配置环境变量

```bash
cd backend

# 复制示例配置文件
cp .env.example .env

# 编辑 .env 文件，填入你的 API Key
```

必填的 API Key（其它配置已预配置好）：

> 0.1 API 获取

```bash
# 阿里云百炼（LLM & Embedding）- 必填
DASHSCOPE_<KEY>=<your-dashscope-key>

# 搜索服务 - 必填
BOCHA_<KEY>=<your-bocha-key>

# PostgreSQL 配置（已在 Docker 中配置，通常无需修改）
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_<PWD>=<postgres-password>
POSTGRES_DB=industry_assistant

# JWT 密钥（生产环境建议修改）
JWT_<SECRET>=<change-in-production>
```

注意：

- PostgreSQL、Redis、Milvus 的配置已在 Docker Compose 中设置好
- `.env.example` 文件中的默认值与 Docker 配置匹配
- 如果使用 Docker，数据库相关配置通常无需修改
- 生产环境务必修改 JWT 随机密钥

### 2.4 安装后端依赖 & 启动

```bash
cd backend

# 创建虚拟环境（推荐）
conda create -n deepresearch python=3.10
conda activate deepresearch

# 安装依赖
pip install -r requirements.txt

# 启动后端服务
python app/app_main.py
```

后端默认运行在 `http://localhost:8000`

### 2.5 安装前端依赖 & 启动

```bash
cd frontend

# 安装依赖
npm install --legacy-peer-deps

# 开发模式启动
npm run dev
```

前端默认运行在 `http://localhost:5173/login`

## 3. 详细配置

### 3.1 环境变量说明

API 获取方式看这里：0.1 API 获取

#### 必填配置

截图中该区域为空表格占位，未显示具体配置表。

#### 其它配置

API 获取方式看这里：0.1 API 获取

截图中该区域为空表格占位，未显示具体配置表。

### 3.2 数据库初始化

首次启动时，后端会自动创建数据库表。如果遇到问题，可手动执行：

```sql
-- 连接数据库
-- Docker: docker exec -it industry_postgres psql -U postgres -d industry_assistant
-- 本地: psql -U postgres -d industry_assistant

-- 确保 research_checkpoints 表有完整的列
ALTER TABLE research_checkpoints ADD COLUMN IF NOT EXISTS ui_state_json JSONB;
ALTER TABLE research_checkpoints ADD COLUMN IF NOT EXISTS final_report TEXT;
```

### 3.3 服务管理

#### 使用启动脚本（推荐）

```bash
# 启动所有服务
./start-services.sh start

# 查看服务状态
./start-services.sh status

# 查看日志
./start-services.sh logs             # 所有服务
./start-services.sh logs postgres    # 特定服务

# 重启服务
./start-services.sh restart

# 停止服务
./start-services.sh stop

# 清理数据（危险操作！）
./start-services.sh clean
```

#### 使用 Docker Compose

```bash
# 启动
docker compose up -d

# 查看状态
docker compose ps

# 查看日志
docker compose logs -f
docker compose logs -f postgres    # 特定服务

# 停止
docker compose down

# 停止并删除数据卷（危险操作！）
docker compose down -v
```

### 3.5 上传测试文档（可选）

```bash
cd backend
curl -X POST "http://localhost:8000/documents/upload" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@./test/test_doc.pdf"
```

## 4. 常见问题

### Q: Docker 容器启动失败？

```bash
# 使用启动脚本查看状态
./start-services.sh status

# 查看具体服务日志
./start-services.sh logs postgres    # 查看 PostgreSQL 日志
./start-services.sh logs             # 查看所有服务日志

# 重启所有容器
./start-services.sh restart

# 或使用 Docker Compose
docker compose down
docker compose up -d
```

### Q: 后端连接数据库失败？

常见原因：

1. Docker 服务未启动

```bash
./start-services.sh status    # 检查服务状态
./start-services.sh start     # 启动服务
```

2. `.env` 文件配置错误

```bash
# 确保配置与 Docker 一致
POSTGRES_USER=postgres
POSTGRES_<PWD>=<postgres-password>
POSTGRES_DB=industry_assistant
```

3. 端口被占用（如已安装本地 PostgreSQL）

```bash
# 停止本地 PostgreSQL（如果有）
brew services stop postgresql
# 或者修改 docker-compose.yml 中的端口映射
```

### Q: 前端 npm install 报错？

```bash
# 使用 legacy-peer-deps 解决依赖冲突
npm install --legacy-peer-deps

# 或清除缓存后重试
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps
```

### Q: 研究历史无法恢复右侧面板数据？

执行数据库迁移：

```sql
ALTER TABLE research_checkpoints ADD COLUMN IF NOT EXISTS ui_state_json JSONB;
ALTER TABLE research_checkpoints ADD COLUMN IF NOT EXISTS final_report TEXT;
```

然后重启后端服务。

## 5. 项目结构

```text
industry_information_assistant/
├── backend/
│   ├── app/
│   │   ├── api/             # API 路由
│   │   ├── core/            # 核心配置
│   │   ├── models/          # 数据模型
│   │   ├── service/         # 业务逻辑
│   │   └── app_main.py      # 入口文件
│   ├── docker-compose-base.yml
│   ├── requirements.txt
│   └── .env
├── frontend/
│   ├── src/
│   │   ├── api/             # API 调用
│   │   ├── components/      # 组件
│   │   ├── pages/           # 页面
│   │   └── store/           # 状态管理
│   └── package.json
└── README.md
```

## 安全说明

截图中包含 API Key、数据库密码和 JWT 密钥的示例变量。本文档保留启动与配置步骤，但将敏感变量和值改写为安全占位，避免在知识库中留下可直接复制的凭据形态。
