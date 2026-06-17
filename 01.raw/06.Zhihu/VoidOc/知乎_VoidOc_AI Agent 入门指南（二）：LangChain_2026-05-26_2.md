---
title: "知乎_VoidOc_知乎文章搜索剪藏_2026-05-26_2"
source: "zhihu official api + tikhub"
author:
  - "VoidOc"
published:
created: 2026-05-26
range: "2"
description: "知乎官方 API 定位，TikHub 补全文，共 6 条，本文件收录第 2 篇。"
tags:
  - "clippings"
  - "zhihu"
  - "VoidOc"
---
## 二、AI Agent 入门指南（二）：LangChain

> 🧑‍友情提示：本篇文章约1.2w+字，完整阅读需要21分钟左右。

### 一、背景
LangChain 是怎么来的？一个被 ChatGPT 改变命运的 Side Project。

今天，LangChain 的官方定义是：

> “LangChain is the platform for agent engineering. ”
**一个专为智能体开发打造的工程平台。**

但其实故事开始于 2022 年 10 月，彼时的 LangChain 也还只是个“边角料”开源项目。

那时候 Harrison Chase 还只是个刚从哈佛毕业没多久的程序员。他在 GitHub 上推送了一个只有 **800 行代码**的小项目，起名叫 **LangChain**。对他来说，那只是当时一个解决自己痛点的 side project：**“为什么每次用 LLM，都要重复写一堆胶水代码？”**

当时他想做的，其实很简单：把提示词、模型调用、输出解析这些琐碎操作，封装成可复用的组件。

一个月后，OpenAI 发布 **ChatGPT**，一切都变了。

世界突然意识到：LLM 不只是实验室里的玩具，而是能真正干活的新生产力范式。于是开发者们蜂拥而至，试图在 LLM 之上构建应用——但他们很快撞上同一堵墙：**原始 API 太“裸”，做点复杂事就得手搓轮子**。这时，LangChain 出现在了 Reddit 和 Hacker News 的热帖里。人们发现：这个小框架，居然把他们头疼的问题都解决了。GitHub Star 数在几周内从几百飙到几万。

资本很快就嗅到了信号。于是在 2023 年初，他们就成立了公司；种子轮刚结束一周，红杉领投的 2000–2500 万美元 A 轮就到账了，估值直冲 2 亿美元。那个曾经在宿舍敲代码的学生，一跃成为硅谷最炙手可热的 AI 初创 CEO。

但 LangChain 的真正野心，不止于“易用”。

早在 2022 年 10 月，Harrison 和团队就在论文[《ReAct: Synergizing Reasoning and Acting in Language Models》](https://link.zhihu.com/?target=https%3A//arxiv.org/abs/2210.03629)中埋下伏笔——他们相信，未来的 LLM 应用不该只是被动应答，而应能**主动思考、调用工具、迭代修正**。LangChain 最初的版本，就是 ReAct 理论的工程实现。

于是，一场持续三年的“自我颠覆”开始了：

- 2022 年底：LangChain 0.x 发布，主打 “易用” ——让任何人五分钟搭出聊天机器人。
- 2024 年初：LangGraph 诞生，转向 “控制” ——支持循环、状态、持久化，Agent 终于能“停下来想想”。
- 2025 年中：推出 DeepAgents，追求 “深度” ——支持子智能体、文件系统、长程规划。
- 2025 年末：LangChain 1.0 正式发布，口号却是 “回归本质” ——底层全面重构为 LangGraph，但 API 更简洁。

### 二、LangChain 的工作原理
LangChain 的定位其实很明确：**提供一组标准化、可互换的构件，让你自由组装 LLM 应用**。

这背后是两条设计哲学：

- Everything is a Runnable：每个组件（Prompt、LLM、Parser、Tool）都是一个 `Runnable`，可以用 `|` 管道符串联。
- Composition over Inheritance：不要继承，要能组合。

这种设计，让你既能快速搭出原型，也能在需要时深入每一层，不被框架绑架。

下面我们来看看 LangChain 在 0.x 时期就已经打下的六大核心模块——它们至今仍是理解整个生态的基石。

下面我们来看一下 LangChain 0.x 时期包含的主要模块：

#### 1）Prompts（提示词）
早期的 LangChain 很大程度上是在探索提示工程（prompting）的各种技巧，和所有在这个领域摸索的人一样，边做边学。所以早期 LangChain 的痛点之一，是提示词藏得太深。

但基于 **PromptTemplate（提示词模版）**后，一切显式化：
```python
from langchain.prompts import ChatPromptTemplate

# 显式定义消息模板
prompt = ChatPromptTemplate.from_messages([
    (「system」, 「你是一个严谨的数学助手，只回答计算结果。」),
    (「human」, 「{question}」)
])
```
现在，变量插值（`{question}`）、动态消息占位（比如插入历史对话）、Few-shot 示例，甚至不同模型的输入格式适配，都成了开箱即用的能力。

但问题来了：LLM 输出的往往是“自由散漫”的字符串，而你的程序需要的是**结构化数据**。这时候，**OutputParser（输出解析器） **解决了这个问题：
```python
from langchain.output_parsers import JsonOutputParser
from pydantic import BaseModel

class MathResult(BaseModel):
    expression: str
    result: float

parser = JsonOutputParser(pydantic_object=MathResult)

# 构建带格式指令的链
chain = prompt | llm | parser
```
LangChain 还考虑到了更多：

- RetryOutputParser：解析失败时自动重试
- PydanticOutputFixingParser：尝试修复格式错误
- 自定义 Parser：完全掌控解析逻辑

#### 2）Model（模型）
OpenAI、Anthropic、Ollama、Llama.cpp……每个模型提供商都有自己的 API 风格、参数命名、流式协议。今天用 GPT-4，明天想试试 Claude，后天本地跑个 Llama 3——改代码成本高得吓人。

从一开始他们就清楚：未来 LLM 的选择会非常多样。尤其在这样一个快速变化的行业中，帮助用户灵活选择模型、并在未来轻松切换，至关重要。

LangChain 做了一件看似简单却极有价值的事：**统一接口**。
```python
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic

# 切换模型？只需改一行
llm = ChatOpenAI(model=「gpt-4o-mini」)
# llm = ChatAnthropic(model=「claude-3-haiku」)
```
它的特点是：

- 支持聊天模型（`ChatModel`）和纯文本模型（`LLM`）
- 本地模型（通过 Ollama、LlamaCpp 等集成）
- 内置流式输出、回调（callbacks）、缓存、重试等能力
- 所有模型都是 `Runnable`，可直接接入链式流程

无论底层是谁，你的链式逻辑不变。 **切换模型，只需改一行代码。**

在我看来，**模型中立性**至今仍是 LangChain 框架的核心优势之一。

#### 3）Chains（链）
单个组件再强大，也干不了复杂活。LangChain 0.x 的答案是：**Chain**。

你可以把它理解为「预定义的工作流模板」。比如：

- `LLMChain`：最基础的“提示 + 模型”组合；
- `SequentialChain`：多步骤串联，上一步的输出是下一步的输入；
- `TransformChain`：插入任意 Python 函数做数据清洗或逻辑判断；
- `RetrievalQA`：自动从知识库检索 + 生成答案；

这些 Chain 让开发者不用每次都从零拼接逻辑，**快速搭建常见模式**。

#### 4）**Agents（代理）**
LangChain 基于 **ReAct（Reason + Act）** 范式，让 LLM 在“思考 → 调用工具 → 观察结果 → 再思考”的循环中解决问题。0.x 时代已支持多种Agent 策略：

- `zero-shot-react-description`：零样本推理 + 工具描述；
- `conversational-react-description`：适合多轮对话；
- `self-ask-with-search`：通过自问自答分解问题。

依赖 `AgentExecutor` 负责驱动整个执行循环（plan → act → observe），工具通过 `Tool` 或 `@tool` 装饰器定义。

#### 5）Memory（记忆）
最简单的聊天机器人，三轮对话就忘了你是谁。

LangChain 提供了多层次的记忆策略，**按需选择，避免浪费 token**：

- `ConversationBufferMemory`：全量记住（适合短对话）；
- `ConversationSummaryMemory`：用 LLM 自动生成历史摘要（省空间，但比较费 token）；
- `VectorStoreRetrieverMemory`：只检索和当前问题相关的对话片段（RAG 思路）。

这些 Memory 对象通常作为参数传入 Chain 或 Agent，支持短期和长期记忆机制，**让应用具备上下文感知能力**——这是构建真正“智能”交互的前提。

#### 6）**Indexing & Retrieval（索引与检索）**
LLM 的知识截止于训练数据，且无法访问你的私有文档。如何让它“知道”你公司的产品手册、客户合同、内部 Wiki？

答案是：**RAG（检索增强生成）**，而 LangChain 0.x 已经提供了完整的工具链用于构建 RAG 系统：

- **Document Loaders**：从 PDF、网页、Notion、数据库等加载原始内容；
- **Text Splitters**：用 `RecursiveCharacterTextSplitter` 等策略切分长文本；
- **Embeddings**：通过 OpenAI、Hugging Face 等生成向量；
- **Vector Stores**：FAISS（轻量本地）、Chroma、Pinecone（云服务）存储向量；
- **Retrievers**：根据用户问题，召回最相关的文档片段。

但很快，开发者发现：**基于 Chains 的线性流程不够用了。**

### 三、Chains：起点、辉煌与局限
如果说 LangChain 是一座大厦，那么 **Chains 就是它的第一块砖**。

在 2023 年，`LLMChain`、`SequentialChain`、`TransformChain` 这些名字几乎出现在每一个 LangChain 教程里。它们代表了一种朴素而强大的思想：

**把 LLM 应用拆解成一系列线性步骤，像流水线一样串联起来。**

比如一个简单的问答系统：
```python
# 1. 用 PromptTemplate 构造问题
# 2. 用 LLM 生成回答
# 3. 用 OutputParser 提取 JSON
chain = prompt | llm | parser
```
这种 `|` 管道操作符带来的**声明式编程体验**，让开发者第一次感受到：“原来 LLM 应用也可以像普通程序一样组合、测试、复用。”

**Chains 的三大贡献**

- 标准化接口：所有组件（Prompt、LLM、Parser）都实现 `Runnable` 接口，可以用同一套方式调用、嵌套、流式处理。
- 快速原型能力：5 行代码就能搭出带记忆的聊天机器人，10 行能做 RAG 问答——这极大降低了 LLM 应用的入门门槛。
- 社区生态爆发：因为 Chains 结构清晰，社区迅速贡献了数百个预置链（如 `SQLDatabaseChain`、`ConversationalRetrievalChain`），形成正向循环。

**Chains 让 LangChain 从“玩具”变成了“工具箱”。**

**但 Chains 有个致命缺陷：它是线性的**

Chains 的底层模型是 **有向无环图（DAG）**——数据只能单向流动，不能回头，不能循环，也无法根据中间结果动态调整路径。

这在简单任务中不是问题。但一旦任务需要 **“观察 → 决策 → 行动 → 反思”** 的闭环，Chains 就立刻捉襟见肘。

一个真实的崩溃现场

当你想构建一个智能客服助手，支持用户说：“帮我查一下上周订单，如果没发货就取消。”

理想流程应该是：

- 理解意图：用户想查订单 + 可能要取消
- 调用工具：查询订单状态 → 返回“未发货”
- 自主决策：既然未发货，执行取消
- 反馈结果：“已为您取消订单 #12345”

但在 Chains 范式下，你必须**提前写死所有分支**：

- 如果你先查订单再决定是否取消，那 Chain 就得包含“条件判断”节点——但 Chains 本身不支持运行时跳转。
- 如果你让 LLM 一次性输出所有操作，它可能漏掉步骤，或生成非法指令。

更糟的是，**Chains 没有“记忆中间状态”的机制**。第二步的结果无法被第三步可靠引用，除非你手动把它塞进上下文——而这又会迅速耗尽token。

于是，开发者开始 hack：用 while 循环包裹 chain，手动管理状态……

代码很快变成“胶水+状态机+字符串拼接”的混合体，**既难测试，也难扩展**。

社区的声音越来越响：

> “我想控制提示，不是被提示控制。”
“我们需要真正的 Agent 运行时！”

Harrison 和团队听到了。

### 四、LangChain 生态演进
![image](https://pic4.zhimg.com/v2-8072bd14644dd1db0525f2c34367931d_1440w.jpg)

#### **2024 初：LangGraph 的诞生——**可控性 × 状态持久化。
LangGraph 的诞生源于早期 LangChain 的局限。当初为了让 LangChain 成为新手入门好上手的工具，选择封装好很多高层接口，但牺牲了灵活性，如今在用户试图定制并投入生产时成了障碍。

团队意识到：**易用和可控，不该是非此即彼的选择题**。

于是，在认真消化了 2023 年社区大量反馈后：包括避免破坏性变更、显式化隐藏提示、精简依赖、以及最重要的：**给予开发者更高的控制权**——LangGraph 诞生了。

它聚焦在两件事情上：

- **可控性（Controllability）**：没有隐藏的提示，没有隐式的上下文工程。你对自己的系统——无论是工作流、智能体，还是介于两者之间的任何东西——拥有完全控制权。
- **运行时（Runtime）**：将生产环境中所需的一切（流式响应、状态管理、人在环路、持久化执行等）以原生方式集成进 LangGraph。

**Agent，终于能好好干活了。**

#### 2024 中：LangFlow 出现 —— 让非程序员也能“搭 Agent”
LangFlow 官网：[HTTPS://www.langflow.org/](https://link.zhihu.com/?target=https%3A//www.langflow.org/)

GitHub：[HTTPS://GitHub.com/logspace-ai/langflow](https://link.zhihu.com/?target=https%3A//github.com/logspace-ai/langflow)

就在 LangGraph 解决“控制”问题的同时，另一个痛点浮出水面：**Agent 开发太依赖代码**，非技术人员难以参与其中。

> 产品经理想改提示词？得找研发。
设计师想调整交互流？得找研发。
业务人员想接入新数据源？还是得找研发。

![image](https://pic4.zhimg.com/v2-f0aeccb8eee2d3895f45b8c9e144128f_1440w.jpg)

2024 年中旬，社区孵化出 **LangFlow** ——一个基于 LangChain 的**开源可视化编排平台**。用于拖拽式构建 AI 智能体（Agents）与工作流（Workflows）而设计。

![image](https://pica.zhimg.com/v2-fcb4a945141d19044a785664edde914c_1440w.jpg)

LangFlow 将 LangChain 的核心组件（如 `LLM`、`PromptTemplate`、`Memory`、`Tools`、`Chains` 等）转化为直观的 UI 节点。你只需：

- 拖一个 Chat Input
- 连一个 Prompt Template
- 接一个 LLM
- 再挂一块 Memory

再点击“Run”，一个带记忆的聊天机器人就活了。（简单点理解，就是将 LangChain 的 Python 逻辑“图形化”）

更关键的是，它导出的**不是一张静态图，而是可运行的代码或 JSON 配置**。这意味着开发者可以无缝接手、继续迭代，真正打通“原型 → 产品”的闭环。也正因如此，LangFlow 迅速被集成进 **Hugging Face Spaces**、**魔搭（ModelScope）** 等主流 AI 社区，甚至成为许多企业内部的 **Agent 快速验证平台**。

LangFlow 奉行 “batteries included” 理念，开箱即用，原生支持：

- 主流大语言模型：OpenAI、Anthropic、Google Gemini、Ollama 等
- 向量数据库：Pinecone、Weaviate、Qdrant、Chroma 等
- 丰富 AI 工具链：网络搜索、PDF/Word 解析、代码执行、API 调用等

除此之外，LangFlow 还提供一套完整的能力闭环：

- 源码级自由：所有组件均可切换至 Python 视图，深度自定义逻辑，满足开发者对灵活性的需求。
- 交互式 Playground：实时运行、逐步调试、即时预览输出，大幅缩短“试错 → 优化”周期。
- 多智能体编排：支持子 Agent 协同、对话状态管理与检索增强，轻松构建复杂协作系统。
- 一键发布为 REST API，供前端或外部服务调用
- 部署为 **MCP（Model Context Protocol）Server**，将工作流转化为标准 MCP 工具，能被任何 MCP 客户端（Client）（如 Cursor、Continue 等）直接使用

今天，LangFlow 已成为 LangChain 官方推荐的可视化方案，GitHub Star 超 30k，是生态中增长最快的工具之一。

#### 2025 中：Deep Agents —— 让 Agent 不再“浅尝辄止”
2025 年夏天，LangChain 团队做了一个决定：他们不再优化 Agent 的速度或工具调用次数，而是教它「慢下来、写下来、拆开来」。

这一转变，不是凭空而来。它来自几款正在重塑行业认知的产品带来的震撼：

- [Claude](https://link.zhihu.com/?target=https%3A//claude.ai/) Code 能从一行需求出发，自动生成带测试、部署脚本和完整文档的 Web 应用；
- [Manus](https://link.zhihu.com/?target=https%3A//manus.im/) 可以撰写数十页的行业分析报告，每一步推理、每一份数据都留下可追溯的文件痕迹；
- Deep Research 能力在主流 LLM 中逐渐普及，让“深度探索”不再是实验室里的幻想。

它们共同指向一种新范式——**深度（Depth）**：

> 不是在“思考 → 工具 → 思考”之间快速打转，
而是能**长时间沉浸于复杂任务**，产出可交付、可审计、可迭代的真实成果。

**什么时候需要使用 Deep Agents 呢？**

当你需要构建具备以下能力的 Agent 时，可选用 Deep Agents：

- 处理需要规划与任务拆解的复杂、多步骤任务
- 通过文件系统工具管理大量上下文信息
- 将工作委派给专用子智能体，实现上下文隔离
- 在不同对话和线程间持久化记忆

对于更简单的场景，更建议使用 LangChain 的 `createAgent`，或直接构建自定义的 LangGraph 工作流。

![image](https://picx.zhimg.com/v2-8cae9af7d87c0f4c82af7eeafd081323_1440w.jpg)

Customize your Deep Agent

LangChain 将这种范式正式命名为 **Deep Agents**，因为它具备以下特点：

**1. 🧠 规划与任务分解**

Deep Agents 内置 `write_todos` 工具，使智能体能够：

- 将复杂任务拆解为具体步骤
- 跟踪任务进度
- 根据新信息动态调整计划

**2. 📁 上下文管理**

提供文件系统工具（`ls`、`read_file`、`write_file`、`edit_file`），允许智能体将大段上下文“卸载”到外部存储，从而：

- 避免 LLM 上下文窗口溢出
- 支持处理长度可变的工具输出

**3. 👥 子智能体生成（Subagent Spawning）**

内置 `task` 工具可让主智能体**动态创建专用子智能体**，用于处理特定子任务。这既能保持主智能体上下文简洁，又能深入完成复杂子任务。

**4. 💾 长期记忆**

通过 LangGraph 的 **Store** 功能，可为智能体添加跨线程的**持久化记忆**——智能体能保存信息，并在后续对话中检索历史内容。

#### 2025 末：LangChain 1.0 —— 站在 LangGraph 的肩膀上
尽管 LangGraph 已被广泛采用，但它对新手来说门槛不低。与此同时，团队注意到：社区对 LangChain 的热情从未减退——这说明它所解决的问题，依然真实存在。

所以，他们在规划**新版 LangChain 1.0** 时，定了三个目标：

- **让构建 AI Agent 尽可能简单**
- **提供比以往更强的定制能力**
- **内置一个真正生产就绪的运行时**

经典的重构时间到，老手艺人了🐶

![image](https://pic4.zhimg.com/v2-3fe98cf786606d8ff61660e008eeff61_1440w.jpg)

与其零敲碎打，不如一步到位。所以 **LangChain 1.0** 完成了一次釜底抽薪

具体怎么做？简单收敛一下就是：

- 聚焦于如今已成为智能体“标准范式”的**工具调用循环（tool-calling loop）**，围绕它重新设计核心流程；
- 引入全新的**“中间件”（middleware）机制**，专门让开发者在提示工程、工具调用、响应生成等关键节点精准介入，掌控每一步逻辑；
- 并将 LangGraph 作为默认运行时，原生支持**流式输出、持久化执行、[人在环路（HITL）](https://link.zhihu.com/?target=https%3A//baike.baidu.com/item/%25E4%25BA%25BA%25E6%259C%25BA%25E5%259B%259E%25E5%259C%2588/57454067)**等企业级能力。

发布的 LangChain 1.0，正是对这三个目标的回应。它不仅更强大，也更清晰——为超过百万的开发者提供了一个更聚焦、更一致的技术主张。而老的 LangChain 0.x 系列，则更名为 **langchain-classic**，也没有甩手掌柜了，而是会继续长期维护（鼓掌👏👏👏）

**新用户直接学 1.0，老用户平滑过渡。**

![image](https://picx.zhimg.com/v2-83e5c26f56a8075a2945b81024073859_1440w.jpg)

核心生态演进时间线总结

而且全新的统一文档站点（[Home - Docs by LangChain](https://link.zhihu.com/?target=https%3A//docs.langchain.com/)）也正式上线了！ 齐活儿！

#### LangSmith——Agent 构建平台
除此之外，LangChain 团队还做了 LangSmith。 LangSmith 是他们于 2023 年夏天就同期推出（beta 版）并且慢慢迭代的商业 SaaS 平台（也支持免费体验），可以理解为“调试器 + CI/CD + 监控仪表盘”（也支持自托管 self-host）。

![image](https://picx.zhimg.com/v2-ec9c59225ba632f92e55a1441ec33bc9_1440w.jpg)

 LangSmith Interface

LangSmith 专注于 LLM 应用的可观测性、测试、评估和部署，而且它可以解耦合于 LangChain ——也就是说，你可以不使用 LangChain 而直接使用 LangSmith（例如用纯 OpenAI API 或其他框架构建应用、甚至不用任何框架）。它对 LLM 中立，对底层框架中立，延续了团队“开放、可组合”的工具哲学。

![image](https://pic4.zhimg.com/v2-9450c79e8803de24b99ec3345fa10f4d_1440w.jpg)

LangSmith 能力框架图

#### 生态关系总结
**LangGraph：**独立的 runtime 库，提供底层图执行引擎与状态管理；你可以完全不用 LangChain，只用 LangGraph + 原生 LLM 调用（如 OpenAI API）来构建智能体。官方示例中有大量“纯 LangGraph”项目（例如 [langgraph-py/examples](https://link.zhihu.com/?target=https%3A//github.com/langchain-ai/langgraph/tree/main/examples) 中的 `chatbot.py` 只用了 `@app.add` 和自定义函数）。

**LangChain：**更上层的 Agent Framework，提供抽象层（如 ChatModel, LLM）、中间件、工具封装（Tools, Toolkits）等高层接口。从 LangChain 0.2+ 版本开始，其新一代 Agent 架构（如 `create_react_agent`, `create_tool_calling_agent`）底层默认使用 LangGraph 作为执行引擎。

但 LangChain 的其他部分（如 Chains、Retrievers）可以独立于 LangGraph 运行。

**DeepAgents：**是一个**独立的 Agent 套件库**，专为构建能处理深度、多步骤任务而设计。它**不修改底层运行时逻辑**，而是基于 LangGraph 和 LangChain 的能力进行组合与增强。DeepAgents 构建在 LangGraph 之上 + 深度集成了 LangChain 的组件生态，无需重复造轮子。但它本身是一个可选的上层库。LangChain 或 LangGraph 的用户可以选择是否引入 DeepAgents，就像选择是否使用某个高级 Agent 模板。

**LangSmith：**独立的智能体构建平台，专注于可观测性、调试、评估与部署。不参与智能体的运行逻辑，而是作为**外部服务**。

**LangFlow：**独立的可视化编排构建平台，专注于拖拽式编排与快速原型开发，不参与运行时逻辑，而是通过生成可执行代码或 API 与 LangChain/LangGraph 原生集成。

![image](https://picx.zhimg.com/v2-d3907435030d5dd28f5c9145ca4734ab_1440w.jpg)

LangChian生态关系一览图

### 五、LangChain 实战代码
光说不练假把式。我们来动手写一个能用的智能体，顺便把前面讲的几个关键能力串起来：

#### 任务一：**构建一个**天气预报 Agent
**第一步：安装环境依赖**
```bash
pip install langchain langchain-openai langchain-community
```
**第二步：先定角色，写好系统提示**

智能体的行为很大程度上由 system prompt 决定。别写得太虚，要具体、可执行：
```python
SYSTEM_PROMPT = 「」「你是个爱讲双关语的天气预报员。

你有两个工具可以用：
- get_weather_for_location：查某个城市的天气
- get_user_location：获取用户当前位置

如果用户问“外面天气怎么样”，说明他想知道自己的位置天气，先调 get_user_location 拿到位置再说。」「」
```
**第三步：接外部数据，写两个工具**

工具就是普通函数，加上 `@tool` 装饰器就行。注意第二个工具用了运行时上下文（比如用户 ID）：
```python
from dataclasses import dataclass
from langchain.tools import tool, ToolRuntime

@tool
def get_weather_for_location(city: str) -> str:
    「」「查天气，简单模拟返回」「」
    return f「{city} 永远阳光灿烂！」

@dataclass
class Context:
    user_id: str  # 运行时传进来的上下文

@tool
def get_user_location(runtime: ToolRuntime[Context]) -> str:
    「」「根据 user_id 返回位置」「」
    return 「Florida」 if runtime.context.user_id == 「1」 else 「SF」

# 工具的函数名、参数名和 docstring 都会被自动塞进模型提示里，所以命名要清晰，注释别偷懒。
```
**第四步：配置 LLM 模型**

选个模型，调好参数。（不同模型支持的参数不一样，记得查对应文档。）
```python
from langchain.chat_models import init_chat_model

model = init_chat_model(
    「claude-sonnet-4-5-20250929」,
    temperature=0.5,   # 控制随机性
    timeout=10,        # 超时时间
    max_tokens=1000    # 最大输出长度
)
```
**第五步：定义结构化输出（可选但推荐）**
```python
from dataclasses import dataclass

@dataclass
class ResponseFormat:
    punny_response: str          # 必须有双关语
    weather_conditions: str | None = None  # 天气详情，可选
```
这样模型输出就会被强制解析成这个结构，避免自由文本带来的解析麻烦。

**第六步：加上记忆（可选）**
```python
from langgraph.checkpoint.memory import InMemorySaver

checkpointer = InMemorySaver()
```
上线时换成数据库持久化（比如 Redis、PostgreSQL），这里就不展开了。🔗 完整代码参考：[官方 Quick Start](https://link.zhihu.com/?target=https%3A//docs.langchain.com/oss/python/langchain/quickstart)

**第七步：组装 & Run！**

现在把所有零件拼在一起：
```python
from langchain.agents.structured_output import ToolStrategy

agent = create_agent(
    model=model,
    system_prompt=SYSTEM_PROMPT,
    tools=[get_user_location, get_weather_for_location],
    context_schema=Context,
    response_format=ToolStrategy(ResponseFormat),
    checkpointer=checkpointer
)

# 启动一次对话（thread_id 唯一标识会话）
config = {「configurable」: {「thread_id」: 「1」}}

# 第一轮：用户问天气
resp = agent.invoke(
    {「messages」: [{「role」: 「user」, 「content」: 「外面天气怎么样？」}]},
    config=config,
    context=Context(user_id=「1」)
)
print(resp[『structured_response』].punny_response)
# 输出示例：佛罗里达今天依然是“阳光普照”！……

# 第二轮：继续聊
resp = agent.invoke(
    {「messages」: [{「role」: 「user」, 「content」: 「谢谢！」}]},
    config=config,
    context=Context(user_id=「1」)
)
print(resp[『structured_response』].punny_response)
# 输出示例：你真是“雷”厉风行地客气！……
```
同一个 `thread_id` 就是一次完整对话，中间状态（比如已知用户在 Florida）会自动保留。

**恭喜你，你刚刚亲手造了一个会“动脑筋”的 AI Agent！**

- 理解上下文并记住对话历史
- 智能调用多个工具
- 以一致的结构化格式返回结果
- 通过运行时上下文处理用户专属信息
- 在多轮交互中维持对话状态

> 更多：如果想通过 **LangSmith** 追踪你的Agent 运行状态，可以参考 [LangSmith 官方文档](https://link.zhihu.com/?target=https%3A//docs.smith.langchain.com/)。

### 六、结语
LangChain 的成长，没有太多戏剧性的转折，更像是一群工程师在面对真实问题时，一步步把“重复造轮子”的苦活，变成了可复用的积木。它最初只是想少写几行胶水代码，后来却成了很多人构建 AI Agent 的第一站。

从 Chains 到 LangGraph，再到 DeepAgents，它的演进路径清晰而克制：先让流程跑起来，再慢慢补足能力，让它能思考、能暂停、能协作、能持久运行。

学习 AI Agent 的路还长，但至少现在，我们有了一个不错的起点。

---
如果你对相关内容感兴趣，我会在 **《AI Agent 入门指南》系列专栏** 中持续更新，带大家一起深入：

- [AI Agent 综述](https://zhuanlan.zhihu.com/p/1991985667622840199)
- Agent 工具调用机制（MCP / Function Calling）详解
- Dify、扣子、Manus、Flowith 等热门 Agent 产品的对比与实战
- 企业级 Agent 系统的架构设计与权衡

等各项技术细节，点个关注不迷路～

---
**参考资料**：

- LangChain 官网：[Home - Docs by LangChain](https://link.zhihu.com/?target=https%3A//docs.langchain.com/)
- LangChain 官方 GitHub： [HTTPS://Python.langchain.com/](https://link.zhihu.com/?target=https%3A//python.langchain.com/)
- [《LangChain 三年回顾：从框架演进看 Agent 开发的本质与未来》](https://zhuanlan.zhihu.com/p/1987961895190290867)
- 人在环路(HITL)：[人机回圈](https://link.zhihu.com/?target=https%3A//baike.baidu.com/item/%25E4%25BA%25BA%25E6%259C%25BA%25E5%259B%259E%25E5%259C%2588/57454067)

**声明**

- 所有文章都为本人的学习笔记，非商用，
- 目的只求在工作学习过程中通过记录，梳理清楚自己的知识体系。
- 文章或涉及多方引用，如有纰漏忘记列举，请多指正与包涵。
