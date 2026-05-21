---
title: "手写Agent框架②：LangChain / LangGraph 选型指南"
source: "https://mp.weixin.qq.com/s/PXcUxKabu774wC4HSlhfuQ"
author:
  - "[[兰笺记]]"
published:
created: 2026-05-16
description: "本文为手写Agent框架系列第2篇，深入解析核心机制"
tags:
  - "clippings"
---
兰笺记 *2026年4月26日 09:00*

## 专题02：LangChain vs LangGraph 选型指南

> **调研依据**
> 
> ：综合自 WeNowdays 完整对比指南、MyEngineeringPath 视觉对比指南、TrueFoundry 官方博客、LangChain 官方文档、ThirdEyeData 企业 AI 对比研究、Peliqan 技术博客等第三方可靠来源。

## 一、先搞清楚两者的关系

LangChain 和 LangGraph 不是竞争关系，而是 **层级关系** ：

```
┌─────────────────────────────────┐
│         LangGraph               │  ← 基于 LangChain 封装的图状态管理框架
│         (Stateful Graph)        │
├─────────────────────────────────┤
│         LangChain               │  ← 底层基础库（LCEL、Prompt、Tool 接口）
│         (Chaining Primitives)   │
├─────────────────────────────────┤
│         LLM API                 │  ← OpenAI / Anthropic / 本地模型
└─────────────────────────────────┘
```

LangChain 官方文档明确说明：

> "LangGraph is built on top of LangChain but designed for **stateful, multi-agent, cyclic workflows**." — WeNowdays 引用 LangChain 官方文档

**核心关系** ：LangGraph 依赖 LangChain 的底层组件（LLM 调用、Tool 接口、Prompt 管理），但在上层提供了图结构的编排能力。

## 二、核心差异：一图说清楚

### 2.1 架构模型对比

|  | LangChain | LangGraph |
| --- | --- | --- |
| 编排模型 | **Chain（线性链）** | **Graph（图，有向有环）** |
| 执行流程 | 顺序执行，A→B→C→D | 节点+边，可循环、可分支 |
| 状态管理 | 无内置持久化 | 内置 Checkpointer |
| 控制流 | 固定顺序 | 条件路由、自由流转 |
| 循环支持 | 不支持（链是线性的） | 原生支持 |
| 多 Agent | 需要自己实现 | 内置多 Agent 协作机制 |

LangChain 的 Chain 模型适合 **线性流水线** ：

```
LangChain Chain（线性）:
Input → Prompt → LLM → Output
         ↓
      下一个 Chain

无法循环，无法状态回溯
```

LangGraph 的 Graph 模型适合 **有状态工作流** ：

```
LangGraph（可循环）:
  ┌──────┐
  ▼      │
Input → Node A → Node B ──┐
              ↓          │
           Node C ────────┘  ← 可以循环回去
              ↓
           Output
```

引用 MyEngineeringPath 的明确描述：

> "LangChain and LangGraph model workflows in fundamentally different ways — one as sequential pipelines, the other as state machines with cycles." — MyEngineeringPath, 2026

## 三、为什么"链"在某些场景不够用

### 3.1 Chain 的局限性

LangChain 的 Chain 模型在以下场景会遇到根本性限制：

| 场景 | Chain 能处理吗 | 说明 |
| --- | --- | --- |
| 简单 RAG | ✅ 可以 | 输入→检索→生成，线性三步 |
| 带工具调用的 Agent | ⚠️ 勉强 | 需要自己实现循环逻辑 |
| 需要重试的流程 | ❌ 不行 | Chain 失败只能从头重跑 |
| 暂停等人工确认 | ❌ 不行 | 没有中断机制 |
| 多步骤推理中间有分支 | ❌ 不行 | 无法条件跳转 |
| 状态需要持久化 | ❌ 不行 | 无 Checkpoint 能力 |

ThirdEyeData 的企业 AI 对比研究指出：

> "LangChain's chain-based approach works well for linear workflows but struggles with complex, branching logic that requires dynamic decision-making and state management." — ThirdEyeData, Enterprise AI Study

### 3.2 Graph 的优势

LangGraph 通过图结构解决了这些问题：

```
1. 循环（Cycles）：Agent 可以反复调用工具直到得到满意结果
2. 条件分支（Conditional Edges）：根据 LLM 输出决定下一步走哪条路
3. 状态持久化（Checkpointing）：每个步骤都可以保存快照，失败可回溯
4. 中断机制（Interrupts）：可以暂停等人工确认再继续
5. 多 Agent 共享状态：多个 Agent 可以读写同一个 State
```

## 四、什么时候选 LangChain

LangChain 仍然是以下场景的正确选择：

### 4.1 适用场景

| 场景 | 为什么适合 LangChain |
| --- | --- |
| 简单 RAG Pipeline | 线性三步：加载→检索→生成 |
| 单一 Prompt 模板 | 不需要状态管理 |
| 快速原型验证 | 上手快，文档丰富 |
| 简单 Chatbot | 单轮对话，不需要循环 |
| Prompt 串联测试 | 只需要按顺序调 LLM |

LangFlow 官方指南明确说明：

> "Use LangChain when the workflow is a straight line." — LangFlow Blog, 2025

### 4.2 LangChain 的优势

```
✅ 入门门槛低，API 简单直观
✅ 文档最丰富，社区最大
✅ 组件库最全（100+ Embeddings、50+ Vectorstores）
✅ 快速原型首选
✅ 适合学习和实验
```

## 五、什么时候选 LangGraph

LangGraph 是以下场景的唯一选择：

### 5.1 适用场景

| 场景 | 为什么必须用 LangGraph |
| --- | --- |
| Agent（带工具调用） | 需要 ReAct 循环：推理→行动→观察→推理 |
| 多轮对话（需要记忆） | 需要 Checkpointer 持久化 |
| 复杂条件分支 | 根据 LLM 输出决定下一步 |
| 需要人工确认 | interrupt() 中断机制 |
| 多 Agent 协作 | 共享 State，多节点通信 |
| 失败重试/回溯 | Checkpoint 可恢复状态 |
| 超时控制 | 每个步骤可设置超时 |

LangChain 官方文档明确指出使用 Checkpointer 的前提：

> "When invoking a graph with a checkpointer, you **must** specify a `thread_id` as part of the `configurable` portion of the config. Without it, the checkpointer cannot save state or resume execution after an interrupt." — LangChain 官方文档

### 5.2 LangGraph 的核心能力

```
✅ 有环图结构 → 支持 Agent 循环调用工具
✅ Checkpointing → 每个步骤状态可持久化
✅ Interrupt → 中断等待人工确认
✅ Conditional Edges → 条件路由，动态决策
✅ Multi-Agent → 多 Agent 共享状态
✅ Time Travel → 可回溯到历史 Checkpoint
✅ Super-step → 批处理节点保证原子性
```

## 六、选型决策树

```
你的工作流是线性的吗？（Input → A → B → C → Output）
    │
    ├── 是 → LangChain ✅
    │        └─ 快速原型 / 简单 RAG / 单步 Prompt
    │
    └── 否（需要循环/分支/状态/中断）
         │
         ├─ 需要 Agent 行为（工具调用/推理循环）？
         │    ├── 是 → LangGraph ✅
         │    │
         │    └─ 否 → 你的场景可能不需要图结构
         │          考虑：工作流是否真的需要循环？
         │
         └─ 需要状态持久化？
              ├── 是 → LangGraph ✅（Checkpoint 是 LangGraph 内置能力）
              │
              └── 否 → LangChain ✅（但要考虑未来是否需要升级）
```

引用 MyEngineeringPath 的选型建议：

> "Use LangGraph when your workflow has cycles (retrying or looping), when state must persist across process restarts or failures, when human approval is required mid-execution, when multiple agents must coordinate with shared state, or when complex conditional routing based on LLM outputs is required." — MyEngineeringPath

## 七、团队选型建议

### 7.1 初级 AI 团队

| 阶段 | 推荐方案 | 说明 |
| --- | --- | --- |
| 学习阶段 | LangChain | 理解 LLM 调用、Prompt、Tool 基本概念 |
| 原型阶段 | LangChain | 快速验证业务逻辑 |
| 升级生产 | LangGraph | 当需要 Agent 循环和状态管理时 |

**推荐路径** ：先用 LangChain 学基础，确认需要 Agent 行为后迁移到 LangGraph。

### 7.2 你们的业务场景分析

基于我们的讨论，你们的场景：

```
场景一：自主问答（客服/知识库）
  → 需要多轮对话记忆 → LangGraph Checkpoint ✅
  → 需要调用搜索工具 → LangGraph Agent Loop ✅
  → 结论：必须用 LangGraph

场景二：业务策略诊断
  → 需要多步骤分析 → LangGraph ✅
  → 可能需要人工确认 → LangGraph Interrupt ✅
  → 可能需要多 Agent 协作 → LangGraph Multi-Agent ✅
  → 结论：必须用 LangGraph
```

LangFlow 的建议：

> "Most production systems start with LangChain and migrate specific agent workflows to LangGraph when the need for statefulness becomes clear." — LangFlow Blog

### 7.3 混用策略

| 组件 | 推荐方案 |
| --- | --- |
| LLM 调用 | LangChain（底层能力） |
| Prompt 管理 | LangChain（LCEL） |
| Tool 定义 | LangChain @tool 装饰器 |
| 状态管理和循环 | LangGraph StateGraph |
| 持久化 | LangGraph Checkpointer |
| 可视化调试 | LangGraph LangSmith |

**关键认知** ：LangGraph 内部调用 LangChain 的组件，两者天然兼容。

## 八、版本选择建议

```
LangChain:   >= 0.2.x（LCEL 稳定）
LangGraph:   >= 0.2.x and < 1.0（生产稳定性，当前推荐区间）
             0.1.x（如果需要极致稳定）
```

LangGraph 官方文档中 Checkpointer 相关接口在 0.2.x 版本已稳定，PostgresSaver、RedisSaver 等生产级存储均已支持。

## 九、选错框架的典型后果

| 选错 | 后果 |
| --- | --- |
| 场景简单却用 LangGraph | 过度工程化，学习曲线陡峭，代码复杂 |
| Agent 场景却用 LangChain | 自己实现循环/状态/重试，全是坑，最后还是得迁移 LangGraph |
| 团队初级却用复杂框架 | 维护成本高，出问题难排查 |

引用 TrueFoundry 的总结：

> "LangChain remains an excellent choice for rapid development and straightforward applications, while LangGraph opens the door to sophisticated, production-grade AI systems that can handle complex real-world requirements." — TrueFoundry Blog

## 十、快速自检清单

学完本专题，你应该能回答：

```
□ LangChain 和 LangGraph 的层级关系是什么？
□ Chain 模型和 Graph 模型的核心区别是什么？
□ LangChain 的局限性在哪些场景会暴露？
□ 什么场景必须用 LangGraph？
□ 你们的两个业务场景（问答 + 诊断）应该选哪个？
□ 两者可以混用吗？分别用在哪些层？
□ 初级 AI 团队的学习路径应该是什么？
```

## 十一、参考资料

WeNowdays - LangChain vs LangGraph: A Complete Educational Guide for AI Developers  
https://wenowadays.com/blogs/langchain-vs-langgraph-a-complete-educational-guide-for-ai-developers-2025

MyEngineeringPath - LangChain vs LangGraph Visual Comparison Guide  
https://myengineeringpath.dev/tools/langchain-vs-langgraph/

TrueFoundry - LangChain vs LangGraph: Compare Features & Use Cases  
https://www.truefoundry.com/blog/langchain-vs-langgraph

LangChain Official Docs - Persistence  
https://docs.langchain.com/oss/python/langgraph/persistence

ThirdEyeData - A Comparative Study Between LangGraph and LangChain for Enterprise AI  
https://thirdeyedata.ai/agentic-ai-solutions/a-comparative-study-between-langgraph-and-langchain-for-enterprise-ai-development/

LangFlow Blog - The Complete Guide to Choosing an AI Agent Framework in 2025  
https://www.langflow.org/blog/the-complete-guide-to-choosing-an-ai-agent-framework-in-2025

Peliqan - LangChain vs LangGraph Explained  
https://peliqan.io/blog/langchain-vs-langgraph/

继续滑动看下一个

AI通识记

向上滑动看下一个