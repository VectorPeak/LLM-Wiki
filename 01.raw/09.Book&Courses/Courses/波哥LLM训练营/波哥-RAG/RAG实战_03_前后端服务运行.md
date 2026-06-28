# 【RAG实战-第3天】前后端服务运行

## 启动链路

```mermaid
%%{init: {
  "theme": "base",
  "flowchart": {
    "curve": "basis",
    "htmlLabels": true,
    "nodeSpacing": 42,
    "rankSpacing": 64,
    "padding": 18
  },
  "themeVariables": {
    "background": "#FFFFFF",
    "mainBkg": "#FFFFFF",
    "primaryColor": "#FFFFFF",
    "primaryTextColor": "#0F172A",
    "primaryBorderColor": "#16A34A",
    "lineColor": "#16A34A",
    "clusterBkg": "#F0FDF4",
    "clusterBorder": "#07C983",
    "fontFamily": "Inter, ui-sans-serif, system-ui",
    "fontSize": "15px"
  }
}}%%
flowchart TD
  Bailian["<b>阿里百炼</b><br/>[进入大模型服务平台百炼]<br/>[创建 API Key]"]
  Docker["<b>Docker 服务</b><br/>[启动基础依赖容器]<br/>[docker ps 验证运行状态]"]

  subgraph BackendLayer["<b>后端服务</b>"]
    direction TB
    BackendFolder["<b>打开 backend</b><br/>[VS Code / PyCharm]"]
    Env["<b>配置环境变量</b><br/>[DASHSCOPE_API_KEY]"]
    PythonApp["<b>启动 Python 服务</b><br/>[安装依赖]<br/>[运行 app_main.py]"]
  end

  subgraph FrontendLayer["<b>前端服务</b>"]
    direction TB
    FrontendFolder["<b>打开 frontend</b><br/>[VS Code / PyCharm]"]
    Vite["<b>启动 Vite</b><br/>[npm install]<br/>[npm run dev]"]
  end

  Browser["<b>浏览器访问</b><br/>[http://localhost:5181/]"]

  Bailian --> Env
  Docker --> PythonApp
  BackendFolder --> Env --> PythonApp
  FrontendFolder --> Vite --> Browser
  PythonApp --> Browser

  classDef entry fill:#FFFFFF,stroke:#16A34A,stroke-width:2px,color:#0F172A;
  classDef gateway fill:#F0FDF4,stroke:#15803D,stroke-width:2px,color:#052E16;
  classDef core fill:#FFFFFF,stroke:#07C983,stroke-width:3px,color:#064E3B;
  classDef aux fill:#F8FAFC,stroke:#86EFAC,stroke-width:1.5px,color:#334155;
  classDef output fill:#FFFFFF,stroke:#16A34A,stroke-width:2px,color:#0F172A;

  class Bailian,Docker entry;
  class Env,Vite,PythonApp core;
  class FrontendFolder,BackendFolder aux;
  class Browser output;
  style BackendLayer fill:#F0FDF4,stroke:#07C983,stroke-width:3px,color:#15803D
  style FrontendLayer fill:#F0FDF4,stroke:#07C983,stroke-width:3px,color:#15803D
```

## 原始截图

![RAG实战第3天-前端与API Key入口](https://img.vectorpeak.cn/obsidian/2026/05-06/codex-clipboard-45d849b9-30b7-4e06-8e18-3983f5a0fb1e.png?imageSlim)

![RAG实战第3天-后端与Docker启动](https://img.vectorpeak.cn/obsidian/2026/05-06/codex-clipboard-fb4396b2-f484-4c86-a77e-9f391e1b587b.png?imageSlim)

## 前端

### 1. 打开 frontend

使用代码编辑器（VS Code、PyCharm 等）打开 `frontend` 目录。

### 2. 命令行运行以下命令

```bash
npm i --legacy-peer-deps

npm run dev
```

### 3. 前端运行成功标志

显示如下内容，则说明前端运行成功：

```text
> gsk@0.0.0 dev
> vite

[vite] (client) Re-optimizing dependencies because vite config has changed

VITE v6.1.0  ready in 414 ms

Local:   http://localhost:5181/
Network: http://192.168.1.9:5181/
Network: http://26.26.26.1:5181/
press h + enter to show help
```

## 后端

### 1. 获取 API Key

以阿里百炼平台（目前业界云平台用阿里云较多）为例：

```text
https://www.aliyun.com/product/bailian
```

在阿里百炼控制台中进入 API Key 页面，点击“创建我的 API-KEY”。

### 2. 打开 backend

使用代码编辑器（VS Code、PyCharm 等）打开 `backend` 目录。

### 3. 命令行运行以下命令

```bash
# 创建虚拟环境
conda create -n deepdimension python=3.11
conda activate deepdimension

# 启动 docker
docker compose -f docker-compose-base.yml up

# 配置你的 api key
export DASHSCOPE_API_KEY="your_api_key_here"

cd app

# 安装相应包
python -m pip install -r requirements.txt

python app_main.py
```

## 如何启动 Docker？

### 在 Linux 上

确保 Docker 服务已启动：

```bash
sudo systemctl start docker
```

通常可以设置开机自启：

```bash
sudo systemctl enable docker
```

通过命令执行 `docker ps`，验证是否正常运行；若能看到容器列表（空列表也可以），说明 Docker 已经启动。

### 在 Windows / macOS 上

1. 启动 Docker Desktop 应用程序（在应用菜单中点击 Docker Desktop 图标）。
2. 等待其启动并在系统通知区（Windows）或菜单栏（macOS）出现 Docker 的小鲸鱼图标，表示 Docker 服务已经就绪。
3. 打开终端、PowerShell 或者 CMD，执行：

```bash
docker ps
```

若无报错，表示已成功启动。
