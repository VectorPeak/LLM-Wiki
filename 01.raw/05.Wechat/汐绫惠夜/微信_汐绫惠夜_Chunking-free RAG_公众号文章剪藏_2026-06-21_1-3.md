---
title: "微信_汐绫惠夜_检索增强_公众号文章剪藏_2026-06-21_1-3"
source: "/api/v1/wechat_mp/web/fetch_mp_article_detail_html"
author:
  - "汐绫惠夜"
published: "2026-06-18"
created: 2026-06-21
description: "TikHub 命中的微信公众号文章候选，共 3 条，本文档收录 3 条"
tags:
  - "clippings"
  - "wechat"
  - "汐绫惠夜"
---

## 0x01. 二十八：Chunking-free RAG
> 发布日期：2026-06-18  
> 原文链接：[二十八：Chunking-free RAG](https://mp.weixin.qq.com/s/cDXDzhn0aHhcLLrJDRb4gw)

### 1. 学习范围
 本日主题是 Chunking-free RAG，重点是 Chunking-Free 架构。传统 RAG 通常需要把文档切成 chunk，再对 chunk 做 embedding 和检索。Chunking-free RAG 试图减少或避免人工 chunking 对语义完整性、召回和上下文组织造成的损伤，让模型在更完整的文档上下文中定位和使用证据。

 本日覆盖：

 传统 chunk-based RAG 的基本假设和问题。

 Chunking-free RAG 的动机与定位。

 Landmark Embedding 的基本思想。

 Chunking-Free In-Context Retrieval 的核心流程。

 长上下文模型、位置标记、段落/句子级定位与证据选择。

 Chunking-free 与普通 RAG、long-context RAG、parent document retrieval 的关系。

 工程实现、评估指标、适用场景和限制。

#### 1.2 传统 Chunk-based RAG 的回顾
 传统 RAG 的典型流程是：
```text
Document -> Split into chunks -> Embed chunks -> Vector index
Query -> Embed query -> Retrieve top-k chunks -> Prompt -> Answer
```
chunking 的作用是把长文档拆成较短片段，便于向量化、索引和放入 prompt。但 chunking 会引入明显的工程选择：

 chunk size。

 overlap。

 分隔符和结构边界。

 标题是否拼入 chunk。

 表格、代码、公式如何切分。

 父子文档如何映射。

 这些选择会影响召回、上下文完整性、成本和答案忠实性。

#### 1.3 Chunking 的核心问题
 chunking 的主要问题包括：

 语义切断：一个完整论点被拆成多个 chunk。

 上下文丢失：chunk 命中但缺少标题、前提、定义或限制条件。

 噪声扩大：chunk 太大导致 embedding 混杂，召回不精确。

 边界敏感：答案正好跨 chunk 边界时容易漏召回。

 参数敏感：chunk size 和 overlap 需要针对数据集调参。

 结构破坏：表格、代码、法律条款、论文段落被切坏。

 重复召回：overlap 太大导致 top-k 被相似 chunk 占满。

 因此，chunking 并不是一个无害预处理步骤。它会改变文档作为知识单元的形态。

#### 1.4 Chunking-free RAG 的定位
 Chunking-free RAG 的目标是：“不提前对文档做固定离线切分”，在尽量保留完整文档或较大上下文结构的情况下，让系统能够定位与 query 相关的证据，并把相关证据提供给 LLM。

 它不是简单地“把所有文档塞进长上下文”。真正的 Chunking-free 思路通常包含：

 用特殊 embedding 或定位机制标记文档中的关键位置。

 在完整或大段文本中识别 query 相关区域。

 避免离线阶段固定切 chunk。

 在线阶段根据 query 动态选择证据位置或片段。

 保持更完整的原始文档结构。

 它和 long-context RAG 有交集，但不完全相同。long-context RAG 关注把更多内容放入上下文；Chunking-free RAG 关注不依赖预切 chunk 的检索和定位机制。

#### 1.5 Landmark Embedding(地标嵌入) 的基本思想
 传统分块 RAG 将文档预先切割为固定长度文本块，语义边界易被人为截断，跨块关联信息丢失；而 Chunking-free RAG 需要一套能在完整长文档内精准定位相关片段的编码方案， **Landmark Embedding(以 BGE Landmark 为代表)** 就是适配无分块检索的主流表征方案。

 BGE Landmark Embedding 相关工作关注在长文本中插入 landmark token 或 landmark 标记，使 embedding 模型能够感知和定位文档中的重要位置。直观理解是：不是把文档切成很多独立 chunk，而是在文档内部设置“地标”，让检索模型学习 query 与文档内部位置之间的关联。

 核心思想可以概括为：
```text
Document with landmarks -> Encode -> Landmark-aware representations
Query -> Encode -> Match query to relevant landmark/position
```
这样系统可以在长文档中定位相关区域，而不必完全依赖固定 chunk 边界。

 Landmark 的意义：

 保留文档整体上下文。

 提供位置级检索入口。

 缓解 chunk 边界切断问题。

 让检索结果能指向原文中的具体区域。

 具体来说：
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkiasMohENpIQmibLt4jOGAH93RV14QDde54ick2HpRspCXTSYnuw3VTMWxicLdsCs0w1ejPic1ZrNYgZI9Tyy7XSNw2PPn3vulY8jgI/640?wx_fmt=png&from=appmsg)
### 1. 离线文档预处理：插入地标 token
 不需要拆分文档，只做简单插入：

 把整篇完整长文按句子拆分；

 在 **每一句的结尾固定追加专用符号<LMK>** (词表中一个独立特殊 token，类似 [CLS]/[SEP])；

 如果全文长度超过 Embedding 模型最大输入上限，用 **滑动窗口** 滚动读取全文，窗口之间有重叠，全程不破坏原文顺序与结构。

 举个极简文本例子：原始段落：

 Bill paid a visit to Eiffel Tower on Sunday. He spent the morning exploring its details.

 插入地标后送入模型的输入：Bill paid a visit to Eiffel Tower on Sunday. <LMK> He spent the morning exploring its details. <LMK>

#### 1.2 模型编码：让<LMK>学会代表前面整句话语义
 把带一串<LMK>的完整长文本一次性送入 BGE-Landmark 编码器做全局编码：

 Transformer 会 **同时看到整段上下文**，每个<LMK>能感知前一句 + 前后相邻句子的全局语境；

 训练阶段专门优化：强制每个<LMK>的输出向量，等于 **它前面那整句话的语义表征**；

 编码完成后，从模型输出序列里， **单独提取每一个<LMK>对应的向量**，这个向量就叫 **LE(Landmark Embedding，地标向量)**。

 上面例子会产出 2 个独立地标向量：

 LE₁ = 第一个<LMK>向量 → 代表第一句话语义

 LE₂ = 第二个<LMK>向量 → 代表第二句话语义

#### 1.3 查询匹配：用地标做细粒度定位
 用户 Query 处理：问句末尾同样加<LMK>，编码取出最后一个 token 向量作为查询向量；

 相似度计算：拿 Query 向量，和文档里 **每一个 LE 地标向量** 算余弦相似度；

 匹配结果：相似度最高的那个 LE，对应原文里该<LMK>前面的句子，就是和问题最相关的局部区域。
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkgfga47R1TFAwj2JfFQDicQ3xha63nJg0J1xxO3A2UFhwIYr8D49w9S5Vt6tLStoWKiberwZWSHEYwQazcSba0HfvuKlue6Dzh30/640?wx_fmt=png&from=appmsg)
 与之前的Chunk分割区别在于，地标不是手动标注的关键词，不需要人工提取实体、关键句；并且全程不会破坏文档完整结构，离线阶段不会切分固定chunk，整篇文本连续输入，消除分块割裂语义的问题；并且将检索精度精细到了句子级。

 滑动窗口只是为适配模型长度，不是分块。窗口只是分批送入长文本，窗口间重叠、原文不截断，取出的地标依然保留全局上下文信息。

 地标向量自带原文位置映射。每个 LE 都记录了它在文档中的前后位置，检索命中后可以动态截取该句子 + 前后上下文送入 LLM，完美适配 Chunking-free RAG “在线动态选证据” 的需求。

#### 1.6 Chunking-Free In-Context Retrieval
 Chunking-Free In-Context Retrieval 关注在不进行传统 chunking 的情况下，让模型在上下文中完成检索。其核心目标是减少预处理阶段的人为分块，利用长上下文模型和检索机制在输入内部找到相关信息。

 一个高层流程可以表示为：
```text
Long document / collection
      |
Add markers / positions / structured boundaries
      |
Model or retriever identifies relevant spans
      |
LLM answers based on selected in-context evidence
```
与传统 RAG 的区别在于：传统 RAG 的基本检索单元是预先切好的 chunk；chunking-free 试图把检索单元转向位置、span、landmark 或动态片段。

 Landmark 地标标记是该检索方案最常用的底层技术手段，依靠 <LMK> 锚点实现上下文内细粒度 span 定位。

#### 1.7 Landmark、Span 与动态证据
 Chunking-free 系统通常需要解决两个问题：

 如何定位：query 对应文档中的哪些位置？

 如何提供证据：定位后给 LLM 多大范围的文本？

 定位可以是：

 landmark token。

 句子位置。

 段落位置。

 标题节点。

 token span。

 attention/score 高的位置。

 证据提供可以是：

 命中位置前后窗口。

 命中段落。

 命中章节。

 多个 span 合并。

 原文加高亮标记。

 chunking-free 并不意味着最终不给模型片段，而是避免离线固定 chunk，把片段选择推迟到 query-time 动态完成。

#### 1.8 与 Parent Document Retrieval 的关系
 Parent document retrieval 用小 chunk 检索，返回大 parent。Chunking-free RAG 与它有相似目标：缓解小 chunk 缺上下文的问题。

 区别：

 Parent document retrieval 仍然依赖离线 child chunk。

 Chunking-free 更强调不使用固定 chunk，或使用位置/landmark 替代 chunk。

 Parent document retrieval 更容易工程落地。

 Chunking-free 更依赖模型能力、长上下文能力或专门训练的 embedding。

 可以把 parent retrieval 看作 chunking-free 思想的工程折中：检索仍用 chunk，但生成尽量用完整父上下文。

#### 1.9 与 Long-Context RAG 的关系
 长上下文模型能容纳更多文本，但它不自动解决检索问题。直接把大量文档塞入 prompt 会带来：

 成本和延迟高。

 关键信息被稀释。

 模型忽略中间信息。

 引用和证据定位困难。

 无关信息干扰答案。

 Chunking-free RAG 可以利用长上下文，但仍需要位置定位、证据选择和忠实性控制。理想状态是：既保留长文档结构，又能高效定位相关区域。

#### 1.10 Chunking-free 的输入组织
 为了让模型在大上下文中定位，输入组织很关键。

 常见设计：
```text
<doc id="doc_1">
<title>...</title>
<section path="1.2">
<landmark id="L001"/>
段落文本...
<landmark id="L002"/>
段落文本...
</section>
</doc>
```
或使用轻量位置标记：
```text
[L001] 第一段...
[L002] 第二段...
[L003] 第三段...
```
位置标记的作用：

 让模型输出可引用位置。

 便于后处理抽取证据。

 便于评估命中位置是否正确。

 支持动态扩展命中位置周围上下文。

#### 1.11 检索粒度与证据窗口
 Chunking-free 系统仍然需要决定证据窗口大小。常见策略：

 命中 landmark 前后若干句。

 命中段落。

 命中章节。

 命中位置周围固定 token 窗口。

 根据语义边界动态扩展。

 窗口过小会丢失前提，窗口过大则引入噪声。与传统 chunking 不同的是，窗口可以在 query-time 动态确定，而不是离线固定。

#### 1.12 训练与模型能力
 Chunking-free RAG 往往依赖模型具备以下能力：

 长文本编码能力。

 query 与文档内部位置匹配能力。

 对 landmark/position 标记的理解。

 从大上下文中选择证据的能力。

 输出引用位置的能力。

 如果 embedding 模型或 LLM 没有经过相关训练，单纯插入标记可能效果有限。Landmark embedding 这类方法的价值在于让模型学习如何利用这些地标。

#### 1.13 工程实现路径
 在工程中可以采用不同强度的 chunking-free 方案。

 轻量方案：

 减少 chunk 数量，使用更大的结构化片段。

 保留完整标题路径和 doc_id。

 使用 parent document retriever。

 在返回上下文中加入位置标记。

 中等方案：

 使用句子/段落级索引。

 命中后动态扩展上下文窗口。

 使用 reranker 判断 span 相关性。

 对长文档做位置标记和证据高亮。

 高级方案：

 使用 landmark embedding。

 使用 chunking-free in-context retrieval 模型。

 结合长上下文 LLM 和位置级证据抽取。

 对文档级检索、位置级定位、答案生成做联合评估。

#### 1.14 评估指标
 Chunking-free RAG 评估既要看最终答案，也要看位置定位。

 检索/定位指标：

 Evidence recall。

 Landmark hit rate。

 Span overlap。

 Position accuracy。

 Document recall。

 生成指标：

 Answer correctness。

 Faithfulness。

 Citation accuracy。

 Completeness。

 Refusal accuracy。

 系统指标：

 Token cost。

 Latency。

 Context utilization。

 证据窗口长度。

 与 chunk-based baseline 的对比。

 关键是比较：在相同成本或相同上下文预算下，chunking-free 是否比 chunk-based RAG 更能保留证据和提升答案忠实性。

#### 1.15 适用场景
 Chunking-free RAG 更适合：

 长文档理解。

 法律合同和政策文档。

 论文和技术报告。

 章节结构强的文档。

 答案跨 chunk 边界的任务。

 需要保留上下文完整性的问答。

 chunking 参数很难调的复杂文档。

 不一定适合：

 简单 FAQ。

 小规模短文档。

 对延迟极敏感的在线检索。

 embedding/LLM 不支持长上下文或 landmark 的系统。

 需要低成本大规模召回的场景。

#### 1.16 限制与风险
 Chunking-free RAG 的主要限制：

 长上下文成本高。

 对模型位置理解能力要求高。

 landmark 或位置标记需要训练或适配。

 证据窗口仍需设计。

 大规模文档集合中仍需要文档级粗召回。

 工程生态不如传统 chunk RAG 成熟。

 评估更复杂。

 它不是传统 RAG 的完全替代，而是一类针对 chunking 痛点的改进方向。

#### 1.17 与传统 RAG 的取舍
 传统 chunk RAG：

 工程成熟。

 向量数据库生态完善。

 成本可控。

 适合大规模检索。

 但受 chunk 边界影响明显。

 Chunking-free RAG：

 更保留文档结构。

 减少固定 chunk 参数依赖。

 更适合长文档和跨边界证据。

 但成本、模型要求和工程复杂度更高。

 实际系统常采用混合方案：先文档级或章节级召回，再用位置标记、动态窗口、rerank 和长上下文生成。

#### 1.18 面试表达要点
 面试中可以这样总结：
```text
传统 RAG 把文档预先切成 chunk，检索单元固定，容易出现语义切断、上下文丢失和参数敏感。
Chunking-free RAG 的目标是减少固定 chunk 依赖，通过 landmark、位置标记、长上下文和动态 span 选择，在更完整文档结构中定位证据。
它不是把所有文档无脑塞进 prompt，也不是完全不选择证据；而是把证据定位从离线固定切分转为 query-time 动态定位。
它适合长文档和跨 chunk 证据，但成本高、对模型能力要求高，工程上常与 parent retrieval、rerank、long-context RAG 混合使用。
```
#### 1.19 核心总结
 Chunking-free RAG 的核心逻辑：

 chunking 是传统 RAG 的关键瓶颈之一。

 避免固定 chunk 可以减少语义切断和上下文丢失。

 Landmark embedding 让模型能感知文档内部位置。

 In-context retrieval 借助长上下文和位置标记在上下文中动态找证据。

 最终仍要解决证据窗口、引用、忠实性、成本和评估问题。

 生产中更现实的是 hybrid：粗召回 + 动态定位 + rerank + 长上下文生成。

#### 1.20 参考资料
 BGE Landmark Embedding paper: https://arxiv.org/pdf/2402.11573

 Chunking-Free In-Context Retrieval paper: https://arxiv.org/pdf/2402.09760

 BAAI BGE models: https://github.com/FlagOpen/FlagEmbedding

 LangChain Parent Document Retriever: https://python.langchain.com/docs/how_to/parent_document_retriever/

 LlamaIndex Advanced Retrieval: https://docs.llamaindex.ai/en/stable/optimizing/advanced_retrieval/advanced_retrieval/

## 0x02. 二十八：Chunking-free RAG自测题
> 发布日期：2026-06-18  
> 原文链接：[二十八：Chunking-free RAG自测题](https://mp.weixin.qq.com/s/iKbkjHiq7scC6nyphhkGdg)

### A. 背景与基本概念
 传统 chunk-based RAG 的基本流程是什么？

 为什么传统 RAG 通常需要 chunking？

 chunk size 和 overlap 分别影响什么？

 chunking 会给 RAG 带来哪些典型问题？

 什么是语义切断？它为什么会影响答案质量？

 为什么说 chunking 不是一个无害的预处理步骤？

 什么是 Chunking-free RAG？

 Chunking-free RAG 是否意味着完全不选择片段、直接塞全文？为什么？

 Chunking-free RAG 和 long-context RAG 有什么关系？

 Chunking-free RAG 主要想解决传统 RAG 的哪些痛点？

### B. Landmark Embedding 与 In-Context Retrieval
 Landmark Embedding 的基本思想是什么？

 landmark token 或位置标记在长文档中起什么作用？

 为什么 landmark 可以缓解 chunk 边界问题？

 Landmark Embedding 和普通 chunk embedding 的主要区别是什么？

 query 如何与文档中的 landmark 或位置建立关联？

 什么是 Chunking-Free In-Context Retrieval？

 In-Context Retrieval 和传统向量召回有什么区别？

 Chunking-free 系统中“定位”和“提供证据”分别指什么？

 常见定位粒度有哪些？

 常见证据窗口策略有哪些？

 为什么 Chunking-free 仍然需要控制证据窗口大小？

 如果证据窗口过小或过大，会分别有什么问题？

### C. 架构、实现与相关技术对比
 请描述一个 Chunking-free RAG 的高层架构。

 Chunking-free RAG 的离线阶段可能做哪些工作？

 Chunking-free RAG 的在线阶段可能做哪些工作？

 Chunking-free RAG 与 Parent Document Retriever 有什么相似点？

 Chunking-free RAG 与 Parent Document Retriever 有什么区别？

 Chunking-free RAG 与 Small-to-Big Retrieval 有什么关系？

 Chunking-free RAG 与普通长上下文问答有什么区别？

 为什么长上下文模型不能直接替代检索？

 Chunking-free RAG 和 GraphRAG 关注点有什么不同？

 Chunking-free RAG 是否可以和向量数据库一起使用？如何结合？

### D. 输入组织、引用与忠实性
 Chunking-free RAG 中为什么要设计 doc_id、section_id 或 landmark_id？

 请给出一种带位置标记的长文档 prompt 结构。

 为什么位置标记有助于 citation 和后处理？

 Chunking-free RAG 如何支持答案引用？

 如果模型输出了错误 landmark 引用，应该如何评估和处理？

 Chunking-free RAG 中如何避免模型在大上下文中忽略关键信息？

 如何处理多个命中位置之间的重复和冲突？

 如果答案需要跨多个位置综合，系统应如何组织证据？

 Chunking-free RAG 如何设计资料不足时的拒答？

 为什么 Chunking-free RAG 仍然会出现幻觉？

### E. 评估与工程落地
 Chunking-free RAG 评估为什么要同时看最终答案和证据定位？

 什么是 evidence recall？

 什么是 landmark hit rate？

 什么是 span overlap？

 如何比较 Chunking-free RAG 和 chunk-based RAG？

 在相同 token budget 下，比较两种 RAG 方案应关注哪些指标？

 Chunking-free RAG 的系统成本主要来自哪里？

 Chunking-free RAG 的延迟可能比传统 RAG 高在哪里？

 什么场景适合优先尝试 Chunking-free RAG？

 什么场景不适合优先使用 Chunking-free RAG？

 如果模型不理解 landmark 标记，会出现什么问题？

 生产中如何从传统 RAG 平滑过渡到更接近 Chunking-free 的架构？

### F. 排错与综合设计
 如果 Chunking-free RAG 定位到了错误位置，你会如何排查？

 如果定位正确但最终答案错误，你会如何排查？

 如果答案缺少上下文前提，应该如何调整证据窗口？

 如果上下文过长导致成本过高，应该如何优化？

 如果文档包含表格或代码，Chunking-free 架构要注意什么？

 如果文档版本频繁变化，Chunking-free RAG 如何维护位置引用？

 如何在 Chunking-free RAG 中处理权限过滤？

 如何结合 reranker 提升 Chunking-free RAG 的证据选择质量？

 如何结合 contextual compression 控制 Chunking-free RAG 上下文长度？

 如何为法律合同问答设计 Chunking-free 或接近 Chunking-free 的 RAG？

 如何为论文问答设计 Chunking-free 或接近 Chunking-free 的 RAG？

 如何为企业制度文档设计 Chunking-free 或接近 Chunking-free 的 RAG？

 请比较 chunk-based RAG、parent document retrieval、long-context RAG、Chunking-free RAG 的优缺点。

 请解释为什么 Chunking-free RAG 不是传统 RAG 的完全替代。

 请给出一个 Chunking-free RAG 的最小可行实现方案。

 请系统总结 Chunking-free RAG 的核心原理、适用场景、工程难点和面试表达要点。

## 0x03. 二十八：Chunking-free RAG自测题答案
> 发布日期：2026-06-18  
> 原文链接：[二十八：Chunking-free RAG自测题答案](https://mp.weixin.qq.com/s/_weQ_jAt2Jd-_fDT9sw6nw)

### 参考资料
 BGE Landmark Embedding paper: https://arxiv.org/pdf/2402.11573

 Chunking-Free In-Context Retrieval paper: https://arxiv.org/pdf/2402.09760

 BAAI BGE models: https://github.com/FlagOpen/FlagEmbedding

 LangChain Parent Document Retriever: https://python.langchain.com/docs/how_to/parent_document_retriever/

 LlamaIndex Advanced Retrieval: https://docs.llamaindex.ai/en/stable/optimizing/advanced_retrieval/advanced_retrieval/

### A. 背景与基本概念
### 1. 传统 chunk-based RAG 的基本流程是什么？
 传统流程是：加载文档，清洗文档，把文档切成 chunk，对每个 chunk 做 embedding，写入向量索引；在线时对 query 做 embedding，检索 top-k chunk，组装上下文，让 LLM 基于上下文回答。

 简写为：
```text
Document -> Chunk -> Embed -> Index
Query -> Retrieve chunks -> Prompt -> Answer
```
#### 1.2 为什么传统 RAG 通常需要 chunking？
 因为原始文档通常太长，无法直接向量化为一个有效表示，也无法全部放入 prompt。chunking 把文档拆成较小检索单元，降低索引和上下文成本。

 它是工程上可行的折中，但会引入边界和语义完整性问题。

#### 1.3 chunk size 和 overlap 分别影响什么？
 chunk size 决定每个片段包含多少信息。太小缺上下文，太大检索不精确。overlap 用于保留跨边界信息，减少答案被切断的风险。

 overlap 太大又会导致冗余索引和重复召回。

#### 1.4 chunking 会给 RAG 带来哪些典型问题？
 典型问题包括语义切断、上下文丢失、边界敏感、结构破坏、重复召回、chunk 参数敏感、表格代码切坏、标题路径丢失。

 这些问题会导致正确证据召回失败或进入上下文后仍不足以回答。

#### 1.5 什么是语义切断？它为什么会影响答案质量？
 语义切断是指一个完整语义单元被拆到多个 chunk 中，例如定义在前一段、限制条件在后一段。检索只命中其中一段时，模型缺少前提或条件，容易答错。

 它特别影响法律条款、技术说明、论文论证和代码上下文。

#### 1.6 为什么说 chunking 不是一个无害的预处理步骤？
 因为 chunking 改变了文档的知识组织形式。切分边界、大小、overlap 和标题处理都会影响 embedding 表示、召回结果和最终答案。

 同一文档用不同 chunking 策略，RAG 效果可能差异很大。

#### 1.7 什么是 Chunking-free RAG？
 Chunking-free RAG 是减少或避免传统离线固定 chunking 的 RAG 思路。它更倾向于保留完整文档或较大结构，通过 landmark、位置标记、长上下文和动态 span 选择来定位证据。

 它的重点是把证据定位从固定 chunk 单元转向文档内部位置或动态片段。

#### 1.8 Chunking-free RAG 是否意味着完全不选择片段、直接塞全文？为什么？
 不是。真正的 Chunking-free 并不是无脑塞全文，而是避免离线固定 chunk，同时仍然需要 query-time 的证据定位、窗口选择、压缩和引用。

 如果直接塞大量全文，成本高、噪声多，模型也可能忽略关键信息。

#### 1.9 Chunking-free RAG 和 long-context RAG 有什么关系？
 二者有交集。长上下文模型为 Chunking-free 提供了更大的输入容量，但 Chunking-free 关注的是不依赖固定 chunk 的定位和证据选择机制。

 long-context RAG 可以很粗糙地塞文档；Chunking-free 更强调 landmark、span 和动态证据。

#### 1.10 Chunking-free RAG 主要想解决传统 RAG 的哪些痛点？
 主要解决 chunk 边界切断、上下文不完整、chunk size 调参敏感、结构被破坏、跨 chunk 证据难召回和重复 chunk 占据 top-k 等问题。

 它希望更好保留文档原始结构和语义连续性。

### B. Landmark Embedding 与 In-Context Retrieval
#### 1.11 Landmark Embedding 的基本思想是什么？
 Landmark Embedding 在长文档中引入 landmark 或位置标记，让模型学习 query 与文档内部位置之间的关联。检索时不是只匹配独立 chunk，而是定位文档中的相关位置。

 直观上，landmark 是文档内部的“地标”。

#### 1.12 landmark token 或位置标记在长文档中起什么作用？
 它们提供可引用、可定位的锚点。模型可以输出某个 landmark，系统再根据该 landmark 提取周围证据窗口。

 这有助于证据定位、引用、后处理和评估。

#### 1.13 为什么 landmark 可以缓解 chunk 边界问题？
 因为 landmark 不要求预先把文档切成互不相干的固定 chunk，而是在原文连续结构中设置位置锚点。命中位置后可以动态扩展前后文。

 这样答案跨边界时，不一定被固定 chunk 切断。

#### 1.14 Landmark Embedding 和普通 chunk embedding 的主要区别是什么？
 普通 chunk embedding 为每个独立 chunk 生成向量，检索单元是 chunk。Landmark embedding 更关注长文档内部位置表示，检索单元可以是 landmark、span 或位置区域。

 前者依赖离线切分，后者更强调位置级定位。

#### 1.15 query 如何与文档中的 landmark 或位置建立关联？
 模型把 query 和带 landmark 的文档表示映射到可匹配空间，计算 query 与位置/landmark 表示的相关性，选择最相关位置。

 具体实现取决于模型架构和训练方式，关键是模型要学会把问题关联到文档内部区域。

#### 1.16 什么是 Chunking-Free In-Context Retrieval？
 它是在不使用传统固定 chunk 的情况下，在长上下文或文档内部执行检索定位的方法。系统通过位置标记、模型注意力或专门检索机制，从上下文中找出与 query 相关的证据。

 它强调 in-context 中的动态检索，而不是离线 chunk 索引。

#### 1.17 In-Context Retrieval 和传统向量召回有什么区别？
 传统向量召回通常从向量库中找 top-k chunk。In-context retrieval 更像是在已提供的大上下文内部寻找相关位置或 span。

 前者检索单元是预切片段，后者检索单元可以是位置、句子、段落或动态 span。

#### 1.18 Chunking-free 系统中“定位”和“提供证据”分别指什么？
 定位是找出 query 对应文档中的位置，例如 landmark 或段落。提供证据是把定位位置周围的合适文本窗口交给 LLM，用于生成答案。

 定位解决“在哪里”，证据窗口解决“给多少上下文”。

#### 1.19 常见定位粒度有哪些？
 包括 landmark、句子、段落、章节、标题节点、token span、表格单元格、代码函数和文档位置区间。

 粒度越细，定位越精确；粒度越粗，上下文越完整。

#### 1.20 常见证据窗口策略有哪些？
 包括命中位置前后若干句、命中段落、命中章节、固定 token 窗口、按语义边界扩展、多 span 合并和父级上下文返回。

 应根据任务类型和 token 预算选择。

#### 1.21 为什么 Chunking-free 仍然需要控制证据窗口大小？
 因为 LLM 上下文仍有成本和注意力限制。窗口太大引入噪声，太小缺少前提和限制条件。

 Chunking-free 避免固定 chunk，但不避免证据选择。

#### 1.22 如果证据窗口过小或过大，会分别有什么问题？
 过小会导致答案缺上下文、丢失定义、限制条件和跨段信息。过大会带来噪声、成本增加、延迟增加，并可能让模型忽略真正关键证据。

 窗口大小应通过评估调参。

### C. 架构、实现与相关技术对比
#### 1.23 请描述一个 Chunking-free RAG 的高层架构。
 高层架构可以是：文档保留较完整结构，插入 doc_id、section_id、landmark_id；对文档或位置建立表示；query 进来后定位相关 landmark/span；动态扩展证据窗口；rerank 或压缩；最后 LLM 基于带引用的证据回答。

 核心是位置定位和动态证据选择。

#### 1.24 Chunking-free RAG 的离线阶段可能做哪些工作？
 离线阶段可能做文档加载清洗、保留结构、插入 landmark、生成文档级或位置级表示、建立粗召回索引、维护位置到原文的映射。

 它不一定完全没有索引，只是不以固定 chunk 作为唯一知识单元。

#### 1.25 Chunking-free RAG 的在线阶段可能做哪些工作？
 在线阶段可能做 query rewrite、文档级粗召回、位置/landmark 定位、动态窗口扩展、rerank、上下文压缩、prompt 生成、答案引用和忠实性检查。

 在线阶段承担更多动态证据选择工作。

#### 1.26 Chunking-free RAG 与 Parent Document Retriever 有什么相似点？
 二者都试图解决小 chunk 缺少上下文的问题，都希望保留更完整的文档信息给生成模型使用。

 它们都体现了“小粒度定位，大粒度生成”的思想。

#### 1.27 Chunking-free RAG 与 Parent Document Retriever 有什么区别？
 Parent Document Retriever 仍依赖离线 child chunk 做检索，只是返回 parent。Chunking-free 更强调不用固定 chunk，改用 landmark、位置或动态 span 定位。

 Parent Retriever 更成熟易落地，Chunking-free 更偏前沿和模型能力驱动。

#### 1.28 Chunking-free RAG 与 Small-to-Big Retrieval 有什么关系？
 Small-to-Big Retrieval 是先小粒度命中，再扩展到大上下文。Chunking-free 可视为更激进的 small-to-big：小粒度可以是 landmark 或 span，而不是固定 chunk。

 二者都在平衡检索精度和上下文完整性。

#### 1.29 Chunking-free RAG 与普通长上下文问答有什么区别？
 普通长上下文问答可能直接把长文档放入 prompt，让模型自己找答案。Chunking-free RAG 会显式设计位置标记、定位机制、证据窗口和引用。

 它不是只依赖模型在长上下文中“自己注意到”关键信息。

#### 1.30 为什么长上下文模型不能直接替代检索？
 因为长上下文成本高、延迟高、噪声多，模型可能忽略中间信息。大规模文档集合也无法全部放入上下文。

 检索仍用于缩小候选范围、控制成本和提高证据相关性。

#### 1.31 Chunking-free RAG 和 GraphRAG 关注点有什么不同？
 Chunking-free 关注避免固定 chunk 和文档内部证据定位。GraphRAG 关注实体关系图、多跳关系和全局结构检索。

 二者可以结合，但解决的问题不同。

#### 1.32 Chunking-free RAG 是否可以和向量数据库一起使用？如何结合？
 可以。工程上常先用向量数据库做文档级或章节级粗召回，再在候选文档内部做 landmark/span 定位。

 也可以把 landmark 表示存入向量库，检索返回位置而不是固定 chunk。

### D. 输入组织、引用与忠实性
#### 1.33 Chunking-free RAG 中为什么要设计 doc_id、section_id 或 landmark_id？
 这些 ID 提供稳定引用和定位锚点。模型输出 ID 后，系统可以映射回原文位置，提取证据并验证引用。

 没有 ID，答案很难追溯和评估。

#### 1.34 请给出一种带位置标记的长文档 prompt 结构。
 示例：
```text
<doc id="policy_2024">
<section id="s1" title="报销范围">
[L001] ...
[L002] ...
</section>
<section id="s2" title="审批流程">
[L003] ...
</section>
</doc>
```
生成时要求模型引用 [L001] 这类位置标记。

#### 1.35 为什么位置标记有助于 citation 和后处理？
 位置标记让模型能明确指出答案依据。后处理系统可以根据标记找到原文、展示引用、检查引用是否存在，并扩展上下文。

 这比只引用模糊标题更可验证。

#### 1.36 Chunking-free RAG 如何支持答案引用？
 可以要求模型在每个关键结论后输出 doc_id、section_id 或 landmark_id。系统再验证这些 ID 是否在上下文中，并检查对应文本是否支持答案。

 引用机制应和位置映射系统绑定。

#### 1.37 如果模型输出了错误 landmark 引用，应该如何评估和处理？
 评估上应记为 citation error 或定位失败。处理上可以触发重答、重新检索、强制从候选 ID 中选择，或用 verifier 检查引用支持性。

 高风险场景不能接受错误引用直接输出。

#### 1.38 Chunking-free RAG 中如何避免模型在大上下文中忽略关键信息？
 可以使用相关位置高亮、把关键证据放在 prompt 更显著位置、减少无关内容、使用 rerank、上下文压缩、要求引用，以及先让模型选择证据再回答。

 长上下文不等于模型一定会使用所有信息。

#### 1.39 如何处理多个命中位置之间的重复和冲突？
 重复位置可以合并或去重，保留最完整证据。冲突位置要根据版本、时间、权威性和元数据排序；生成时应说明冲突，不应强行合并为确定结论。

 需要记录证据来源，便于用户核查。

#### 1.40 如果答案需要跨多个位置综合，系统应如何组织证据？
 应按子问题或证据链组织多个位置，保留每个位置的 doc_id/landmark_id，并在 prompt 中说明需要综合。生成时每个关键结论引用对应证据。

 多跳问题可以先生成中间结论，再最终汇总。

#### 1.41 Chunking-free RAG 如何设计资料不足时的拒答？
 prompt 应要求如果定位到的证据不足以支持答案，就说明资料不足，并列出缺失信息。系统也可以用 verifier 检查答案 claims 是否有证据支持，无支持则转拒答。

 拒答策略仍然重要，因为更大上下文不代表一定有答案。

#### 1.42 为什么 Chunking-free RAG 仍然会出现幻觉？
 模型可能忽略证据、误读上下文、使用参数知识补全、错误引用 landmark、把无关文本当证据，或在资料不足时猜测。

 因此仍需要 prompt 约束、引用校验和忠实性评估。

### E. 评估与工程落地
#### 1.43 Chunking-free RAG 评估为什么要同时看最终答案和证据定位？
 因为最终答案正确不代表定位正确，可能是模型靠先验答对。定位正确但答案错误则说明生成或上下文组织有问题。

 同时评估能区分定位能力和生成能力。

#### 1.44 什么是 evidence recall？
 evidence recall 衡量系统是否找到了回答问题所需的证据。对 Chunking-free 来说，可以看正确文档、正确位置或正确 span 是否被包含在候选证据中。

 它回答“证据有没有被找到”。

#### 1.45 什么是 landmark hit rate？
 landmark hit rate 衡量模型或检索器是否命中标注为正确证据的 landmark。若问题的标准证据在 L010 附近，系统返回 L010 或允许范围内的 landmark，即为命中。

 它是位置级检索评估指标。

#### 1.46 什么是 span overlap？
 span overlap 衡量预测证据 span 与标准证据 span 的重叠程度，可以用 token、字符或句子级 overlap 计算。

 它比只看文档命中更细，适合评估定位精度。

#### 1.47 如何比较 Chunking-free RAG 和 chunk-based RAG？
 应在相同数据、问题集、模型、token budget 或成本约束下比较，分别看证据召回、答案正确性、faithfulness、citation accuracy、延迟和成本。

 不能只挑几个案例主观比较。

#### 1.48 在相同 token budget 下，比较两种 RAG 方案应关注哪些指标？
 关注 Recall@evidence、answer correctness、faithfulness、citation accuracy、平均上下文长度、延迟、成本和拒答准确率。

 相同 budget 下能更好覆盖证据且更忠实的方案更优。

#### 1.49 Chunking-free RAG 的系统成本主要来自哪里？
 成本来自长上下文输入、位置级定位模型、额外 rerank/压缩、landmark 表示构建、更多 token 处理和评估复杂度。

 如果粗召回候选文档很大，成本会迅速上升。

#### 1.50 Chunking-free RAG 的延迟可能比传统 RAG 高在哪里？
 可能高在长文档编码、in-context 定位、动态窗口扩展、LLM 处理长 prompt、rerank 和 verifier。

 因此生产中常需要粗召回、缓存和分级处理。

#### 1.51 什么场景适合优先尝试 Chunking-free RAG？
 适合长文档、法律合同、政策制度、论文、技术报告、答案跨 chunk 边界、chunk 参数难调、需要完整上下文和精确引用的场景。

 这些场景中传统 chunking 的损伤明显。

#### 1.52 什么场景不适合优先使用 Chunking-free RAG？
 简单 FAQ、短文档、小知识库、低延迟高并发、成本敏感、模型不支持长上下文或 landmark 的场景，不适合优先使用。

 传统 chunk RAG 更成熟且成本可控。

#### 1.53 如果模型不理解 landmark 标记，会出现什么问题？
 模型可能忽略标记、引用错误标记、无法把问题关联到位置，或把标记当普通文本噪声。

 这说明需要模型训练、提示示例、后处理约束或更简单的位置引用机制。

#### 1.54 生产中如何从传统 RAG 平滑过渡到更接近 Chunking-free 的架构？
 可以先保留传统索引，增加标题路径和 doc_id；再使用 parent retrieval 和相邻 chunk 合并；然后加入位置标记和动态窗口；最后评估 landmark/span 定位能力。

 这是渐进式演进，比一次替换系统风险低。

### F. 排错与综合设计
#### 1.55 如果 Chunking-free RAG 定位到了错误位置，你会如何排查？
 检查 query rewrite 是否偏移、文档结构和 landmark 是否正确、位置表示是否有效、粗召回是否包含正确文档、reranker 是否误排、评估标注是否准确。

 还要检查模型是否真正理解 landmark。

#### 1.56 如果定位正确但最终答案错误，你会如何排查？
 检查证据窗口是否足够、上下文是否噪声过多、prompt 是否要求忠实引用、模型是否误读、是否存在冲突文档、输出是否经过 verifier。

 这属于生成或上下文组织问题，不是定位问题。

#### 1.57 如果答案缺少上下文前提，应该如何调整证据窗口？
 可以扩大命中位置前后窗口，按段落或章节边界扩展，加入标题路径和上级说明，或使用 parent context。

 同时用压缩和 rerank 控制噪声。

#### 1.58 如果上下文过长导致成本过高，应该如何优化？
 使用文档级粗召回减少候选，限制证据窗口，加入 rerank 和 contextual compression，缓存高频 query，按问题类型选择是否启用 chunking-free。

 成本优化不能牺牲关键证据。

#### 1.59 如果文档包含表格或代码，Chunking-free 架构要注意什么？
 表格要保留列名、行号、表题和单位；代码要保留文件路径、函数名、缩进和依赖上下文。位置标记不能破坏语法或表格结构。

 证据窗口应按表格块或函数块扩展，而不是简单按字符。

#### 1.60 如果文档版本频繁变化，Chunking-free RAG 如何维护位置引用？
 需要稳定 doc_id、version、section_id，并在文档更新后重建 landmark 映射。引用应包含版本号或更新时间。

 否则旧 landmark 可能指向错误位置。

#### 1.61 如何在 Chunking-free RAG 中处理权限过滤？
 权限过滤必须在粗召回和文档进入上下文之前完成。用户无权访问的文档或位置不能出现在 prompt 中。

 不能依赖模型看到后“不要泄露”。

#### 1.62 如何结合 reranker 提升 Chunking-free RAG 的证据选择质量？
 可以先定位多个候选 landmark/span，再用 reranker 对 query 与候选窗口打分，保留最相关证据。也可以对扩展窗口进行 rerank，减少噪声。

 rerank 是位置定位和生成之间的重要质量控制。

#### 1.63 如何结合 contextual compression 控制 Chunking-free RAG 上下文长度？
 定位后对证据窗口进行句子级抽取、摘要或低相关内容过滤，只保留支持答案的片段。

 注意压缩不能删除限制条件、否定词、数字、条款编号和引用锚点。

#### 1.64 如何为法律合同问答设计 Chunking-free 或接近 Chunking-free 的 RAG？
 保留合同条款层级、条款编号、版本和页码；按条款设置 landmark；query 先定位相关条款，再扩展到相邻子条款和定义条款；回答必须引用条款号，资料不足或冲突时拒答。

 权限和版本控制必须在检索前完成。

#### 1.65 如何为论文问答设计 Chunking-free 或接近 Chunking-free 的 RAG？
 保留标题、摘要、章节、图表、公式和参考文献位置；按段落或章节 landmark 定位；问题可先做文档级粗召回，再定位相关段落；答案引用章节或段落 ID。

 对方法、实验和结论类问题，应跨多个位置组织证据。

#### 1.66 如何为企业制度文档设计 Chunking-free 或接近 Chunking-free 的 RAG？
 保留制度名称、部门、适用范围、更新时间、章节路径和条款编号；定位后扩展到完整条款；冲突时优先最新或权威版本；回答引用制度和条款。

 还要强制权限过滤和资料不足拒答。

#### 1.67 请比较 chunk-based RAG、parent document retrieval、long-context RAG、Chunking-free RAG 的优缺点。
 chunk-based RAG 成熟、低成本、适合大规模，但容易语义切断。Parent document retrieval 用小 chunk 检索、大 parent 生成，兼顾精度和上下文，但仍依赖 chunk。Long-context RAG 能放更多内容，但成本高、噪声多、定位弱。Chunking-free RAG 减少固定 chunk 依赖，保留结构并动态定位证据，但模型要求和工程复杂度高。

 实际系统常混合使用。

#### 1.68 请解释为什么 Chunking-free RAG 不是传统 RAG 的完全替代。
 因为传统 RAG 成熟、便宜、易扩展，适合大量短文档和低延迟场景。Chunking-free 成本更高，依赖长上下文或专门模型，评估和工程更复杂。

 它是针对 chunking 痛点的改进方向，而不是所有场景的默认方案。

#### 1.69 请给出一个 Chunking-free RAG 的最小可行实现方案。
 最小方案：先做文档级或章节级粗召回；在候选文档中插入段落级 landmark；让 LLM 或 reranker 选择最相关 landmark；提取 landmark 前后窗口；组装带 doc_id/landmark_id 的上下文；要求 LLM 基于证据回答并引用位置；最后校验引用是否存在。

 这个方案不需要完全重训模型，也能接近 chunking-free 的动态定位思想。

#### 1.70 请系统总结 Chunking-free RAG 的核心原理、适用场景、工程难点和面试表达要点。
 核心原理是减少离线固定 chunk 依赖，通过 landmark、位置标记、长上下文和动态 span/window 选择，在更完整文档结构中定位证据。适用场景是长文档、法律合同、论文、技术报告、跨 chunk 证据和强引用需求。

 工程难点包括模型是否理解位置标记、粗召回、证据窗口大小、成本延迟、引用校验、权限过滤和评估。面试表达要强调：它不是把全文无脑塞给模型，也不是完全不做证据选择；它是把固定 chunk 的预处理问题转化为 query-time 的位置定位和动态证据选择问题。
