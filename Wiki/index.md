---
type: meta
title: "LLMWiki Index"
created: 2026-05-05
updated: 2026-05-19
status: developing
tags:
  - meta
  - index
related:
  - "[[overview]]"
  - "[[hot]]"
  - "[[log]]"
sources: []
raw_bucket: ""
source_path: ""
---

# LLMWiki Index

本页是知识库主索引。每次摄取、创建、重命名或删除重要 Wiki 页面后，都应更新本页。

## Core Entrypoints

- [[overview]]: 全库定位、结构和当前状态总览。
- [[hot]]: 最近上下文缓存，供 `/Query` 的 quick/standard 模式优先读取。
- [[log]]: Wiki 维护操作日志，新记录写在顶部。

## Current Status

- `Schema` 规则层已建立，包括结构、frontmatter、摄取、查询、lint、风格和来源策略。
- 已摄取 `RAW/06.Website`、`RAW/09.Wechat` 的 Agent/RAG/大模型/算法面试资料子集、`RAW/03.Self-Notes`、`RAW/05.Research` PDF、`RAW/07.BookCourse` PDF。
- `RAW/09.Wechat` 已完成来源层去重入库：96 个原始 Markdown 中 95 个 source 页面有效覆盖，1 个重复 RAW 标注在主来源页中。
- 已将 GitHub 项目原始语料规则调整为本地生成 GitMD-style RAW，并新增 `RAW/04.GitHub` 项目采集件。
- PDF 抽取文本只保存在 `Clippings/.llmwiki-cache`，正式来源仍回指 `RAW` 原始文件。

## Domains

- [[大模型底层原理]]
- [[算法与编程基础]]
- [[隐私保护与删除权]]
- [[智能体工程支架领域]]
- [[Agent 与 RAG 工程面试]]
- [[AI 编程工具与 Agent 产品]]

## Projects

- [[LangChain]]
- [[LangGraph]]
- [[LlamaIndex]]
- [[RAGFlow]]

## Methods

- [[传统机器学习面试准备框架]]
- [[大模型学习路径]]
- [[工程支架设计]]
- [[深度学习学习路径]]
- [[生产级 Agent 系统设计]]
- [[生成器-评估器循环]]
- [[算法学习路径]]
- [[隐私保护协议评估]]
- [[自然语言处理学习路径]]
- [[Agent 面试准备框架]]
- [[Agent Context 文件评估]]
- [[AI 编程工具面试准备]]
- [[Embedding 与 Rerank 选型方法]]
- [[LLM 推理优化方法]]
- [[LM Evaluation Harness 工程]]
- [[PDF 解析与 OCR 预处理]]
- [[Prompt 工程]]
- [[RAG 工程摄取链路]]
- [[RAG 效果评估]]

## Concepts

- [[残差连接]]
- [[大模型预训练与微调]]
- [[多模态 RAG]]
- [[反向传播]]
- [[父子 Chunk]]
- [[删除权通知分发协议]]
- [[上下文交接]]
- [[神经网络基础]]
- [[数据结构与算法]]
- [[长程智能体]]
- [[智能体可读性]]
- [[Agent 记忆系统]]
- [[Agent 架构]]
- [[Agent 人工干预]]
- [[Attention Residuals]]
- [[Claude Code]]
- [[GRPO]]
- [[Hermes Agent]]
- [[KV Cache]]
- [[LangGraph 状态流转]]
- [[MCP 与 CLI]]
- [[MoE]]
- [[OpenClaw]]
- [[Prompt Cache]]
- [[RAG 文本分块]]
- [[ReAct]]
- [[Reflection]]
- [[Repository-Level Context Files]]
- [[RNN]]
- [[Spec-Driven Development]]
- [[Tool Calling]]
- [[Transformer]]
- [[Word2Vec]]

## Entities

- [[波哥聊大模型]]

## Sources

- [[10个必须会的机器学习算法-你会几个]]
- [[20个python基础问题-你会几个]]
- [[阿里面试官-bge-和-gte-的区别都说不清-rerank-模型怎么配的也不知道-你这-rag-是蒙着眼做的]]
- [[百度面试官-如何赋予-llm-规划能力]]
- [[聊聊ai系统的四层缓存架构]]
- [[深度学习150题-拿走不谢]]
- [[深度学习注意力机制大全-你知道几个]]
- [[手写agent框架②-langchain-langgraph-选型指南]]
- [[算法工程师要掌握这些技能]]
- [[字节面试官-为什么claude-code不用rag检索代码-而是用grep-我-因为...省钱-他沉默了三秒]]
- [[agent-interview-summary-1]]
- [[agent-summary-2026-03]]
- [[algo-column-100个transformer知识点]]
- [[algo-column-10个pytorch常用法-不会就不要学ai了]]
- [[algo-column-20个transformer常见知识点]]
- [[algo-column-30个transformer常见知识点]]
- [[algo-column-50个python常识问题-拿走不谢]]
- [[algo-column-大模型的量化技术]]
- [[algo-column-大模型的投机采样]]
- [[algo-column-大模型后训练30题]]
- [[algo-column-大模型面试题1]]
- [[algo-column-大模型面试题2]]
- [[algo-column-大模型面试题3]]
- [[algo-column-大模型位置编码50题]]
- [[algo-column-大模型agent20题]]
- [[algo-column-大模型kv-cache原理]]
- [[algo-column-大模型moe]]
- [[algo-column-多模态rag50题]]
- [[algo-column-多agent协同系统的分层分片策略]]
- [[algo-column-后训练-监督微调-强化学习]]
- [[algo-column-强化学习微调的-熵坍缩-现象]]
- [[algo-column-什么是多模态rag]]
- [[algo-column-手机端部署ai模型的技术路线]]
- [[algo-column-算法工程师需要掌握这些算法]]
- [[algo-column-推导reward-modeling中pairwise-comparison的loss]]
- [[algo-column-我是这样学习ai模型的]]
- [[algo-column-显存占用计算]]
- [[algo-column-小模型训练50题]]
- [[algo-column-agent问题10道]]
- [[algo-column-cnn要怎样才算精通]]
- [[algo-column-flashattention]]
- [[algo-column-pageattention]]
- [[algo-column-pytorch训练模型注意点]]
- [[algo-column-transformer必会知识点]]
- [[algo-column-transformer常见面试题]]
- [[algo-column-transformer常见知识点]]
- [[algo-column-transformer组成模块]]
- [[algo-column-yolo易混知识点]]
- [[algo-interview-100题-随机森林]]
- [[algo-interview-100题-xgboost]]
- [[algo-interview-200题-cnn]]
- [[algo-interview-20题-决策树]]
- [[algo-interview-20题-朴素贝叶斯]]
- [[algo-interview-30题-逻辑回归]]
- [[algo-interview-30题-rnn和lstm]]
- [[algo-interview-column-分类模型指标19问]]
- [[algo-interview-column-回归模型指标20问]]
- [[algo-interview-column-扩散模型diffusion50问]]
- [[algo-interview-column-无监督聚类30问]]
- [[algo-interview-column-python基础100题]]
- [[algo-interview-column-transformer100问]]
- [[algo-interview-column-yolo模型损失函数]]
- [[attention-residuals]]
- [[build-a-large-language-model-from-scratch]]
- [[careful-deletion-notification-protocol]]
- [[claude-code-self-note]]
- [[deep-learning-advanced-nlp]]
- [[deep-learning-from-scratch]]
- [[delrightguard-deletion-notification-protocol]]
- [[effective-harnesses-for-long-running-agents]]
- [[evaluating-agents-md-paper]]
- [[harness-design-for-long-running-application-development]]
- [[hello-algo-python]]
- [[hermes-agent-self-note]]
- [[langgraph-state-flow]]
- [[llm-算法面试30题汇总]]
- [[llm-微调面试100问]]
- [[llm-agent面试50问]]
- [[llm-algo-interview-门控机制50题]]
- [[llm-engineer-混合精度和全精度区别]]
- [[llm-engineer-评价rag项目效果]]
- [[llm-engineer-让大模型的回答更加多样化]]
- [[llm-engineer-主流大模型的解码策略]]
- [[llm-engineer-rag策略]]
- [[llm-engineer-rag流程与优化手段]]
- [[llm-engineer-rag在大模型中的作用]]
- [[llm-engineer-rag知识库如何构建]]
- [[llm-engineer-ragflow和llamaindex区别]]
- [[llm-harness工程20题]]
- [[llm-prompt工程60题]]
- [[ml-algo-决策树100问]]
- [[ml-algo-逻辑回归100问]]
- [[ml-algo-svm100问]]
- [[openai-harness-engineering-codex]]
- [[openclaw-self-note]]
- [[openspec-self-note]]
- [[production-agent-system-three-questions]]
- [[rag-chunking-strategy]]
- [[rag-engineering-chain]]
- [[rag-pdf解析难在哪-主流方案是什么]]
- [[react-reflection-memory]]
- [[sft-rag-interview]]
- [[trustnotify-deletion-notification-framework]]
- [[wechat-boge-26-年3月面试题总结-大模型推理优化与工程落地]]
- [[wechat-boge-26年3月面试题总结-大模型底层原理总结]]
- [[wechat-boge-26年3月面试题总结-大模型训练与微调总结]]
- [[wechat-boge-这一年我对-ai-求职这件事的几个判断]]
- [[wechat-boge-grpo]]
- [[wechat-boge-grpo-reward-hacking]]
- [[wechat-boge-rl]]
- [[wechat-boge-sft构造数据的一些经验]]

## Comparisons

- [[LangChain 与 LangGraph]]
- [[RAGFlow 与 LlamaIndex]]

## Questions

- [[如何赋予 LLM 规划能力]]
- [[如何让长程编码智能体稳定推进复杂任务]]
- [[如何设计生产级 Agent 的人工干预与 SSE]]
- [[如何选择 Embedding 和 Rerank 模型]]
- [[为什么代码检索不总是适合用 RAG]]
- [[GRPO 为什么可能出现 Reward Hacking]]
- [[LangGraph 状态流转需要定时拉状态吗]]
- [[RAG 文本分块为什么不是固定长度即可]]

## Logs

暂未摄取 `RAW/02.Logs`。按使用者要求，本轮跳过日志资料。

## Meta

- [[index]]
- [[overview]]
- [[hot]]
- [[log]]
- [[lint-report-2026-05-14]]
- [[lint-report-2026-05-19]]
