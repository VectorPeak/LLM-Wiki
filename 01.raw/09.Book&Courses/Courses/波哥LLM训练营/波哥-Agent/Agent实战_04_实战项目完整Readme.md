# 【Agent实战-第4天】实战项目完整 Readme

# SalesPilot：全域知识增强的大模型销售智脑

本项目是为新能源车企打造的智能销售培训助手系统，整合 **RAG 问答、实时 Web 搜索和智能 Agent 三大核心技术**，支持本地文档知识库检索（覆盖车辆参数/配置/FAQ）、动态获取竞品对比/行业政策/用户评价，并通过个性化 Agent 生成针对性销售话术。

复现本项目，你可以学会：

1. 掌握工业级 RAG 系统开发：从文档向量化、混合检索策略到生成结果优化全流程。
2. 构建实时知识更新体系：集成搜索引擎 API 与网页解析技术，突破大模型时效限制。
3. 开发智能决策 Agent：基于 ReAct 框架实现用户画像分析、多工具调度和对话记忆管理。

本系统架构具有行业普适性，通过调整知识库和工具链即可快速应用于以下领域：

- 金融领域：客户理财顾问系统（产品知识库 + 金融数据 API + 风控规则引擎）
- 医疗领域：智能问诊助手（医学文献库 + 检查报告解析 + 诊疗指南 Agent）
- 教育领域：个性化学习系统（教材知识图谱 + 学术资源爬取 + 自适应推荐引擎）
- 电商领域：智能导购机器人（商品数据库 + 用户评论分析 + 促销策略生成）

## 项目界面

系统首页展示为“企业培训助手”，用户可以在输入框中提出问题，并通过按钮触发：

- 附件上传
- 深度探索
- 网络检索
- 推荐问题快捷输入

示例推荐问题包括：

- 星辰电动 ES9 有智能驾驶吗？
- 星辰电动 ES9 多少钱？
- 介绍一下星辰电动 ES9 的配置。
- 比较一下华为问界 M7 和星辰电动 ES9。
- 你好，帮我了解一下星辰电动 ES9。

系统回答时会展示：

- 检索过程与引用内容
- 自然语言答案
- 图片搜索结果
- 视频搜索结果
- 后续追问输入框

## 关键能力

### 1. 车辆知识库问答（本地知识库检索）

支持基于本地车辆资料进行问答，例如车辆配置、价格、续航、功能介绍等。系统会从知识库中召回相关片段，再交给大模型生成面向用户的回答。

### 2. 实时 Web 检索

当用户问题需要最新信息时，系统会调用搜索 API 获取网页信息，例如竞品新闻、行业政策、用户评价等，避免模型仅依赖过期知识。

### 3. 图像与视频检索

系统可以展示与问题相关的图片和视频搜索结果，例如车辆外观图、评测视频、配置图片等，让销售培训场景更直观。

### 4. 交互增强与 Agent 决策

系统不仅是普通问答，还会结合用户意图和历史上下文决定是否需要：

- 本地知识库检索
- 网络搜索
- 深度研究
- 生成推荐追问
- 输出销售话术

## 部署流程

### 1. 确认已经安装 Docker

如果未安装，则通过官网下载：

https://www.docker.com/products/docker-desktop/

### 2. 获取并配置 API Key

需要获取大模型 API Key 和搜索 API Key。

#### 2.1 大模型 API Key

本项目默认使用阿里通义大模型 API。

通义百炼地址：

https://www.aliyun.com/product/bailian

进入阿里云百炼控制台后，在右上角找到 API Key 管理入口，创建或查看自己的 API Key。

#### 2.2 搜索 API Key

Serper Key 是一个用于访问 Serper API 的密钥。Serper 是一个提供谷歌搜索结果的 API 工具，开发者可以通过 Serper Key 调用该工具，快速获取谷歌搜索的实时结果。

Serper 获取网页：

https://serper.dev/

进入 Serper 控制台后，点击 **API key** 菜单获取所需 key。

> 注意：截图中展示的是密钥管理页面和 `.env` 配置位置，本文档只保留配置方式，不记录任何真实密钥。

### 3. 启动后端服务

在项目代码中的 `.env` 文件中配置以下环境变量：

```env
DASHSCOPE_API_KEY="<your-dashscope-key>"
SERPER_API_KEY="<your-serper-key>"
```

#### 3.1 启动 Docker

启动 Docker，包括 PostgreSQL 和 Elasticsearch 服务。注意需要合理上网，否则可能连接不上。

先进入 `backend` 目录，再运行以下命令：

```bash
docker compose -f docker-compose-base.yml up
```

如果终端出现类似下面的信息：

```text
[+] Running 2/2
✔ Container postgres-service       Running
✔ Container elasticsearch-service  Running
```

或者在 Docker Desktop 中看到名为 `backend` 的项目且状态为绿色，则说明启动成功。

#### 3.2 创建并激活虚拟环境

```bash
# 创建虚拟环境
conda create -n agent python=3.11

# 激活虚拟环境
conda activate agent
```

#### 3.3 安装相应的包

先进入 `app` 目录：

```bash
cd app
```

再运行以下命令：

```bash
python -m pip install -r requirements.txt
```

#### 3.4 启动应用服务

```bash
python app_main.py
```

如果输出类似下面内容，则说明启动成功：

```text
INFO:     Started server process [18820]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     127.0.0.1:7249 - "POST /deep_research/?session_id=... HTTP/1.1" 200 OK
```

到此为止，后端服务启动成功。

### 4. 启动前端服务

前后端服务启动成功后，可能还是输出状态，建议新开一个 terminal。

#### 4.1 检查是否安装 Node.js

```bash
node -v
npm -v
```

如果正常输出版本且不报错，则说明已经安装了 Node.js；若报错，则先通过官网安装：

https://nodejs.org/zh-cn

#### 4.2 安装前端依赖

先删除版本锁文件：

```text
package-lock.json
```

再去 `frontend` 目录：

```bash
cd frontend
```

运行以下命令：

```bash
npm install
```

#### 4.3 启动开发服务器

```bash
npm run dev
```

出现类似下面的信息，则表示运行成功，可以进入该链接体验项目：

```text
VITE v6.2.3  ready in 712 ms

➜  Local:   http://localhost:5181/
➜  Network: http://10.32.25.118:5181/
➜  Network: http://172.19.96.1:5181/
➜  press h + enter to show help
```

如果遇到：

```text
Error: Cannot find module
```

则需要删除 `node_modules`，重新执行：

```bash
npm install
```

最终通过 `ctrl + click` 进入链接后，可以看到项目首页。

## 运行成功标志

当前后端都成功启动后，浏览器中应能看到“企业培训助手”首页，包含：

- 输入框
- 附件按钮
- 深度探索按钮
- 网络检索按钮
- 推荐问题
- 发送按钮

用户输入问题后，系统会调用后端服务，并根据问题情况执行本地知识库检索、网络检索或深度研究流程。
