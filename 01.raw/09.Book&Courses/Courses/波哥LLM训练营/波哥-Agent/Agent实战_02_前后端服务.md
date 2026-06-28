# 【Agent实战-第2天】前后端服务

## 后端

### 1. `.env` 中配置 API key 和 Serper key

需要在 `.env` 文件中配置模型服务 key 和 Serper key。截图中主要标出了两个配置项：

- DashScope 模型服务 key：在 `.env` 中填写对应的 DashScope key。
- Serper 检索服务 key：在 `.env` 中填写对应的 Serper key。

API key 配置方法：  
【RAG实战-第3天】前后端服务运行

Serper key 配置网页：  
https://serper.dev/

页面中进入 **API Key** 菜单，可以查看或重置 Serper 的 API Key。

### 2. 起服务

代码块启动 docker：

```bash
docker compose -f docker-compose-base.yml up

# 创建虚拟环境
conda create -n agent python=3.11
conda activate agent

# 配置你的 key
export DASHSCOPE_KEY="<your-key-here>"

cd app

# 安装相应包
python -m pip install -r requirements.txt

python app_main.py
```

如何启动 docker：  
【RAG实战-第3天】前后端服务运行

## 前端

前端项目目录中可以看到以下结构和文件：

```text
FRONTEND
├── .husky
├── mock
├── node_modules
├── public
│   ├── pricing
│   ├── logo_48.ico
│   ├── logo_64.ico
│   ├── logo_128.ico
│   ├── logo.ico
│   ├── pricing.html
│   └── vite.svg
├── src
├── .env
├── .gitignore
├── .lintstagedrc
├── .prettierignore
├── .prettierrc
├── eslint.config.js
├── index.html
├── package-lock.json
├── package.json
├── README.md
├── tsconfig.app.json
├── tsconfig.json
└── tsconfig.node.json
```

先删除这个文件：

```text
package-lock.json
```

然后执行：

```bash
npm install
npm run dev
```

terminal 中会出现访问链接。
