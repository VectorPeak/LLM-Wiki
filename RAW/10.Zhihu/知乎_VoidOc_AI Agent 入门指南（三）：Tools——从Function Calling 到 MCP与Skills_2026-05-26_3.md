---
title: "知乎_VoidOc_知乎文章搜索剪藏_2026-05-26_3"
source: "zhihu official api + tikhub"
author:
  - "VoidOc"
published:
created: 2026-05-26
range: "3"
description: "知乎官方 API 定位，TikHub 补全文，共 6 条，本文件收录第 3 篇。"
tags:
  - "clippings"
  - "zhihu"
  - "VoidOc"
---
## 三、AI Agent 入门指南（三）：Tools——从Function Calling 到 MCP与Skills

> 更新日志：2026.1.19 补充Skills相关内容
🧑‍友情提示：本篇文章约1.1w+字，完整阅读需要19分钟左右。

### 一、背景
哈喽各位小伙伴👋，欢迎回到我的AI Agent专栏。

让我们快速回顾前两篇文章：

[AI Agent 入门指南（一）：综述](https://zhuanlan.zhihu.com/p/1991985667622840199)[AI Agent 入门指南（二）：LangChain](https://zhuanlan.zhihu.com/p/1992600416882537114)

前两篇我们聊了 Agent 是什么、LangChain 怎么搭架子。

那么接下来，咱们来唠一唠Agent中工具模块的技术实现与发展，来拆解一下 Agent 是如何一步步实现「动手干活」的。

---
还记得我们第一次聊 Agent 时说的那个例子吗？

“帮我订一张明天去杭州的高铁票。”

传统 AI 会回你：“你可以去 12306 查。”
而一个真正的 Agent 会直接动手：查余票、选座位、下单、发邮件通知你——全程不用你抬一根手指。

![image](https://pic2.zhimg.com/v2-cc59c22761639074c688da665cc78a09_1440w.jpg)

又到了我爱的配图环节

**那它是怎么做到的？**

答案就藏在这四个模块的**Loop**里：

![image](https://pic1.zhimg.com/v2-3f5afc4c28becc880876386f3e34a27a_1440w.jpg)

前两项让它「想得明白」，后两项让它「干得漂亮」。

而今天我们要聊的 **Tools（工具）**，就是 Agent 的「手」——没有它，再聪明的大脑也只能干瞪眼。

### 二、什么是Tools？
别被“工具”这个词吓到。它没那么高大上——在AI Agent领域

**本质上，Tool 就是一个带说明书的函数**。

比如：

- 你想知道天气 → 调用 `get_weather(city="北京")`
- 你想画一只猫 → 调用 `generate_image(prompt="一只穿西装的橘猫")`
- 你想查公司财报 → 调用 `query_database(table="financials", year=2025)`

![image](https://pic1.zhimg.com/v2-81188e56a8cc0fbe3754f8e424e8ffee_1440w.jpg)

Qwen-Image Edit 2511画的

但关键在于：**Agent 不能靠猜来调用这些函数**。它需要明确知道：

- 这个工具有什么用？（功能描述）
- 需要传什么参数？（输入 Schema）
- 返回什么格式？（输出结构）

这就引出了一个核心问题：**大模型怎么“决定”调用哪个工具、传什么参数？**

它不能说：“嗯……我觉得应该查一下天气。”——这没法执行。
它必须输出一段**机器能直接解析的指令**，比如：
```json
{
  "name": "get_weather",
  "arguments": {
    "city": "杭州"
  }
}
```
这种能力，就是我们接下来要聊的——**Function Calling（函数调用）**。

### 三、Function Calling
**📚 推荐阅读：**

- OpenAI 官方博客：[《Function Calling and Other API Updates》（2023）](https://link.zhihu.com/?target=https%3A//openai.com/index/function-calling-and-other-api-updates/%3Fspm%3D5176.28103460.0.0.96a07551Pus1NB)
- OpenAI 官方文档：[https://platform.openai.com/docs/guides/function-calling](https://link.zhihu.com/?target=https%3A//platform.openai.com/docs/guides/function-calling)

2023 年，OpenAI 在 GPT-4 中悄悄埋下了一颗炸弹：**Function Calling**。

在此之前，想让 LLM 调用外部服务，基本靠“Prompt 工程 + 正则解析”——堪称玄学。

你写一百遍“请严格按照 JSON 格式输出”，它还是可能回你一句：“好的！我这就帮你查杭州天气～☀️”。

但 Function Calling 的出现**改变了游戏规则**。

它的核心思想很简单：**把工具注册成函数签名，让模型在推理时直接生成函数调用**。

模型经过**微调**，能够根据用户输入判断是否需要调用函数，并输出符合函数签名的 JSON 对象。

这是一种**更可靠地将 LLM 能力与外部工具/API 连接起来的新方式**。

开发者可以借此实现：

- **构建能调用外部工具的聊天机器人**（例如类似 ChatGPT 插件的功能）
- 将“给 Anya 发邮件，问问她下周五要不要一起去喝咖啡”这样的请求转换为函数调用，如 `send_email(to: string, body: string)`；
- 或将“波士顿现在的天气怎么样？”转换为 `get_current_weather(location: string, unit: 'celsius' | 'fahrenheit')`。
- **将自然语言转换为 API 调用或数据库查询**
- 将“本月我的前十位客户是谁？”转换为内部 API 调用，例如 `get_customers_by_revenue(start_date: string, end_date: string, limit: int)`；
- 或将“Acme 公司上个月下了多少订单？”转换为 SQL 查询，如 `sql_query(query: string)`。
- **从文本中提取结构化数据**
- 定义一个名为 `extract_people_data(people: [{name: string, birthday: string, location: string}])` 的函数，用于从维基百科文章中提取所有提及的人物信息。

上面的case可以通过OpenAI在OpenAPI `/v1/chat/completions` 接口新增的 `functions` 和 `function_call` 参数实现。开发者通过 **JSON Schema** 向模型描述函数，并可选择强制模型调用特定工具。

**举个栗子 🌰：**

你告诉模型有以下工具可用：
```python
tools = [
  {
    "type": "function",
    "function": {
      "name": "search_web",
      "description": "搜索互联网获取最新信息",
      "parameters": {
        "type": "object",
        "properties": {
          "query": {"type": "string", "description": "搜索关键词"}
        },
        "required": ["query"]
      }
    }
  }
]
```
然后你问：“马斯克最近在搞什么？”

GPT-4 不会直接编答案，而是返回：
```json
{
  "tool_calls": [
    {
      "function": {
        "name": "search_web",
        "arguments": "{\"query\": \"Elon Musk latest news\"}"
      }
    }
  ]
}
```
你的程序拿到这个结构化输出，立刻就能调用 `search_web("Elon Musk latest news")`，再把结果喂回去——**整个过程干净、可靠、可复用**。

![image](https://pica.zhimg.com/v2-74f42691af63547c9b7ad2b96241d8ba_1440w.jpg)

OpenAI官网上另一个function calling的例子

Function Calling 的出现，让 Agent 真正具备了**可落地的行动能力**。

但它也有局限：**每个平台（比如OpenAI、Anthropic、Google）都有自己的调用格式，工具无法跨平台复用**。
就像 USB-C 出现前的充电口：苹果用 Lightning，安卓用 Micro-USB，谁也别想通用。

于是，2024 年底，一个新的协议横空出世：**MCP**。

### 三、MCP协议
**📚 推荐阅读：**

- MCP官方文档：[What is the Model Context Protocol (MCP)? - Model Context Protocol](https://link.zhihu.com/?target=https%3A//modelcontextprotocol.io/docs/getting-started/intro)
- GitHub 项目：[https://github.com/modelcontextprotocol](https://link.zhihu.com/?target=https%3A//github.com/modelcontextprotocol)

---
**什么是MCP？**

**MCP（Model Context Protocol）** 是由 **Anthropic 牵头**，联合多家 AI 基础设施厂商与开源社区共同发起制定的一套**开放标准协议**。

> 官方定义**：MCP (Model Context Protocol) is an open-source standard for connecting AI applications to external systems. ** Using MCP, AI applications like Claude or ChatGPT can connect to data sources (e.g. local files, databases), tools (e.g. search engines, calculators) and workflows (e.g. specialized prompts)—enabling them to access key information and perform tasks.
Think of MCP like a USB-C port for AI applications. Just as USB-C provides a standardized way to connect electronic devices, MCP provides a standardized way to connect AI applications to external systems.

说人话就是：你可以把 **MCP 想象成 AI 应用的 “USB-C 接口”**

让任意 AI 应用，都能调用任意符合 MCP 规范的工具，无论模型来自哪家、工具部署在何处。就像USB接口让手机、电脑、显示器、充电器之间即插即用。

MCP 自 2024 年底正式发布以来，已获得包括 **Hugging Face、阿里魔搭社区 ModelScope、LlamaIndex、Ollama、Vercel AI SDK** 等主流生态的广泛支持。

项目已在 GitHub 以 MIT 许可证开源，并提供多语言 SDK（TypeScript、Python、Java、Kotlin、C#），并建立了活跃的社区讨论区和工具注册广场。

---
MCP 的架构设计兼顾**灵活性、安全性与可扩展性**，主要包含四大核心组件：

| 组件 | 说明 |
| --- | --- |
| Tool Manifest（工具清单） | 类似 OpenAPI，使用标准化的 YAML/JSON 描述工具的能力：名称、功能描述、输入参数 Schema、输出格式、权限要求等，让 Agent “看得懂”工具能做什么。 |
| Transport Layer（传输层） | 支持 HTTP、gRPC、WebSocket 等多种通信协议，适配从本地开发、云端服务到边缘设备的各种部署场景。 |
| Context Propagation（上下文透传） | 自动携带用户身份（User ID）、会话标识、认证令牌等上下文信息，确保工具调用过程安全、可审计、可追踪。 |
| Dynamic Discovery（动态发现） | Agent 启动时可主动询问：“你有哪些工具？” 工具服务实时返回可用能力清单。Agent 再根据当前任务动态选择最合适的工具——这才是真正的 “即插即用” 体验。 |

如果说早期的 Function Calling（如 OpenAI 的函数调用）是“各家自建村头小路”，那么 MCP 就是想修一条“国道”。

### 四、技能 Skills
有些小伙伴私信问我那25年底开始火热🔥的skills概念和MCP又是什么关系？我来补充解答一下：

**Agent 领域的 「Skills（技能）」概念**是**由 Anthropic **公司于 2025 年10月提出、12月正式开源的，是一种用于增强大语言模型（LLM）智能体（Agent）在特定任务中专业能力的**结构化、模块化知识封装机制**。

它的核心目标是：**让通用大模型在需要时，按需加载并执行高度专业化的工作流程或领域知识，而不是一次性塞入所有信息**。

本质上是领域专业知识的打包：一个 Skill 是一个**本地文件夹**，必须包含 `SKILL.md` 文件。

下面是一个 Skill 目录结构的例子：
```
test-skill/
├── SKILL.md (required)
├── reference.md (optional documentation)
├── examples.md (optional examples)
├── scripts/
│   └── helper.py (optional utility)
└── templates/
    └── template.txt (optional template)
```
`SKILL.md`分三层：

- 第一层（YAML 前置元数据）：`name`、`description`，初始化即加载；
- 第二层（Markdown 主体）：详细操作步骤、规则、示例，按需激活；
- 第三层（可选链接文件）：如脚本、参考文档、模板等，运行时按需调用。

下面是一个SKILL.md的例子：
```python
---
name: my-skill-name
description: Brief description of what this Skill does and when to use it
---

# Skill Name

### Instructions
Provide clear, step-by-step guidance for Claude.

### Examples
Show concrete examples of using this Skill.
```
**Skills vs MCP：**

简单来说：MCP负责“连接”，Skills负责“执行”。可以把MCP看作是让AI能拿到工具，而Skills是教AI如何用好这个工具。

- MCP提供与外部工具或系统的连接能力，相当于赋予 AI 「拿到工具」的权限；
- Skills 则定义了「如何正确使用这些工具」，即具体的执行逻辑与业务规则。

最佳实践：二者结合使用效果最佳。比如：先通过MCP让AI连接到公司数据库，再调用一个“数据可视化Skill”，AI能自动从数据库提取数据并生成符合公司标准的分析报告。

---
**🙋 这里会有人问：那为什么不再封装一个“数据可视化”的MCP？**

**这是一个非常关键且深刻的问题！它触及了MCP 与 Skills 的设计哲学差异和AI 工具集成的分层逻辑。**

因为「数据可视化」往往不是一个原子工具能力，通常是个包含多步骤、且需上下文理解的复杂任务流程，比如有时候想要先做数据清洗再画饼图、有时候需要数据补缺再做多树状图对比，等等。

—— 而这正是 Skills 擅长的领域！

 MCP 更适合封装单一、确定性的工具能力（如“查询数据库”或“调用图表 API”）。

目前，Agent Skills 已成为 AI 工程化（AI Engineering）和智能体开发新范式中的关键组件之一。最后总结一下为什么MCP虽然生态已经很丰富了，但我们还是需要Skills的原因：

- **解决 Token 爆炸**：企业场景常有数十上百个工具，全量描述会耗尽上下文；
- **避免“烟囱式 Agent”**：不再为每个业务新建独立 Agent，而是构建一个通用 Agent 基座 + 多个可复用 Skills；
- **降低专业门槛**：非技术人员也可编写 `SKILL.md` 来封装领域 SOP；
- **提升可靠性与可维护性**：技能模块化，便于测试、更新、共享和迁移。

### 五、实战练习
#### 实战1: 创建你的第一个 MCP 工具
**目标**：实现一个**本地启动的天气查询 MCP 服务**，并通过客户端成功调用 `get_weather` 工具获取真实天气数据。

**步骤 1：注册 OpenWeatherMap 账号并获取 API Key**

- 访问 [https://home.openweathermap.org/users/sign_up](https://link.zhihu.com/?target=https%3A//home.openweathermap.org/users/sign_up)
- 注册账号并登录。
- 进入 [API Keys 页面](https://link.zhihu.com/?target=https%3A//home.openweathermap.org/api_keys)
- 复制你的 API Key（例如：`abc123def456...`）

**步骤 2：编写 MCP 天气工具代码（以Python函数为例）**

创建文件 `weather_mcp_real.py`（放在 `examples/mcp_servers/weather_mcp_server` 下或其他位置）。

⚠️：FastMCP 是构建 MCP 服务器和客户端的标准框架，使用简洁的 Python 代码即可创建工具、公开资源、定义提示词等：它实现了所有复杂的协议细节和服务器管理，开发者可以专注于MCP服务本身的工具实现。FastMCP 提供高级接口，且是python风格的，在大多数情况下，您只需装饰一个函数即可将您的项目封装为MCP Server。
```python
"""
real weather query example using OpenWeatherMap API.

Run from the repository root:
    uv run examples/mcp_servers/weather_mcp_server/weather_mcp_real.py
"""

import os
import httpx
from mcp.server.fastmcp import FastMCP

# Create an MCP server
mcp = FastMCP("RealWeatherService", json_response=True)

# Get API key from environment variable
OPENWEATHER_API_KEY = os.getenv("OPENWEATHER_API_KEY")
if not OPENWEATHER_API_KEY:
    raise EnvironmentError("Please set the OPENWEATHER_API_KEY environment variable.")

BASE_URL = "https://api.openweathermap.org/data/2.5/weather"

@mcp.tool()
def get_weather(city: str) -> dict:
    """
    Get current weather for a city using OpenWeatherMap API.

    Args:
        city (str): Name of the city (e.g., "London", "Beijing").

    Returns:
        dict: Contains temperature (°C), condition, humidity, and city name.
              On error, returns {"error": reason}.
    """
    try:
        params = {
            "q": city,
            "appid": OPENWEATHER_API_KEY,
            "units": "metric"  # 返回摄氏度
        }
        response = httpx.get(BASE_URL, params=params, timeout=10.0)
        data = response.json()

        if response.status_code == 200:
            return {
                "city": data["name"],
                "temperature": round(data["main"]["temp"]),
                "condition": data["weather"][0]["description"].capitalize(),
                "humidity": data["main"]["humidity"]
            }
        elif response.status_code == 404:
            return {"error": f"City '{city}' not found."}
        else:
            return {"error": f"OpenWeather API error: {data.get('message', 'Unknown error')}"}

    except httpx.RequestError as e:
        return {"error": f"Network error: {str(e)}"}
    except Exception as e:
        return {"error": f"Unexpected error: {str(e)}"}

@mcp.prompt()
def weather_outfit_advice(city: str) -> str:
    """Generate a prompt asking for outfit advice based on real-time weather."""
    return f"Given today's weather in {city}, what should I wear? Be specific and practical."

if __name__ == "__main__":
    mcp.run(transport="streamable-http")
```
**步骤 3：设置环境变量**

在运行前，必须设置你的 API Key：

Linux/macOS
```bash
export OPENWEATHER_API_KEY='your_actual_api_key_here'
```
Windows (PowerShell)
```
$env:OPENWEATHER_API_KEY = "your_actual_api_key_here"
```
> 🔒 安全提示：**不要**将 API Key 写死在代码中，也不要提交到 Git！

**步骤4: 启动服务并测试**

Python版本的MCP servers开发过程用uv管理是最连贯的，本文全程以uv命令演示。
```bash
# 1、安装uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 初始化项目目录
  uv init weather_mcp_server && cd weather_mcp_server

# 创建隔离环境并激活
uv venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# 安装核心依赖
uv add "mcp[cli]"

# 启动服务
uv run examples/mcp_servers/weather_mcp_server/weather_mcp_real.py
```
启动服务后，MCP 服务器默认监听 `http://127.0.0.1:8000`（具体看日志）。

另外，你需要一个支持使用 MCP 协议调用工具的 LLM 应用程序，即“MCP 客户端”，例如 Cherry Studio、Claude Desktop、Cursor 、Cline 或其他自定义客户端

你可以通过 MCP 客户端调用 `get_weather` 工具，传入城市名如 `"Tokyo"`。

示例返回：
```json
{
  "city": "Tokyo",
  "temperature": 12,
  "condition": "Light rain",
  "humidity": 72
}
```
#### 实战2: 探索魔搭社区MCP广场
如果你希望自己开发的MCP服务被更多人看到，或者学习更多MCP实战，可以了解一下魔搭社区ModelScope。

先甩两个开箱即用的教程：

[一个案例带你实现自己的MCP，打包PyPI并部署到魔搭 MCP 广场](https://link.zhihu.com/?target=https%3A//www.modelscope.cn/learn/1487)[一个案例带你基于Gradio实现创空间MCP，同步到MCP广场](https://link.zhihu.com/?target=https%3A//www.modelscope.cn/learn/1489)

以及魔搭 x Datawhale 的系列课程：[Task1：从零开发MCP Server【Datawhale AI夏令营】](https://link.zhihu.com/?target=https%3A//modelscope.cn/learn/1436%3Fpid%3D1434)

![image](https://pica.zhimg.com/v2-0a86cbe6537318172cc260a2549f081a_1440w.jpg)

再不够的，更多保姆级的视频教程！：[学了100小时后，我才发现学习MCP的最佳方式是这个！](https://link.zhihu.com/?target=https%3A//modelscope.cn/learn/1491%3Fpid%3D1441)

![image](https://picx.zhimg.com/v2-fb28b83e3f499a080df091defdf601d3_1440w.jpg)

真的，包的兄弟，包你学会MCP的。

不得不说，魔搭真的是个很好用的国产AI开源社区 ～

---
### 六、结语
随着 MCP 等协议的普及，「工具」正在从**代码片段**演变为**可发现、可组合、可计费的服务单元**。

就像今天的 SaaS 一样，我认为，在未来 **工具即服务（Tools-as-a-Service）将会成为 AI Agent 生态的基础设施。**

没有工具，Agent 只是“嘴强王者”；有了工具，它才真正拥有改变现实的能力。

那么先暂停一下！来恭喜你一下！

![image](https://pica.zhimg.com/v2-b0e556a0e980208936a4c46629276e94_1440w.jpg)

你今天不仅理解了 Function Calling 的机制，还亲手写了一个 MCP 工具，已经站在了AI Agent的起跑线上了！

下一站，我们将聊聊 **Memory（记忆）**：如何让 Agent 不只记得这一轮对话，还能记住你几个月前说过“讨厌香菜”。

也欢迎关注我的专栏，点个关注不迷路～

[AI Agent入门指南](https://www.zhihu.com/column/c_1990066103146267877)

**声明**

- 所有文章都为本人的学习笔记，非商用，
- 目的只求在工作学习过程中通过记录，梳理清楚自己的知识体系。
- 文章或涉及多方引用，如有纰漏忘记列举，请多指正与包涵。
