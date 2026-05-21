---
title: RAG 系统的文本分块策略：语义完整性与人工先验的协同设计
source: https://mp.weixin.qq.com/s/yJtkwCbhwB4c27G3ox7zFw
author:
  - 波哥聊大模型
published:
created: 2026-05-07
description: 在 RAG（Retrieval-Augmented Generation）系统的工程实践中，文本分块（chunking）往往是被低估的环节。
tags:
  - clippings
---

---

在 RAG（Retrieval-Augmented Generation）系统的工程实践中，文本分块（chunking）往往是被低估的环节。大多数系统在原型阶段使用固定长度分块（如每 512 token 切一刀），在召回效果不理想时，第一反应是调 embedding 模型或 reranker，而不是重新审视分块策略。

这一优先级排序通常是错误的。分块决策直接决定了检索的信息粒度上限：如果一个关键概念在切分时被拆散到两个 chunk，任何 embedding 模型都无法从单个 chunk 中完整召回它。分块是 RAG 管线中最上游的结构性决策，其影响会向下游逐级放大。

![图片](https://mmbiz.qpic.cn/sz_mmbiz_jpg/kSX2Q9RM8CRhasempTicPvp1aO1FEVSbLWLWO7pnTgQOVpnyONAsQHHNVAG5KIzKqnyiaF8WXN0NlrBiaPA3lm2uH4DMj807uWyEsabob135JM/640?wx_fmt=jpeg&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=0)

问题的复杂性在于，分块策略需要同时满足三个相互制约的目标： **语义完整性** （每个 chunk 应包含完整的语义单元）、 **检索精度** （chunk 不能太长，否则噪声增加，相关段落被稀释）、 **标注可维护性** （对于需要人工干预边界的场景，标注成本必须可控）。这三者构成一个难以同时最优化的约束三角。

## 问题分析 — 粒度-连贯性-标注成本的三角约束

### 为什么固定长度分块是基线而非终点

固定长度分块（Fixed-size chunking）的问题不在于它"错了"，而在于它对语言结构完全无感。自然语言的语义边界天然对齐于句子、段落、章节等结构，而 token 长度与这些边界没有稳定对应关系。一段 400 token 的文字可能是一个完整的论证过程，也可能是三个不同话题的拼接。

固定长度分块的实际召回问题体现在两个方向：

- **过细切分** ：将一个完整概念的定义与其示例切到不同 chunk，导致单独召回任意一个都不够完整
- **过粗切分** ：一个 chunk 涵盖多个话题，与查询的相关部分被不相关内容稀释，embedding 相似度下降

### 三角约束的具体表现

**粒度与连贯性的张力** ：更细的粒度（如句子级 chunk）保证了每个检索单元足够专注，但割裂了跨句子的语义依赖。一个因果关系（"由于 A，所以 B"）如果被拆成两个 chunk，单独召回 B 时会丢失"由于 A"这个前提。

**连贯性与标注成本的张力** ：保持连贯性最可靠的方法是让领域专家手动标注语义边界。但对于大规模知识库（数十万文档），人工标注的成本是不可接受的。自动化方法（如语义相似度阈值切分）又不可避免地在边界识别上引入噪声。

**粒度与标注成本的张力** ：粒度越细，需要标注的潜在边界点越多，单位文档的标注工作量越大。即使只标注"不应在此切分"的禁止边界，细粒度方案的标注密度也远高于粗粒度方案。

理解这个三角之后，分块策略的设计目标就清晰了： **在自动化处理大多数边界的前提下，提供一个低成本的接口让人工先验注入到关键位置** 。

---

## 技术原理 — 三条实现路径的深度解析

### 路径一：语义感知切分（Semantic-aware Chunking）

语义感知切分的核心思想是：用 embedding 模型度量相邻文本段的语义距离，在语义突变点处切分。

**基本算法（以 LangChain SemanticChunker 为代表）** ：

```
from langchain_experimental.text_splitter import SemanticChunker
from langchain_openai.embeddings import OpenAIEmbeddings

splitter = SemanticChunker(
    embeddings=OpenAIEmbeddings(),
    breakpoint_threshold_type="percentile",  # 或 "standard_deviation"
    breakpoint_threshold_amount=95,          # 第95百分位的语义距离视为边界
)

chunks = splitter.split_text(document)
```

算法步骤：

1. 将文档切为句子（或固定小段）
2. 对每对相邻句子计算 embedding 余弦距离
3. 距离超过阈值的位置标记为候选边界
4. 合并边界之间的句子形成最终 chunk

**优势** ：不依赖文档结构标记（如 Markdown 标题），对纯文本文档有良好泛化性。

**局限** ：阈值选择对领域高度敏感。技术文档中相邻句子的语义距离分布与小说、法律文本完全不同，需要领域级别的阈值校准。此外，embedding 模型本身的质量瓶颈会传导到边界识别的准确性上。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

### 路径二：混合规则 + LLM 校验（Hybrid Rule + LLM Validation）

纯 embedding 方法的弱点在于对局部语义突变的过度敏感，以及对结构信号的忽视。混合方法将两类信号结合：

**第一层：结构规则确定优先边界**

文档的显式结构（标题层级、列表、表格、段落间空行）是高可信度的边界信号，优先采用：

```
import re

def extract_structural_boundaries(text: str) -> list[int]:
    """提取基于文档结构的边界位置（字符偏移）"""
    boundaries = []
    # Markdown 标题
    for m in re.finditer(r'\n#{1,6}\s', text):
        boundaries.append(m.start())
    # 双空行（段落分隔）
    for m in re.finditer(r'\n\n+', text):
        boundaries.append(m.start())
    return sorted(set(boundaries))
```

**第二层：语义距离检测补充软边界**

在结构边界之间的长段落中，用 embedding 距离检测语义突变点，作为补充候选边界。

**第三层：LLM 校验合并歧义边界**

对于两层方法产生冲突或低置信度的边界，调用轻量 LLM（如 GPT-4o-mini）判断是否真正存在语义断点：

```
def validate_boundary_with_llm(
    context_before: str,
    context_after: str,
    llm_client,
) -> bool:
    """让 LLM 判断两段文字是否应该被切分为独立 chunk"""
    prompt = f"""判断以下两段文字是否在讨论同一个主题，回答 YES 或 NO：

[前段]
{context_before[-200:]}  # 只取末尾200字符，控制token消耗

[后段]
{context_after[:200]}

是否属于同一主题（YES=不切分，NO=切分）："""

    response = llm_client.complete(prompt, max_tokens=5)
    return response.strip().upper() == "YES"
```

这一架构的关键设计是 **分层降级** ：结构规则处理 ~70% 的边界（高效低成本），语义检测处理 ~25% 的软边界，LLM 校验只处理剩余 ~5% 的歧义案例（高成本但数量少）。

### 路径三：人工先验注入接口（Human-in-the-loop Boundary Injection）

前两条路径都是纯自动化的。当知识库涉及高度专业的领域（法规文本、医学指南、专利文件），自动化边界识别的错误率无法接受时，需要设计一个低成本的人工干预接口。

**核心设计原则：让专家标注"不应切分"而非"应在哪里切分"**

正向标注（标出所有正确边界）成本很高；负向标注（标出错误边界，即"此处不应切分"）成本低，因为自动化方法的精确率通常比召回率更容易优化——宁可多切，让人工排除错误切点。

**实现方式：边界保护标记（Boundary Protection Markers）**

在文档中嵌入轻量的结构化注释，切分器在解析时尊重这些标记：

```
# 文档中的保护标记示例
# <!-- chunk:no-break --> 表示前后两段不应被切分
text = """
第三条 合同的成立需满足以下条件：
<!-- chunk:no-break -->
（一）双方具有完全民事行为能力；
（二）意思表示真实；
（三）不违反法律法规的强制性规定。
"""

def split_with_protection(text: str, base_splitter) -> list[str]:
    """在基础切分器结果上，合并被保护标记跨越的 chunk"""
    NO_BREAK = "<!-- chunk:no-break -->"
    protected_ranges = find_protected_ranges(text, NO_BREAK)
    raw_chunks = base_splitter.split(text.replace(NO_BREAK, ""))
    return merge_protected_chunks(raw_chunks, protected_ranges)
```

**标注成本分析** ：对于一份 10,000 字的法律文件，自动化方法可能产生 ~40 个候选切点。专家只需审查其中被标记为"低置信度"的 ~8 个（通过 LLM 置信度分数筛选），在有问题的地方添加 `no-break` 标记，整个过程约需 15 分钟。相比全量人工标注（通常需要 2-3 小时），成本降低了 90% 以上。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

---

## 解决方案 — 分块策略对检索精度与可维护性的影响

### 检索精度的量化影响

以下对比基于典型 RAG 评估场景（使用 RAGAS 框架，指标为 Context Precision 和 Context Recall）：

| 分块策略 | Context Precision | Context Recall | 适用场景 |
| --- | --- | --- | --- |
| 固定长度（512 token） | 基线 | 基线 | 快速原型 |
| 语义感知切分 | +8% ~ +15% | +5% ~ +10% | 通用文本语料 |
| 混合规则 + LLM 校验 | +15% ~ +25% | +12% ~ +20% | 结构化文档（技术手册、报告） |
| 混合 + 人工注入 | +20% ~ +35% | +15% ~ +25% | 专业领域（法律、医学、金融） |

数字区间较宽，因为收益高度依赖原始文档的结构质量和领域特性。

### 父子 chunk 架构：精度与召回的解耦

一个值得单独提及的工程模式是 **父子 chunk（Parent-Child Chunking）** ，它将检索粒度与返回粒度解耦：

- **子 chunk** （细粒度，如 128 token）：用于 embedding 检索，保证相关性判断的精准性
- **父 chunk** （粗粒度，如 512 token）：检索命中后，返回子 chunk 所属的父 chunk 给 LLM，提供更完整的上下文
```
# 构建父子 chunk 索引
parent_chunks = semantic_splitter.split(doc, target_size=512)
for parent in parent_chunks:
    child_chunks = fixed_splitter.split(parent.text, size=128)
    for child in child_chunks:
        child.metadata["parent_id"] = parent.id
        vector_store.add(child)          # 检索用子 chunk
    doc_store.add(parent)                # 返回用父 chunk

# 检索时
def retrieve_with_parent(query: str, k=5) -> list[str]:
    child_results = vector_store.search(query, k=k)
    parent_ids = {c.metadata["parent_id"] for c in child_results}
    return [doc_store.get(pid) for pid in parent_ids]  # 返回父 chunk
```

这一架构对 Context Precision 的提升尤其显著，因为细粒度子 chunk 有效降低了向量检索中的噪声干扰。

### 可维护性的设计考量

分块策略的可维护性常被忽视，但在知识库持续更新的系统中至关重要：

**增量更新的边界稳定性** ：当源文档局部修改时，固定长度分块会导致修改位置之后的所有 chunk 的 token 偏移量发生变化，大量 chunk 需要重新 embedding。语义感知切分在文档局部修改时，只有语义边界变化的区域需要重新切分，影响范围更小。

**人工标记的版本管理** ： `no-break` 保护标记直接嵌入文档内容，天然随文档版本控制系统（Git）同步，不需要维护独立的标注数据库。

**可观测性** ：在每个 chunk 的 metadata 中记录切分依据（结构规则 / 语义阈值 / LLM 校验 / 人工保护），便于后续分析和调试：

```
chunk.metadata = {
    "doc_id": "...",
    "chunk_boundary_source": "structural",  # or "semantic" / "llm" / "human"
    "boundary_confidence": 0.92,
    "parent_id": "...",
}
```

---

## 总结

文本分块策略的核心设计空间可以归结为一个决策树：文档是否有显式结构？是否需要人工先验注入？对标注成本的容忍度如何？

对于大多数通用场景， **混合规则 + 语义感知** 的两层架构（不含 LLM 校验）在成本和效果之间取得了较好的平衡。LLM 校验层适合在歧义边界密集的领域文档上按需开启，而非全量应用。人工保护标记机制应作为系统的可选组件预留，而非一开始就强制所有文档经过人工审核。

当前仍有几个值得关注的开放方向：针对多模态文档（图文混排 PDF）的语义边界识别、跨语言文档的分块策略迁移，以及如何利用检索日志中的用户行为信号（点击、引用、反馈）对分块边界进行在线调整。这些方向目前缺乏成熟的工程实践，也是 RAG 系统从"能用"迈向"好用"的关键差距所在。

---
