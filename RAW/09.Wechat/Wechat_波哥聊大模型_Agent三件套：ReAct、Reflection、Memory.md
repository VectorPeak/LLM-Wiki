---
title: Agent三件套：ReAct、Reflection、Memory
source: https://mp.weixin.qq.com/s/OexdxbuTa3pDkNu0aV_k0g
author:
  - 波哥聊大模型
published:
created: 2026-05-07
description: 早期的 LLM 应用大多是&quot;一问一答&quot;：给定输入，模型输出一段文本，交互结束。但当任务变得复杂——需要访问外部工具、处理多步骤依赖、或者在执行中途纠正错误——单轮生成就力不从心了。
tags:
  - clippings
---

---

早期的 LLM 应用大多是"一问一答"：给定输入，模型输出一段文本，交互结束。但当任务变得复杂——需要访问外部工具、处理多步骤依赖、或者在执行中途纠正错误——单轮生成就力不从心了。

Agent 框架的出现正是为了应对这类挑战。一个 Agent 不仅能调用工具，还需要规划、执行、观察反馈，并在必要时调整策略。而支撑这些能力的，是三种经过充分研究的推理机制： **ReAct** （推理与行动交织）、 **Reflection** （自我反思与修正）、 **Memory** （跨步骤或跨会话的信息持久化）。

（想详细学习，可以看大模型训练营S2（详情 **了解可+v** **：** **Burger\_AI）的第七周）**

![图片](https://mmbiz.qpic.cn/mmbiz_png/kSX2Q9RM8CQCOOmLHU4ibyGEm0fKfvXFXpQGiasAoyOw3DvOeRxdtZckBNatrqer46kiblT8h4ggaQXxEByoRwEIPsJlRwO2oDyTvpdB3DgBto/640?wx_fmt=png&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=0)

这三种机制并非互斥，实际工程中往往组合使用。本文系统梳理它们的原理、实现方式与适用边界。

![img](https://mmbiz.qpic.cn/sz_mmbiz_jpg/kSX2Q9RM8CT7hIsUpLVVpVZsSECzgpfrqDIXkIUPOInqPzmpaCzqOcyPGuibuaYibCOWic6aoJgnkSXX4pWk1oY8Bsh6y1cML8nyh4x0tZrtwI/640?wx_fmt=jpeg&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=1)

img

## ReAct：将推理链与工具调用交织执行

### 核心思想

ReAct（Reasoning + Acting）由 Yao et al. (2022) 提出，核心想法是： **让模型在每次行动前先显式推理，在观察到行动结果后再继续推理** ，形成 `Thought → Action → Observation` 的循环。

与纯 Chain-of-Thought（CoT）相比，ReAct 的推理步骤不再只是内部语言游戏，而是和真实的外部操作（搜索、计算、API 调用）紧密耦合。与纯工具调用（如 function calling）相比，ReAct 保留了可解释的中间推理过程，便于调试和干预。

### 执行循环

```
Thought: 分析当前状态，决定下一步行动
Action: tool_name(args)
Observation: <工具返回的结果>
Thought: 根据观察更新理解，规划下一步
Action: ...
...
Final Answer: <最终输出>
```

每一轮 `Thought` 是模型对当前信息的内化与分析； `Action` 是对外部环境的操作； `Observation` 是环境反馈，直接拼接回 prompt 供下一轮使用。

### 代码示例（基于 LangChain 风格伪代码）

```
from langchain.agents import create_react_agent
from langchain_core.tools import tool

@tool
def search_web(query: str) -> str:
    """搜索互联网获取最新信息"""
    return web_search_api(query)

@tool
def python_repl(code: str) -> str:
    """执行 Python 代码并返回结果"""
    return exec_sandbox(code)

# 创建 ReAct Agent
agent = create_react_agent(
    llm=llm,
    tools=[search_web, python_repl],
    prompt=react_prompt_template  # 包含 Thought/Action/Observation 格式说明
)

# Agent 会自动循环执行，直到输出 Final Answer
result = agent.invoke({"input": "2024年全球AI芯片市场规模是多少？"})
```

### 局限性

ReAct 的主要问题是 **错误累积** ：一旦某步 `Thought` 判断有误，后续行动都会建立在错误前提上，且模型不会主动意识到偏差。此外，对于需要长距离规划的任务，每步只看"当前观察"的局部性也是瓶颈。

![img](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

img

## Reflection：让 Agent 审视并修正自身输出

### 为什么需要自我反思

ReAct 解决了"如何行动"的问题，但没有解决"如何判断行动是否正确"的问题。Reflection 机制引入了一个额外的评估步骤：模型（或独立的 critic 模型）对已有的输出或轨迹进行批评，再由 actor 模型根据反馈修改。

这一思路的代表工作包括：

- **Reflexion** （Shinn et al., 2023）：将反思结果以自然语言形式写入记忆，在下一次尝试时作为上下文输入
- **Self-Refine** （Madaan et al., 2023）：迭代地让模型对自身输出提供 feedback 并改写，无需外部信号
- **Critic-Actor 架构** ：将生成（Actor）和评估（Critic）分离为两个独立 LLM 调用，降低自我验证的确认偏差

### Reflexion 的记忆写入机制

Reflexion 的关键设计在于：反思结果不是临时的，而是 **写入持久化的语言记忆** ，在下一轮任务启动时读取。

```
Episode 1:
  尝试解题 → 失败
  Reflection: "我直接搜索了结果，但忽略了单位换算，导致数值错误。
               下次应该先确认单位再进行计算。"
  → 写入 memory

Episode 2:
  读取 memory 中的反思 → 在 Thought 中主动检查单位 → 成功
```

这与人类从错误中学习的过程高度一致：失败本身不产生学习，对失败的反思和归因才产生学习。

### 实现时的工程考量

**单模型 vs. 双模型** ：让同一模型既生成又反思存在确认偏差——模型往往会认为自己的输出是合理的。用独立的 critic prompt 甚至独立的模型实例，能有效缓解这一问题。

**反思粒度** ：粒度太细（针对每个 token）开销过大；粒度太粗（只在任务失败时反思）信号稀疏。实践中常以"步骤"或"子任务"为单位触发反思。

**终止条件** ：迭代反思如果不加限制，容易陷入无限循环或过拟合于某个错误的修正方向。需要设置最大迭代次数，并引入外部验证信号（如单元测试通过率、人工评分）作为停止依据。

```
def reflection_loop(task, actor_llm, critic_llm, max_iter=3):
    output = actor_llm.generate(task)

    for i in range(max_iter):
        # Critic 评估当前输出
        critique = critic_llm.evaluate(
            task=task,
            output=output,
            prompt="指出输出中的具体问题，说明如何改进"
        )

        # 如果 Critic 认为质量达标，提前终止
        if critique.is_satisfactory:
            break

        # Actor 根据 critique 修改输出
        output = actor_llm.refine(
            task=task,
            previous_output=output,
            feedback=critique.content
        )

    return output
```

## Memory：跨步骤与跨会话的信息持久化

### 记忆的四种类型

Agent 的记忆系统通常按 **持久化范围** 和 **检索方式** 分为四类，对应人类记忆的不同层次：

| 类型 | 存储位置 | 生命周期 | 典型用途 |
| --- | --- | --- | --- |
| **In-context Memory** | Prompt 上下文 | 当前会话 | 对话历史、中间结果 |
| **External Memory** | 向量数据库 / KV 存储 | 持久化 | 长期知识、用户偏好 |
| **Episodic Memory** | 结构化日志 | 持久化 | 过往任务轨迹、Reflexion 反思 |
| **Procedural Memory** | 模型权重（微调） | 永久 | 技能、格式、领域知识 |

实际 Agent 系统中最常用的是前两种，因为它们无需改变模型本身。

### In-context Memory 的管理

In-context Memory 受 token 窗口限制，需要主动管理：

**滑动窗口** ：只保留最近 N 轮对话，丢弃早期历史。简单但会丢失重要信息。

**摘要压缩** ：当历史过长时，用 LLM 将早期历史压缩为摘要，再拼接进 prompt。

```
def compress_history(messages: list, llm, threshold=4000) -> list:
    """当历史超过阈值时，压缩早期消息"""
    if token_count(messages) < threshold:
        return messages

    # 保留最近 10 轮，压缩更早的历史
    recent = messages[-10:]
    older = messages[:-10]

    summary = llm.invoke(
        f"将以下对话历史压缩为简洁摘要，保留关键信息：\n{format(older)}"
    )

    return [{"role": "system", "content": f"早期对话摘要：{summary}"}] + recent
```

**选择性保留** ：用模型或规则判断哪些消息"重要"（如包含用户偏好、关键决策），优先保留。

### External Memory 与 RAG 集成

External Memory 通常以向量数据库实现，与 RAG（Retrieval-Augmented Generation）架构天然契合：

```
写入路径：新信息 → Embedding 模型 → 向量数据库
读取路径：当前查询 → Embedding 模型 → 相似度检索 → 注入 Prompt
```

对于 Agent 场景，External Memory 的写入时机很关键：

- **任务完成后写入** ：将任务结果、Reflection 反思写入，供未来任务检索
- **实时写入** ：每个重要的 `Observation` 都持久化，适用于长期运行的 Agent
- **手动触发写入** ：用户或系统显式标记"值得记住"的信息

### 记忆检索的精度问题

向量相似度检索的精度并不总能满足需求。常见的改进策略：

**混合检索（Hybrid Search）** ：将语义相似度（向量）与关键词匹配（BM25）结合，提升精确匹配的召回率。

**时间衰减** ：为记忆条目附加时间戳，检索时对近期记忆给予更高权重，避免过时信息干扰当前决策。

**结构化元数据过滤** ：在向量检索前，先用结构化字段（任务类型、用户 ID、时间范围）做硬过滤，缩小检索空间。

## 三者的协同：一个完整 Agent 的推理栈

孤立地看，ReAct 负责执行、Reflection 负责修正、Memory 负责积累。在完整的 Agent 系统中，三者构成一个多层次的推理栈：

```
任务输入
  │
  ▼
[Memory 读取] ← 检索相关历史经验和 Reflection 笔记
  │
  ▼
[ReAct 执行循环]
  Thought → Action → Observation → Thought → ...
  │
  ▼
[Reflection 评估]
  是否达到目标？输出质量是否满足要求？
  │
  ├── 满足 → 输出最终结果
  │
  └── 不满足 → 生成反思笔记 → [Memory 写入] → 重试 ReAct
```

这个结构在 HumanEval、AlfWorld、WebShop 等基准上都有实验验证：三者组合的成功率显著高于任意单一机制。

**典型的工程取舍** ：

- 对于 **响应时延敏感** 的场景（如实时对话），Reflection 的迭代开销难以接受，可以省略，只保留 ReAct + 轻量 Memory
- 对于 **一次性任务** （如代码生成、报告撰写），Reflection 的多轮迭代带来的质量提升通常值得等待
- 对于 **长期运行的 Agent** （如自动化运营、持续监控），Memory 的设计是核心挑战，需要仔细考虑写入策略、检索精度和记忆老化

## 总结

ReAct 将推理与行动解耦但又显式关联，解决了纯 CoT 无法感知外部反馈的问题；Reflection 引入自我评估循环，让 Agent 能从失败中积累改进信号；Memory 提供跨步骤和跨会话的信息持久化，使 Agent 的能力随时间积累而非每次从零开始。

当前这三种机制仍有若干开放问题值得持续关注：Reflection 的评估信号质量（如何判断"反思是否准确"？）、Memory 的遗忘与更新策略（旧记忆如何老化而不干扰新任务？）、以及多 Agent 场景下记忆共享的一致性保证。这些问题既是工程挑战，也是当前学术研究的活跃方向。
