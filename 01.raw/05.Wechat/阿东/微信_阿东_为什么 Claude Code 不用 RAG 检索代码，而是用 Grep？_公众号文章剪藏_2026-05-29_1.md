---
title: "微信_阿东_检索增强_公众号文章剪藏_2026-05-29_1"
source: "/api/v1/wechat_mp/web/fetch_mp_article_detail_html"
author:
  - "阿东"
published: "2026-05-28"
created: 2026-05-29
description: "TikHub 命中的微信公众号文章候选，共 1 条，本文档收录 1 条"
tags:
  - "clippings"
  - "wechat"
  - "阿东"
---

## 0x01. 面试官：为什么 Claude Code 不用 RAG 检索代码，而是用 Grep？
> 发布日期：2026-05-28  
> 原文链接：[面试官：为什么 Claude Code 不用 RAG 检索代码，而是用 Grep？](https://mp.weixin.qq.com/s/w0cBHNuA68KX6mE73Bup5w)

阿东花了一早上时间，翻了 Anthropic 首席工程师 Boris Cherny 的播客原话、亚马逊科学团队的论文、Cursor 官方博客、Claude Code 源码，以及 X 上大量工程师的讨论，把这件事从头到尾捋了一遍。
![image](https://mmbiz.qpic.cn/sz_mmbiz_jpg/cQwYPia4EPNic1rH2gr66zxBK98pRz2CGicMGjkvEE4KrIwnyOeg28jAMkOQJTHBEKbaUWgt0wNLr7Kc7UQg5s9HfgZNRlWhL0z8JqYoH8gK6A/640?from=appmsg)
### 面试标准回答打法(先看这段，再看全文)
 如果你时间紧，只看这一段就够用。面试官问"为什么 Claude Code 不用 RAG 而用 Grep"，按五层递进回答：

 **第一层 · 事实：** Anthropic 首席工程师 Boris Cherny 亲口说的——早期用过 Voyage Embedding + 本地向量数据库，后来 Agentic Search(Glob+Grep+Read)全面碾压，"by a lot"。

 **第二层 · 原因：** 代码搜索关键词 95% 是标识符(函数名、变量名、类名)，本身就是精确的语义锚点。精确匹配 > 语义匹配。加上零索引同步问题、零安全风险(不需要把代码发到外部服务器)。

 **第三层 · 性能：** 底层 ripgrep 用 SIMD + 多线程，4500 文件仓库全文搜索 0.1 秒。本地代码库 MB~几百 MB 级，暴力搜索效率高。

 **第四层 · 架构优势：** LLM 驱动多轮迭代搜索，自身充当 Reranker。不是一次检索拿 Top-K，而是根据每轮结果动态调整策略，顺藤摸瓜追踪调用链。

 **第五层 · 辩证收尾：** OpenAI Codex 独立做了相同选择。但不等于向量没用——PwC 2026 论文发现程序化文件交付下向量在一半配置中反超。核心判断： **你的 Agent 在解决语义发现问题还是证据定位问题？** 编程 Agent 大量工作是证据定位，grep 天然适配。

 面试加分点：提到 Boris Cherny 的名字和 Latent Space 播客(证明你看过一手信源)，提到"Is Grep All You Need"论文(2026.05，PwC)，提到"检索策略 × 工具交付方式 = 最终效果"这个框架。
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/cQwYPia4EPNicBdjNlvMOInE8VQic6fMVR39X2o3L4INWhQFR4cGRMKeLIMhyfbXmVwt5ibo9aSHZibykXicz9Tu0UL4a3icictsty85VCF7Y98icsb0/640?from=appmsg)
 以下是完整深度解析，帮你理解每一层背后的逻辑。

### 先说结论：Claude Code 到底怎么查代码的？
 Claude Code 在分析代码仓库时，核心就靠三个工具： **Glob、Grep、Read**。

 • **Glob** 负责按文件名模式匹配，比如 **/*.java 找出所有 Java 文件，结果按修改时间排序。

 • **Grep** 负责在文件内搜索内容，底层用的是 ripgrep(Rust 写的高性能搜索工具)。

 • **Read** 负责读取文件内容，可以读整个文件，也可以指定行号范围只读一部分。

 没有向量数据库，没有 Embedding 模型，没有索引构建过程，没有 Chunk 分片策略。

 Anthropic 内部把这种方式叫 **Agentic Search(智能体搜索)** ——不预先构建任何索引，让 Agent 在执行任务过程中，根据当前上下文和目标，动态决定搜什么、怎么搜、搜到之后下一步干什么。

 这三个工具还有一个关键属性：它们都是只读工具，可以并行执行。Claude Code 经常同时发起多个 Grep 搜索，一次性扫描多个关键词。

 **最新动态(2026年4月)：** Claude Code v2.1.117 进一步演进，Glob 和 Grep 工具被替换为内嵌的 bfs 和 ugrep，通过 Bash 直接调用，省去独立工具调用的往返开销。底层工具在变，但"零索引 + 词法搜索 + Agent 驱动"的核心思路没变。
![image](https://mmbiz.qpic.cn/mmbiz_png/cQwYPia4EPN9EiaxJeHRCv6EIyXU5hNrAALjUKvNhzQIsOpSEogKncOfls6j7w0VLcpCtib3QqbV9ibeMosnibWGeD0GUZLGhf37tZwG3P8Cuals/640?from=appmsg)
### Boris Cherny 原话怎么说？
 这段信息来源是 Boris Cherny(Claude Code 创建者、Anthropic 首席工程师)2025 年 5 月 7 日在 Latent Space 播客上的原话。

 Boris 的原话是这样的：

 "We tried very early versions of Claude that actually used RAG. We indexed the codebase, and I think we were just using Voyage. So just off-the-shelf RAG, and that worked pretty well. And we tried a few different versions... Eventually, we landed on just agentic search as the way to do stuff."

 他给出了放弃 RAG 的核心原因：

 "One is it outperformed everything. **By a lot. By a lot.** And this was surprising."

 主持人追问这个判断基于什么 benchmark？Boris 坦承：

 "This was just vibes, so internal vibes. There's some internal benchmarks also, but mostly vibes. It just felt better."

 Boris 在 Hacker News 上也进一步解释过：早期 Claude Code 用过 RAG + 本地向量数据库，但很快发现 Agentic Search 整体效果更好，而且更简单，不存在安全、隐私、索引过时和可靠性方面的问题。

 他还提到了一个有趣的灵感来源：这种方式受到了他在 Instagram 时期观察工程师搜索代码方式的启发——当 Meta 内部编辑器的"跳转到定义"功能坏掉时，工程师们就是用 grep 来找代码的。

### RAG 用在代码搜索上到底有什么问题？
 要理解这个选择，得先搞清楚 RAG 在代码场景下的五个痛点：

 **1. 代码不是自然语言，语义相似度不管用** RAG 的核心逻辑是把文本转向量，用余弦相似度找"语义最接近"的内容。但代码不一样—— createD1HttpClient 和 buildD1HttpClient 语义接近，却可能是两个完全不同的函数； handleAuth 和 validateJwtToken 语义差距大，后者却可能是前者内部调用的关键逻辑。

 代码世界里，一个变量名、一个方法签名、一个 import 路径，要么完全匹配，要么就是找错了。没有"大概对"这回事。

 **2. 索引同步成本极高** 代码不断变化。改了方法名，索引里还是旧名字；新增了文件，索引里没有。保持实时同步需要增量更新、文件监听、冲突处理，这套东西的复杂度比 RAG 本身还高。而 grep 搜的永远是磁盘上此时此刻的文件内容，天然不存在同步问题。

 **3. 安全和隐私** RAG 需要 Embedding 模型生成向量——要么本地跑(消耗算力)，要么调远程 API(代码发到外部服务器)。Boris 提到，连 Anthropic 自己的代码库都不愿意发到第三方服务去生成 Embedding。grep 直接在本地磁盘搜索，安全优势是碾压级的。

 **4. 搜索精度问题** 向量搜索返回的是一堆"语义相关"的代码片段，Agent 拿到后还得二次理解和筛选。grep 返回的是精确的代码行和文件路径，Agent 拿到就能直接用。

 **5. 一次检索 vs 多轮探索** 传统 RAG 是"一次检索"模式——query 进去，Top-K 结果出来。但代码理解往往需要多轮追踪：发现一个函数调用，顺藤摸瓜去搜被调用的函数定义，再看这个函数的引用关系。这种多轮迭代的搜索能力，是 RAG 的单次检索模式做不到的。
![image](https://mmbiz.qpic.cn/mmbiz_jpg/cQwYPia4EPN88hyp3bR9IfibvhfcicSdVcqxZD9KuDdMlbnNlB2HnmDVkUibSicD9kHDEo8WAvWWYJhibLY7ZerRQOn3NtcM8ThyrQzb7KUwNy9kw/640?from=appmsg)
### ripgrep 凭什么这么快？
 Claude Code 用的不是 GNU grep，而是 ripgrep——用 Rust 写的现代搜索工具。作者 Andrew Gallant 在 Rust 正则表达式引擎上花了两年半时间，用了 SIMD 指令集加速，搜索速度逼近内存带宽极限。

 在一个 4500 文件的中型代码仓库上实测：

| 搜索模式 | ripgrep | GNU grep | 性能提升 |
| :--- | :--- | :--- | :--- |
| 低频词 TOOL_VERBS | 0.09s | 2.55s | **28x** |
| 正则 async.*gen | 0.10s | 3.30s | **33x** |
| 高频词 import.*from | 0.10s | 2.45s | **25x** |

 约 0.1 秒的搜索延迟，完全在人类感知阈值以下。

 而同样的搜索任务走 RAG 流程：查询文本→Embedding 模型生成向量→向量数据库 KNN 搜索→可能还要 Rerank，整个链路至少 8 个步骤、四五个服务。

 **规模决定论：** grep 方案可行的根本原因是，开发者本地项目通常是 MB 到几百 MB 级别，恰好落在暴力搜索的高效区间。对比向量检索面向的 GB 级海量知识库，量级完全不同。
![image](https://mmbiz.qpic.cn/mmbiz_jpg/cQwYPia4EPNibia2qByhGSLMwn0wEH8icb5Cd98hTdZWES4aV2sjRfxVeWMR72iaDJ31EVsicIGNEnNib70dtd1iaE9LbFWyPySZKIP1VbicE8v54IyU/640?from=appmsg)
### Agentic Search 的完整工作流
 Claude Code 的搜索不是简单调一次 grep 就完事，而是 **LLM 驱动的多轮循环搜索**：
 1. **输入** → 用户问题 + 对话历史 + 可用工具列表，送入 LLM
 2. **决策** → LLM 分析上下文，决定直接回答还是调用工具搜索
 3. **执行** → 调用 Grep/Glob/Read，获取原始结果
 4. **迭代** → 将新结果追加到上下文，再次送入 LLM 进行下一轮分析
 5. **终止** → 判定信息足够，生成最终答案

 举个实战例子——追踪 "Bridge 系统如何记录工具调用"：

 • **第一轮：** 组合关键词广撒网 "GrepTool | tool.*track"，锁定 4 个文件

 • **第二轮：** 切换到 content 模式，深入看目标文件片段，发现"工具-动词"映射表

 • **第三轮：** 用 Read 读取完整文件，理解核心逻辑

 • **第四轮：** 全局搜索引用关系，拼出完整链路

 这个过程中， **LLM 本身就充当了 Reranker 的角色**。传统 RAG 需要单独的 Rerank 模型来弥补向量检索精度不够的问题。而在 Agentic Search 中，LLM 做的不是简单排序，而是"理解 + 决策 + 行动"——它会根据每一轮搜索的结果动态调整后续搜索策略。

 另外，Claude Code 还有一个 **AgentTool(子智能体)** 机制：启动独立的 LLM 实例执行复杂的多步探索，上下文隔离，中间搜索结果保留在子 Agent 内部，仅向主 Agent 汇报精炼总结，有效缓解上下文窗口压力。

### 行业对比：Claude Code vs Cursor vs Codex
 **Claude Code(零索引路线)：** Glob + Grep + Read，零启动延迟、零维护成本，超大库下检索可能有延迟。

 **Cursor(双索引路线)：** 语义索引(tree-sitter 智能分块 + Turbopuffer 向量引擎)+ 精确搜索索引(trigram 倒排索引)。命中率高、可扩展性强，但有启动延迟、需维护索引库。值得注意的是，即便是重度依赖向量索引的 Cursor，其系统提示词也将 grep_search 标注为"主要探索工具"，语义搜索仅作辅助。

 **OpenAI Codex(零索引路线)：** 同样不使用向量索引，核心搜索方式是通过 shell 调用 ripgrep。与 Claude Code 的差异在于：Claude Code 把 grep 封装成结构化工具，更稳健；Codex 让 LLM 直接写 Shell 命令，灵活性高但对模型能力要求更高。

 ==两家竞品独立做出了相同的架构决策——放弃向量检索，采用 LLM 驱动的 Grep。在日常代码开发中，"精确匹配找到已知符号"的需求远比"语义理解找相似概念"更高频、更确定。==
![image](https://mmbiz.qpic.cn/mmbiz_jpg/cQwYPia4EPN9VHWMxKM6rkA0H4iarXicKXTAiasMqwfiaOjVbyRRNL5CrwXg9y5iaeokmrhk7ATTRjd47MIH7FcNs72gaejvsB6DT4kT0Q0fmYdTA/640?from=appmsg)
### X 上工程师们怎么看？
 这个话题在 X 上引发了大量讨论，观点非常多元：

 **"这还是 RAG"派：** 如果把 RAG 理解为"先检索、再生成"的广义范式，那 Claude Code 用 grep 检索 + LLM 生成，本质上就是 RAG，只是检索层从向量换成了词法搜索。

 **"grep 不够用"派：** Milvus 公开批评 Claude Code 的方案，核心质疑包括：多轮搜索导致 Token 膨胀、开发者等待多轮搜索的时间税、grep 零语义理解。

 **"工具在进化"派：** 有开发者开始给 Claude Code 加装语义搜索 MCP 工具(如 mgrep、QMD)，把向量检索作为 grep 的补充而非替代。

 **"主流 Agent 的共识"派：** @vinhnx 总结得到位："主流编程 Agent——Claude Code、Codex CLI、Gemini CLI——都在用 grep/ripgrep + 文件排除 + AST 解析来管理上下文，而不是 RAG、Embedding 或向量索引。"

### 论文实锤：学术界怎么说？
 **亚马逊论文(2025年12月)：** "Keyword search is all you need"，结论是仅有关键词搜索工具的 Agent 系统可以达到完整 RAG 系统 90% 以上的性能。

 **ISSTA '26 GrepRAG 论文：** 在代码补全任务中，朴素的单轮 Grep 检索效果甚至超过了基于 Embedding 的 RAG 基线。核心原因是代码搜索关键词中约 95% 是标识符，它们本身就是精确的"语义锚点"。

 **重点论文："Is Grep All You Need?"(2026年5月，PwC)：** 目前对 grep vs 向量检索在 Agent 系统中最系统的实验研究。核心发现：

 • **内联交付时，grep 在所有框架-模型组合中准确率均高于向量检索。** 最大差距 23.3 个百分点。

 • **框架比检索策略更重要。** 同一模型在不同框架下准确率差距高达 16.4 个百分点。

 • **程序化交付打乱了优劣关系。** 切换到文件式交付后，向量检索在一半配置中反超。

 • **检索策略的优劣会随噪声变化而反转。** 论文最重要的结论： **检索策略 × 工具交付方式 = 最终效果**，单独比较 grep 和向量毫无意义。

 ==真正的问题不是"还需不需要向量数据库"，而是你的 Agent 在解决语义发现问题还是证据定位问题。编程 Agent 的大量工作是证据定位，grep 天然适配。==

### 成本挑战与应对
 grep 方案不是没有代价。多轮搜索确实会消耗更多 Token。Claude Code 通过三个机制来控制：
 1. **Prompt Cache(提示缓存)：** 识别重复的历史对话前缀，仅对增量内容计费，实测降低约 81% 的 Token 成本
 2. **Auto-compaction(自动压缩)：** 历史上下文过长时，自动调用 LLM 生成摘要替换旧历史
 3. **子 Agent 隔离：** 大量中间搜索结果在子 Agent 独立上下文中处理，仅返回精炼结论

### 面试回答模板
 **面试官问：为什么 Claude Code 不用 RAG 检索代码，而是用 Grep？** **第一层(直接原因)：** Boris Cherny 在播客中明确说过，早期版本用过 Voyage Embedding + 本地向量数据库做 RAG，但 Agentic Search 方案全面碾压了 RAG，"by a lot"。

 **第二层(代码场景特殊性)：** 代码搜索关键词 95% 是标识符，函数名、变量名本身就是精确的语义锚点。精确匹配比语义匹配更重要。同时不存在索引同步问题，也不需要把代码发到外部服务器。

 **第三层(性能够用)：** 底层用 ripgrep，SIMD 指令集 + 多线程并行，在几千文件的仓库上全文搜索约 0.1 秒。本地代码仓库 MB~几百 MB 级，恰好在暴力搜索的高效区间。

 **第四层(Agent 多轮优势)：** 传统 RAG 是"一次检索"模式，Agentic Search 是多轮迭代。LLM 自身充当 Reranker，做的不是简单排序，而是理解 + 决策 + 行动。

 **第五层(辩证看待)：** OpenAI Codex 也独立做出了相同选择。但 PwC 论文发现，切换到程序化文件交付后向量在一半配置中反超。真正的问题是你的 Agent 在解决语义发现问题还是证据定位问题。

### 一句话总结
 RAG 没死，死的是"预先构建全局索引 + 单次静态检索"的传统实现方式。在 Agent 时代，检索的载体从 Embedding + 向量库变成了 LLM 驱动的 Grep，但"先检索、再生成"的范式本身依然成立。真正的问题不是选 grep 还是向量，而是： **检索策略 × 工具交付方式 × Agent 框架 = 最终效果。**

### 参考来源
- Boris Cherny, Latent Space Podcast, 2025.05.07

- Sahil Sen et al., "Is Grep All You Need?", arXiv:2605.15184, 2026.05.14

- Amazon Science, "Keyword search is all you need", 2025.12

- ISSTA '26, "GrepRAG"

- Cursor Blog, 混合检索架构与 A/B 测试结果

- Claude Code v2.1.117 Release Notes

 阿东，大模型算法工程师，OPC创业者。
![图片](https://mmbiz.qpic.cn/mmbiz_png/cQwYPia4EPN8GFRLMBOhLOjXuCrD4F8Q1aw6y3D5G8IaMJyiaMiaQSiaEkSqm5ibg6vHScHXmbm6mMyBVgc9M4uaj63dm4WKMEUjLBGJWMEnib5J0/640?wx_fmt=png&from=appmsg&watermark=1&wxfrom=5&wx_lazy=1&tp=webp#imgIndex=3)
