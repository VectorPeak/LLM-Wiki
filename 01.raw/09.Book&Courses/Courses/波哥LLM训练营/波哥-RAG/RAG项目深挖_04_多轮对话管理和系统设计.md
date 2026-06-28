# 【RAG项目深挖-04】多轮对话管理和系统设计

> 😎 继续深挖**多轮对话、引用溯源、系统部署和 A/B 测试**。这些是面试官评估你“系统设计能力”和“工程落地能力”的关键。

---

## 1. 多轮对话

### 1.1 为什么需要多轮对话？

> 😎 先讲业务场景：

保险咨询通常不是一次性的，而是**连续多轮**：

**场景 1：追问细节**

- 用户：“意外险保什么？”
- 系统：“意外险承保意外伤害导致的身故、残疾、医疗费用...”
- 用户：“那摔伤算吗？”（代词“那”指代上一轮的“意外险”）
- 系统需要理解：用户在问“摔伤是否属于意外伤害”

**场景 2：信息收集**

- 用户：“我想买保险”
- 系统：“请问您的年龄和职业？”
- 用户：“30 岁，程序员”
- 系统：“推荐意外险+医疗险...”

**场景 3：澄清歧义**

- 用户：“等待期是多久？”（没说是哪个产品）
- 系统：“请问您咨询的是哪款产品？我们有 A 款（30 天）和 B 款（90 天）”
- 用户：“A 款”

如果没有多轮对话能力：

- 系统无法理解代词（“它”“那个”“这个”）
- 每次都要重复完整问题，用户体验差
- 无法进行深度交互

---

### 1.2 多轮对话的核心挑战

| 挑战 | 描述 | 解决方案 |
|---|---|---|
| 指代消解 | “它”“那个”指代什么？ | 对话历史分析 + LLM 改写 |
| 上下文窗口 | 历史对话太长，超出 LLM 限制 | 压缩策略 + 关键信息提取 |
| 话题切换 | 用户突然问新问题 | 话题检测 + 历史清空 |
| 状态管理 | 需要记住用户信息（年龄、产品） | 会话状态存储 |

---

### 1.3 架构设计

```text
用户输入（第 N 轮）
    ↓
对话历史加载（前 N-1 轮）
    ↓
话题连续性检测
    ├── [话题切换] 清空历史，按单轮处理
    └── [话题延续] 进入多轮处理流程
    ↓
指代消解 + Query 改写
    ↓
检索（使用改写后的 query）
    ↓
生成答案（历史上下文 + 检索结果 + 当前 query）
    ↓
更新对话历史
```

---

### 1.4 指代消解与 Query 改写

**这是多轮对话的核心！**

问题示例：

```text
轮次 1：
用户："意外险保什么？"
系统："意外险承保意外伤害导致的身故、残疾、医疗费用..."

轮次 2：
用户："那摔伤算吗？"
↓
问题：系统不能直接用“那摔伤算吗”去检索（没有主语）
需要改写成："摔伤是否属于意外险的保障范围？"
```

#### 方案 1：基于 LLM 的 Query 改写

```python
QUERY_REWRITE_PROMPT = """
你是一个保险客服对话系统。用户正在进行多轮对话，当前问题可能包含代词或省略成分，需要结合历史对话改写成完整、独立的问题。

对话历史：
{history}

当前问题：{query}

请将当前问题改写成一个完整、独立的问题，可以直接用于检索，不包含任何代词或省略成分。只输出改写后的问题，不要有任何解释。

改写后的问题：
"""

def rewrite_query_with_history(query, history):
    """
    基于历史对话改写当前 query
    """
    # 构建历史对话文本
    history_text = "\n".join([
        f"用户：{turn['user']}\n系统：{turn['assistant']}"
        for turn in history[-3:]  # 只保留最近 3 轮
    ])

    prompt = QUERY_REWRITE_PROMPT.format(
        history=history_text,
        query=query
    )

    rewritten_query = llm.generate(prompt, max_tokens=100)
    return rewritten_query.strip()
```

实际效果：

| 原 query | 历史上下文 | 改写后 query |
|---|---|---|
| “那摔伤算吗” | Q1：意外险保什么 | “摔伤是否属于意外险的保障范围” |
| “等待期多久” | Q1：A 款产品怎么样 | “A 款产品的等待期是多久” |
| “它和 B 款的区别” | Q1：介绍下 A 款 | “A 款和 B 款产品的区别是什么” |

#### 方案 2：基于规则的指代消解（作为 backup）

```python
def resolve_coreference(query, history):
    """
    基于规则的指代消解
    """
    # 规则1：检测代词
    pronouns = ['它', '那', '这', '那个', '这个', '他', '她']

    has_pronoun = any(p in query for p in pronouns)
    if not has_pronoun:
        return query  # 没有代词，不需要改写

    # 规则2：从历史中提取实体（产品名、概念）
    last_entities = extract_entities(history[-1]['user'])
    # 如："意外险保什么" -> 提取出"意外险"

    # 规则3：替换代词
    resolved_query = query
    for pronoun in pronouns:
        if pronoun in query and last_entities:
            resolved_query = resolved_query.replace(
                pronoun,
                last_entities[0]  # 用最近的实体替换
            )

    return resolved_query

def extract_entities(text):
    """
    提取实体（产品名、保险术语）
    """
    # 用正则匹配常见实体
    patterns = [
        r'[A-Z]\d?款',      # A款、B1款
        r'意外险', r'医疗险', r'重疾险',
        r'等待期', r'犹豫期', r'现金价值',
    ]

    entities = []
    for pattern in patterns:
        matches = re.findall(pattern, text)
        entities.extend(matches)

    return entities
```

---

### 1.5 话题连续性检测

**问题：如何判断用户是在追问，还是问了新问题？**

场景对比：

```text
[追问场景]
轮次1："意外险保什么？"
轮次2："那摔伤算吗？" → 追问，需要历史上下文

[话题切换]
轮次1："意外险保什么？"
轮次2："你们公司在哪里？" → 新话题，历史无用
```

解决方案：用 LLM 做二分类。

```python
TOPIC_CONTINUITY_PROMPT = """
判断用户的当前问题是否与上一轮对话相关。

上一轮对话：
用户：{last_user}
系统：{last_assistant}

当前问题：{current_query}

如果当前问题是对上一轮的追问、延续、澄清，回答"是"；
如果是完全无关的新话题，回答"否"。

只回答"是"或"否"，不要有任何解释。

答案：
"""

def is_topic_continuous(query, history):
    """
    判断话题是否连续
    """
    if not history:
        return False  # 没有历史，肯定是新话题

    last_turn = history[-1]

    prompt = TOPIC_CONTINUITY_PROMPT.format(
        last_user=last_turn['user'],
        last_assistant=last_turn['assistant'],
        current_query=query
    )

    response = llm.generate(prompt, max_tokens=5)

    return "是" in response
```

优化：基于相似度的快速判断（减少 LLM 调用）

```python
def is_topic_continuous_fast(query, history):
    """
    基于语义相似度快速判断
    """
    if not history:
        return False

    last_query = history[-1]['user']

    # 计算语义相似度
    query_emb = embedding_model.encode(query)
    last_emb = embedding_model.encode(last_query)
    similarity = cosine_similarity(query_emb, last_emb)

    # 阈值：相似度 > 0.6 认为是追问
    if similarity > 0.6:
        return True

    # 如果相似度在中间区间，用 LLM 二次判断
    if 0.4 < similarity <= 0.6:
        return is_topic_continuous(query, history)  # 调用 LLM

    return False  # 相似度 < 0.4，肯定是新话题
```

---

### 1.6 对话历史管理

**问题 1：历史对话太长怎么办？**

LLM 的上下文窗口有限，如果用户聊了 30 轮，历史会超限。

解决方案：滑动窗口 + 摘要压缩。

```python
class ConversationManager:
    def __init__(self, max_history_turns=5):
        self.max_history_turns = max_history_turns
        self.history = []
        self.summary = ""  # 早期对话的摘要

    def add_turn(self, user_query, assistant_response):
        """
        添加一轮对话
        """
        self.history.append({
            'user': user_query,
            'assistant': assistant_response
        })

        # 如果超过窗口大小，压缩旧对话
        if len(self.history) > self.max_history_turns:
            self._compress_history()

    def _compress_history(self):
        """
        压缩历史对话
        """
        # 取出最早的 2 轮对话
        old_turns = self.history[:2]

        # 用 LLM 生成摘要
        summary_prompt = f"""
请简要总结以下对话的关键信息：

{format_turns(old_turns)}

摘要（50字以内）：
"""
        new_summary = llm.generate(summary_prompt)

        # 合并到总摘要
        if self.summary:
            self.summary += f" 之后，{new_summary}"
        else:
            self.summary = new_summary

        # 删除已摘要的对话
        self.history = self.history[2:]

    def get_context_for_llm(self):
        """
        获取用于输入 LLM 的上下文
        """
        context = ""

        # 添加历史摘要
        if self.summary:
            context += f"早期对话摘要：{self.summary}\n\n"

        # 添加最近的对话
        context += "最近对话:\n"
        for turn in self.history:
            context += f"用户：{turn['user']}\n"
            context += f"系统：{turn['assistant']}\n"

        return context
```

效果：

- 即使聊 30 轮，输入 LLM 的 tokens 始终保持在 15000 以内。
- 关键信息不丢失（通过摘要保留）。

**问题 2：如何存储对话历史？**

方案：Redis + 会话 ID。

```python
import redis
import json

class ConversationStore:
    def __init__(self):
        self.redis_client = redis.Redis(
            host='localhost',
            port=6379,
            decode_responses=True
        )
        self.ttl = 3600 * 24  # 24 小时过期

    def save_conversation(self, session_id, history):
        """
        保存对话历史
        """
        key = f"conversation:{session_id}"
        value = json.dumps(history, ensure_ascii=False)
        self.redis_client.setex(key, self.ttl, value)

    def load_conversation(self, session_id):
        """
        加载对话历史
        """
        key = f"conversation:{session_id}"
        value = self.redis_client.get(key)

        if value:
            return json.loads(value)
        else:
            return []  # 新会话

    def clear_conversation(self, session_id):
        """
        清空对话历史（用户点击“新对话”）
        """
        key = f"conversation:{session_id}"
        self.redis_client.delete(key)
```

---

### 1.7 多轮对话的 Prompt 设计

关键：让 LLM 知道这是多轮对话，并利用历史上下文。

```python
MULTI_TURN_QA_PROMPT = """
你是一个专业的保险客服，正在与用户进行多轮对话。

{conversation_history}

检索到的相关文档：
{retrieved_docs}

当前用户问题：{current_query}

请基于检索到的文档回答用户问题，注意：
1. 如果当前问题与历史对话相关，结合历史回答
2. 如果检索结果与历史矛盾，优先以检索结果为准
3. 如果当前问题在历史中已回答，可以简要概括
4. 保持对话的连贯性和自然性

回答：
"""

def generate_answer_multi_turn(query, history, retrieved_docs):
    """
    多轮对话的答案生成
    """
    # 构建对话历史文本
    history_text = ""
    for turn in history[-3:]:  # 最近 3 轮
        history_text += f"用户：{turn['user']}\n"
        history_text += f"系统：{turn['assistant']}\n"

    # 构建检索文档文本
    docs_text = "\n\n".join([
        f"[文档{i+1}] {doc.content}"
        for i, doc in enumerate(retrieved_docs)
    ])

    prompt = MULTI_TURN_QA_PROMPT.format(
        conversation_history=history_text,
        retrieved_docs=docs_text,
        current_query=query
    )

    answer = llm.generate(prompt, max_tokens=500)
    return answer
```

---

### 1.8 实际效果和指标

评估多轮对话效果：

| 指标 | 定义 | 单轮 | 多轮 |
|---|---|---:|---:|
| 问题理解准确率 | 正确理解用户意图的比例 | 0.89 | **0.94** |
| 答案一致性 | 与历史回答不矛盾的比例 | - | **0.91** |
| 用户满意度 | 点赞率 | 0.82 | **0.88** |

典型改进案例：

```text
[没有多轮对话]
用户："意外险保什么？"
系统："意外险承保意外伤害..."
用户："那摔伤算吗？"
系统："摔伤通常指..." → 答非所问，没理解“那”指代意外险

[有多轮对话]
用户："意外险保什么？"
系统："意外险承保意外伤害..."
用户："那摔伤算吗？"
系统："摔伤属于意外伤害，在意外险的保障范围内。" → 正确理解
```

---

## 2. 引用溯源（Citation & Source Attribution）

### 2.1 为什么需要引用溯源？

业务价值：

1. **增强可信度**：让用户知道答案来自哪里，不是“AI 瞎编的”。
2. **合规要求**：保险行业监管严格，所有建议必须有依据。
3. **方便核查**：用户可以查看原文，自己判断。
4. **降低风险**：如果 LLM 生成的答案有误，用户可以对照原文纠正。

用户视角：

```text
[没有引用]
系统："核辐射不在保障范围。"
用户：😟 你怎么知道的？凭什么？

[有引用]
系统："核辐射不在保障范围。"
来源：《XX意外险条款》第3条 责任免除 > （2）核辐射、核爆炸
[查看原文]
用户：✅ 有理有据，可信
```

---

### 2.2 引用溯源的技术挑战

| 挑战 | 描述 | 解决方案 |
|---|---|---|
| 细粒度定位 | 答案的每句话来自哪个 chunk？ | 句子级别的归因 |
| LLM 幻觉 | LLM 可能编造不存在的内容 | 答案验证 + 逐句对比 |
| 多源融合 | 答案可能综合了多个 chunk | 多源引用展示 |
| 引用格式 | 如何清晰展示来源？ | 结构化元数据 |

---

### 2.3 架构设计

```text
检索 Top-5 文档
    ↓
输入 LLM 生成答案
    ↓
答案后处理：逐句归因
    ├── 将答案分句
    ├── 每句话与检索文档对比
    └── 找到支持该句的文档
    ↓
构建引用信息
    ├── 文档 ID、章节路径
    ├── 页码、段落位置
    └── 原文片段
    ↓
返回答案 + 引用
```

---

### 2.4 方法 1：基于 Prompt 的引用生成

最简单的方法：让 LLM 在生成答案时标注来源。

```python
CITATION_PROMPT = """
你是一个保险客服。请基于以下文档回答用户问题，并在每句话后用[文档X]标注来源。

文档1：{doc1_content}
来源：{doc1_source}

文档2：{doc2_content}
来源：{doc2_source}

...

用户问题：{query}

要求：
1. 每个事实性陈述后用[文档X]标注来源
2. 如果一句话综合了多个文档，用[文档X, Y]
3. 如果某句话是你的推理，不要标注来源
4. 保持回答的流畅性

回答：
"""

def generate_answer_with_citation(query, retrieved_docs):
    """
    生成带引用的答案
    """
    # 构建 prompt
    prompt = CITATION_PROMPT.format(
        query=query,
        **{f"doc{i+1}_content": doc.content
           for i, doc in enumerate(retrieved_docs)},
        **{f"doc{i+1}_source": doc.metadata['source']
           for i, doc in enumerate(retrieved_docs)}
    )

    answer = llm.generate(prompt)
    return answer
```

实际效果：

```text
用户："核辐射在保障范围吗？"
系统："核辐射不在保障范围内[文档2]。根据条款，责任免除包括核辐射、核爆炸等情况[文档2]。"
```

问题：

- LLM 可能忘记标注来源（遗漏率约 15%）。
- LLM 可能标注错误的文档编号。
- 无法处理 LLM 的幻觉（编造内容）。

---

### 2.5 方法 2：后处理式归因

思路：先生成答案，再用算法找每句话的来源。

```python
def attribute_answer_to_sources(answer, retrieved_docs):
    """
    将答案的每句话归因到来源文档

    返回：
    [
        {
            'sentence': '核辐射不在保障范围内。',
            'source_doc_id': 'doc_2',
            'confidence': 0.92
        },
        ...
    ]
    """
    # Step 1: 分句
    sentences = split_sentences(answer)

    attributions = []

    for sent in sentences:
        # Step 2: 计算该句与每个文档的相似度
        best_doc = None
        best_score = 0

        for doc in retrieved_docs:
            # 用 Sentence-BERT 计算语义相似度
            score = compute_similarity(sent, doc.content)

            if score > best_score:
                best_score = score
                best_doc = doc

        # Step 3：如果相似度 > 阈值，认为该句来自该文档
        if best_score > 0.75:
            attributions.append({
                'sentence': sent,
                'source_doc_id': best_doc.id,
                'source_metadata': best_doc.metadata,
                'confidence': best_score
            })
        else:
            # 相似度低，可能是 LLM 的推理或幻觉
            attributions.append({
                'sentence': sent,
                'source_doc_id': None,
                'confidence': 0
            })

    return attributions
```

优化：用 NLI 模型验证蕴含关系。

```python
def verify_entailment(sentence, document):
    """
    用自然语言推理（NLI）模型验证文档是否支持该句

    返回：entailment / contradiction / neutral
    """
    # 用预训练的 NLI 模型（如 RoBERTa-large-MNLI）
    nli_input = {
        'premise': document,      # 前提（文档）
        'hypothesis': sentence    # 假设（答案中的句子）
    }

    result = nli_model.predict(nli_input)
    # result: {'entailment': 0.92, 'contradiction': 0.03, 'neutral': 0.05}

    if result['entailment'] > 0.7:
        return 'supported'       # 文档支持该句
    elif result['contradiction'] > 0.5:
        return 'contradicted'    # 文档与该句矛盾（幻觉！）
    else:
        return 'not_found'       # 文档中没有相关信息
```

集成 NLI 验证后的归因：

```python
def attribute_with_nli(answer, retrieved_docs):
    """
    结合相似度 + NLI 的归因
    """
    sentences = split_sentences(answer)
    attributions = []

    for sent in sentences:
        candidates = []

        # 找到相似度 > 0.6 的所有候选文档
        for doc in retrieved_docs:
            sim_score = compute_similarity(sent, doc.content)
            if sim_score > 0.6:
                # 用 NLI 验证
                entailment = verify_entailment(sent, doc.content)

                if entailment == 'supported':
                    candidates.append({
                        'doc': doc,
                        'score': sim_score
                    })

        # 选择得分最高的文档
        if candidates:
            best = max(candidates, key=lambda x: x['score'])
            attributions.append({
                'sentence': sent,
                'source_doc_id': best['doc'].id,
                'source_metadata': best['doc'].metadata,
                'verified': True
            })
        else:
            # 没有文档支持该句 → 可能是幻觉
            attributions.append({
                'sentence': sent,
                'source_doc_id': None,
                'verified': False,
                'warning': 'unverified_claim'
            })

    return attributions
```

---

### 2.6 幻觉检测与处理

**问题：LLM 可能编造不存在的内容。**

检测方法：

```python
def detect_hallucination(answer, retrieved_docs):
    """
    检测答案中的幻觉
    """
    attributions = attribute_with_nli(answer, retrieved_docs)

    hallucinations = []

    for attr in attributions:
        if not attr['verified']:
            # 该句话没有文档支持
            hallucinations.append({
                'sentence': attr['sentence'],
                'severity': 'high' if contains_factual_claim(attr['sentence'])
                            else 'low'
            })

    return hallucinations

def contains_factual_claim(sentence):
    """
    判断句子是否包含事实性陈述
    """
    # 事实性陈述通常包含：数字、日期、专有名词、断言
    factual_patterns = [
        r'\d+',           # 数字
        r'第\d+条',       # 条款编号
        r'必须|应当|不得|禁止',  # 强断言
    ]

    return any(re.search(p, sentence) for p in factual_patterns)
```

处理策略：

```python
def handle_hallucination(answer, hallucinations):
    """
    处理检测到的幻觉
    """
    if not hallucinations:
        return answer  # 没有幻觉，原样返回

    clean_answer = answer

    # 策略1：删除幻觉句子
    for h in hallucinations:
        if h['severity'] == 'high':
            # 删除该句
            clean_answer = clean_answer.replace(h['sentence'], '')

    # 策略2：添加警告标记
    for h in hallucinations:
        if h['severity'] == 'low':
            # 标记为“未验证”
            clean_answer = clean_answer.replace(
                h['sentence'],
                f"{h['sentence']} ⚠️[未在文档中找到依据]"
            )

    return clean_answer
```

#### 引用信息的结构化展示

前端展示示例：

```json
{
  "answer": "核辐射不在保障范围内。根据条款，责任免除包括核辐射、核爆炸等情况。",
  "citations": [
    {
      "sentence": "核辐射不在保障范围内。",
      "source": {
        "doc_id": "doc_123",
        "doc_title": "XX意外险条款",
        "section_path": "第3条 责任免除 > （2）",
        "page_num": 5,
        "original_text": "责任免除：（2）核辐射、核爆炸、核污染...",
        "url": "/docs/doc_123#page5"
      },
      "confidence": 0.92
    },
    {
      "sentence": "根据条款，责任免除包括核辐射、核爆炸等情况。",
      "source": {
        "doc_id": "doc_123",
        "doc_title": "XX意外险条款",
        "section_path": "第3条 责任免除",
        "page_num": 5,
        "original_text": "本保险不承担以下责任：（1）战争...（2）核辐射、核爆炸...",
        "url": "/docs/doc_123#page5"
      },
      "confidence": 0.89
    }
  ],
  "unverified_sentences": []  // 幻觉句子列表
}
```

前端 UI 设计：

```text
用户问题：核辐射在保障范围吗？

【回答】
核辐射不在保障范围内。[1] 根据条款，责任免除包括核辐射、核爆炸等情况。[1]

【引用来源】
[1] XX意外险条款 - 第3条 责任免除 > （2） - 第5页
    原文："责任免除：（2）核辐射、核爆炸、核污染..."
    [查看完整文档] [跳转到原文位置]
```

---

### 2.7 引用信息的结构化展示

前端展示示例同上，核心是返回：

- `answer`
- `citations`
- `sentence`
- `source`
- `doc_id`
- `doc_title`
- `section_path`
- `page_num`
- `original_text`
- `url`
- `confidence`
- `unverified_sentences`

---

### 2.8 实际效果和指标

| 指标 | 无引用 | 有引用 |
|---|---:|---:|
| 用户信任度 | 6.8/10 | **8.4/10** |
| 点赞率 | 0.76 | **0.88** |
| 用户查看原文率 | - | 32% |
| 投诉率（因答案错误） | 2.30% | **0.80%** |

> 😎 **归因准确率：**
>
> - 基于 Prompt 的方法：82%（LLM 会遗漏或标错）
> - 基于后处理的方法：91%
> - 加入 NLI 验证后：**94%**

幻觉检测效果：

- 检测召回率：87%
- 检测准确率：93%

---

## 3. 系统部署（Backend & Infrastructure）

**详细的参考 FinRAG**

### 3.1 整体架构

```text
前端（React）
    ↓ HTTP/WebSocket
后端API（FastAPI）
    ├── 会话管理服务（Redis）
    ├── 检索服务
    │   ├── 向量检索（Milvus）
    │   └── 关键词检索（Elasticsearch）
    ├── 重排序服务（Cross-Encoder）
    └── LLM服务（OpenAI API / 自部署）
        ↓
文档存储（MinIO / S3）
日志&监控（Prometheus + Grafana）
```

---

### 3.2 服务器配置

你在必须能说清楚：

#### 开发环境

```text
1 台服务器
- CPU: 16核
- 内存: 64GB
- GPU: 1×NVIDIA A10（24GB显存）
- 存储: 2TB SSD

部署内容：
- 向量检索（Milvus）：10GB内存 + CPU
- 关键词检索（Elasticsearch）：8GB内存
- 重排序模型（bge-reranker）：GPU 12GB显存
- Embedding模型（bge-large）：GPU 8GB显存
- Redis: 2GB内存
- FastAPI后端: 4GB内存
```

#### 生产环境（面试重点）

```text
架构：分布式部署

【服务器1：API网关 + 会话管理】
- 8核CPU + 32GB内存
- FastAPI（4个worker进程）
- Redis（主节点）
- Nginx（负载均衡）

【服务器2-3：检索集群】
- 16核CPU + 64GB内存
- Milvus（分布式部署，2个节点）
- Elasticsearch（2个节点，做主从）

【服务器4：模型推理】
- 8核CPU + 64GB内存 + 2×A10 GPU
- Embedding模型（Triton Inference Server）
- Reranker模型（Triton）
- 支持动态批处理（batch size=32）

【服务器5：LLM服务】
- 选项A：调用OpenAI API（无需GPU）
- 选项B：自部署（需要 4×A100 GPU）

【服务器6：存储+监控】
- MinIO（对象存储，存文档）
- Prometheus + Grafana（监控）
- ELK Stack（日志）

【数据库】
- PostgreSQL（存元数据、用户信息）
- Redis Cluster（会话存储，3主3从）
```

#### 成本估算

| 资源 | 配置 | 月成本 | 说明 |
|---|---|---:|---|
| 计算（云服务器） | 6 台 | ¥20,000 | 按需弹性扩容 |
| GPU（A10） | 2 张 | ¥30,000 | 用于模型推理 |
| 存储 | 5TB | ¥1,200 | 文档+向量库 |
| 带宽 | 500GB/月 | ¥400 | 用户请求 |
| LLM API | OpenAI | ¥4,000 | 按 token 计费 |
| **总计** | - | **55600/月** | - |

---

### 3.3 后端 API 设计

面试官可能问：你负责的后端 API 有哪些接口？

```python
from fastapi import FastAPI, WebSocket
from pydantic import BaseModel

app = FastAPI()

# 1. 单轮问答接口
class QueryRequest(BaseModel):
    query: str
    top_k: int = 5

class QueryResponse(BaseModel):
    answer: str
    citations: List[Dict]
    retrieved_docs: List[Dict]
    response_time: float

@app.post("/api/query")
async def query(request: QueryRequest):
    """
    单轮问答
    """
    start_time = time.time()

    # 检索
    docs = retrieve(request.query, top_k=request.top_k)

    # 生成答案
    answer = generate_answer(request.query, docs)

    # 归因
    citations = attribute_answer_to_sources(answer, docs)

    return QueryResponse(
        answer=answer,
        citations=citations,
        retrieved_docs=[d.to_dict() for d in docs],
        response_time=time.time() - start_time
    )

# 2. 多轮对话接口
class ChatRequest(BaseModel):
    session_id: str
    query: str

@app.post("/api/chat")
async def chat(request: ChatRequest):
    """
    多轮对话
    """
    # 加载历史
    history = conversation_store.load_conversation(request.session_id)

    # 判断话题连续性
    if is_topic_continuous(request.query, history):
        # 改写 query
        rewritten_query = rewrite_query_with_history(request.query, history)
    else:
        rewritten_query = request.query

    # 检索 + 生成
    docs = retrieve(rewritten_query, top_k=5)
    answer = generate_answer_multi_turn(request.query, history, docs)

    # 更新历史
    history.append({'user': request.query, 'assistant': answer})
    conversation_store.save_conversation(request.session_id, history)

    return {
        'answer': answer,
        'citations': attribute_answer_to_sources(answer, docs)
    }

# 3. WebSocket流式响应（优化用户体验）
@app.websocket("/ws/chat")
async def websocket_chat(websocket: WebSocket):
    """
    WebSocket接口：流式返回答案
    """
    await websocket.accept()

    while True:
        # 接收用户消息
        data = await websocket.receive_json()
        query = data['query']
        session_id = data['session_id']

        # 检索
        docs = retrieve(query, top_k=5)

        # 流式生成答案
        async for chunk in generate_answer_streaming(query, docs):
            await websocket.send_json({
                'type': 'answer_chunk',
                'content': chunk
            })

        # 发送引用
        await websocket.send_json({
            'type': 'citations',
            'content': attribute_answer_to_sources(answer, docs)
        })
```

---

### 3.4 性能优化

#### 优化 1：缓存机制

```python
import hashlib
from functools import lru_cache

class QueryCache:
    def __init__(self, redis_client):
        self.redis = redis_client
        self.ttl = 3600  # 1小时过期

    def get_cache_key(self, query):
        """
        生成缓存 key
        """
        return f"query_cache:{hashlib.md5(query.encode()).hexdigest()}"

    def get(self, query):
        """
        获取缓存
        """
        key = self.get_cache_key(query)
        cached = self.redis.get(key)

        if cached:
            return json.loads(cached)
        return None

    def set(self, query, result):
        """
        设置缓存
        """
        key = self.get_cache_key(query)
        self.redis.setex(key, self.ttl, json.dumps(result, ensure_ascii=False))

# 在API中使用
@app.post("/api/query")
async def query(request: QueryRequest):
    # 先查缓存
    cached_result = query_cache.get(request.query)
    if cached_result:
        return cached_result

    # 缓存未命中，正常处理
    result = process_query(request.query)

    # 存入缓存
    query_cache.set(request.query, result)

    return result
```

缓存命中率：

- 常见问题（“等待期多久”）：95% 命中
- 整体：42% 命中
- 响应时间：500ms → 50ms（缓存命中时）

#### 优化 2：异步处理

```python
import asyncio

async def retrieve_async(query, top_k):
    """
    异步检索：向量检索和关键词检索并行
    """
    # 并行执行
    vector_task = asyncio.create_task(vector_search_async(query, top_k))
    bm25_task = asyncio.create_task(bm25_search_async(query, top_k))

    # 等待两个任务完成
    vector_results, bm25_results = await asyncio.gather(vector_task, bm25_task)

    # 融合
    return fuse_results(vector_results, bm25_results)
```

性能提升：

- 串行：120ms（向量 70ms + BM25 50ms）
- 并行：**75ms**（max(70ms, 50ms) + 融合 5ms）

#### 优化 3：批处理

```python
class BatchProcessor:
    def __init__(self, max_batch_size=32, max_wait_time=0.05):
        self.max_batch_size = max_batch_size
        self.max_wait_time = max_wait_time
        self.queue = []
        self.lock = asyncio.Lock()

    async def add_to_batch(self, query):
        """
        将 query 加入批处理队列
        """
        async with self.lock:
            future = asyncio.Future()
            self.queue.append((query, future))

            # 如果队列满了，立即处理
            if len(self.queue) >= self.max_batch_size:
                await self._process_batch()

        return await future

    async def _process_batch(self):
        """
        批量处理
        """
        if not self.queue:
            return

        queries, futures = zip(*self.queue)
        self.queue = []

        # 批量 embedding
        embeddings = embedding_model.encode_batch(queries)

        # 批量检索
        for i, (query, future) in enumerate(zip(queries, futures)):
            result = search_with_embedding(embeddings[i])
            future.set_result(result)

# 使用
batch_processor = BatchProcessor()

@app.post("/api/query")
async def query(request: QueryRequest):
    result = await batch_processor.add_to_batch(request.query)
    return result
```

性能提升：

- 单个请求：embedding 30ms
- 批处理（batch=32）：总共 50ms，平均每个 1.6ms

---

### 3.5 监控和告警

```python
from prometheus_client import Counter, Histogram, Gauge

# 定义指标
request_count = Counter('api_requests_total', 'Total API requests', ['endpoint'])
request_latency = Histogram('api_request_duration_seconds', 'API request latency')
retrieval_recall = Gauge('retrieval_recall', 'Retrieval recall rate')

@app.post("/api/query")
async def query(request: QueryRequest):
    # 记录请求数
    request_count.labels(endpoint='/api/query').inc()

    # 记录延迟
    with request_latency.time():
        result = process_query(request.query)

    return result

# Grafana仪表板监控：
# - QPS（每秒查询数）
# - P50/P95/P99延迟
# - 检索召回率
# - 缓存命中率
# - GPU利用率
```

告警规则：

```yaml
# prometheus/alerts.yml
groups:
  - name: rag_system
    rules:
      - alert: HighLatency
        expr: api_request_duration_seconds{quantile="0.95"} > 2
        for: 5m
        annotations:
          summary: "P95延迟超过2秒"

      - alert: LowRecall
        expr: retrieval_recall < 0.85
        for: 10m
        annotations:
          summary: "检索召回率低于85%"
```

---

## 4. A/B 测试（效果验证）

### 4.1 为什么需要 A/B 测试？

> 😎 **场景：你做了一个优化（如调整检索权重），如何证明有效？**
>
> **不能只靠离线指标（MRR 等），必须看线上真实用户反馈。**

---

### 4.2 A/B 测试设计

```python
class ABTestManager:
    def __init__(self):
        self.experiments = {
            'reranker_v2': {
                'control': 'bge-reranker-base',   # 对照组
                'treatment': 'bge-reranker-large', # 实验组
                'traffic_split': 0.5,              # 50%流量
                'start_date': '2024-01-01',
            },
            'dynamic_weight': {
                'control': 'fixed_weight_0.5',
                'treatment': 'llm_intent_based',
                'traffic_split': 0.3,  # 30%流量（保守）
                'start_date': '2024-01-15',
            }
        }

    def assign_variant(self, user_id, experiment_name):
        """
        为用户分配实验组
        """
        # 用 user_id 做哈希，确保同一用户始终在同一组
        hash_val = int(hashlib.md5(user_id.encode()).hexdigest(), 16)

        exp = self.experiments[experiment_name]
        threshold = exp['traffic_split']

        if (hash_val % 100) / 100 < threshold:
            return exp['treatment']
        else:
            return exp['control']

    def log_event(self, user_id, experiment, variant, metrics):
        """
        记录实验数据
        """
        db.insert('ab_test_events', {
            'user_id': user_id,
            'experiment': experiment,
            'variant': variant,
            'timestamp': datetime.now(),
            **metrics
        })

# 在API中使用
@app.post("/api/query")
async def query(request: QueryRequest, user_id: str):
    # 分配实验组
    reranker_variant = ab_test.assign_variant(user_id, 'reranker_v2')

    # 使用对应的模型
    if reranker_variant == 'bge-reranker-large':
        reranker = large_reranker
    else:
        reranker = base_reranker

    # 正常处理
    result = process_query(request.query, reranker=reranker)

    # 记录指标
    ab_test.log_event(user_id, 'reranker_v2', reranker_variant, {
        'response_time': result['response_time'],
        'user_satisfied': None  # 用户反馈后更新
    })

    return result
```

---

### 4.3 评估指标

- **用户满意度**：点赞率、点踩率
- **任务完成率**：用户问题是否得到解答（通过后续行为判断）

辅助指标：

| 类别 | 指标 | 说明 |
|---|---|---|
| 效果 | MRR、NDCG | 离线评估 |
| 体验 | 响应时长、流畅度 | 用户感知 |
| 行为 | 点击原文率、会话轮数 | 参与度 |
| 业务 | 转化率（咨询→购买） | 商业价值 |

---

### 4.4 实验案例

#### 实验 1：精排模型升级

```text
【假设】
bge-reranker-large 比 base 版本效果更好，但延迟更高

【实验设计】
- 对照组：bge-reranker-base（30ms）
- 实验组：bge-reranker-large（80ms）
- 流量：50%
- 时长：2周

【结果】
| 指标 | 对照组 | 实验组 | 提升 | 显著性 |
|------|--------|--------|------|--------|
| 点赞率 | 81% | 87% | +6% | p<0.01 ✅ |
| 响应时长 | 450ms | 520ms | +70ms | p<0.01 ⚠️ |
| 会话轮数 | 2.3 | 2.6 | +13% | p<0.05 ✅ |

【结论】
实验组效果显著更好，虽然延迟增加70ms，但用户满意度提升6%，值得上线。

【后续优化】
通过模型量化，将 large 模型延迟降到 50ms，兼顾效果和体验。
```

#### 实验 2：动态权重策略

```text
【假设】
基于意图识别的动态权重比固定权重效果更好

【实验设计】
- 对照组：固定权重（向量0.5，BM25 0.5）
- 实验组：动态权重（意图识别后调整）
- 流量：30%（保守，因为涉及核心算法）
- 时长：1周

【结果】
| 指标 | 对照组 | 实验组 | 提升 | 显著性 |
|------|--------|--------|------|--------|
| MRR | 0.84 | 0.89 | +6% | p<0.01 ✅ |
| 点赞率 | 83% | 89% | +7% | p<0.01 ✅ |
| 响应时长 | 480ms | 520ms | +40ms | p<0.05 ⚠️ |

【结论】
实验组显著更优，延迟增加可接受。全量上线。

【意外发现】
动态权重对“精确查询”提升明显（+12%），对“语义查询”提升较小（+2%）
→ 后续可以考虑更精细的策略
```

---

### 4.5 实验平台搭建

```yaml
# 实验配置文件（YAML）
experiments:
  reranker_v2:
    name: "精排模型升级"
    hypothesis: "large模型比base效果更好"
    variants:
      - name: control
        config:
          reranker_model: "bge-reranker-base"
      - name: treatment
        config:
          reranker_model: "bge-reranker-large"
    traffic_allocation:
      control: 0.5
      treatment: 0.5
    metrics:
      primary: user_satisfaction
      secondary: [response_time, mrr, click_rate]
    duration_days: 14
    min_sample_size: 10000
```

自动化分析脚本：

```python
def analyze_experiment(experiment_name):
    """
    分析实验结果
    """
    # 从数据库加载数据
    df = load_experiment_data(experiment_name)

    # 对每个指标做统计检验（t-test）
    results = {}
    for metric in ['user_satisfaction', 'response_time', 'mrr']:
        control = df[df['variant'] == 'control'][metric]
        treatment = df[df['variant'] == 'treatment'][metric]

        # t检验
        t_stat, p_value = stats.ttest_ind(treatment, control)

        results[metric] = {
            'control_mean': control.mean(),
            'treatment_mean': treatment.mean(),
            'lift': (treatment.mean() - control.mean()) / control.mean(),
            'p_value': p_value,
            'significant': p_value < 0.05
        }

    return results
```

---

## 5. 总结：系统工程能力的体现

> 😎 面试官想看到的：
>
> ✅ **不只是算法，还有工程**
>
> - “我不仅优化了检索算法，还搭建了完整的后端服务，支持每秒 100+ QPS”
>
> ✅ **不只是离线指标，还有线上验证**
>
> - “我通过 A/B 测试验证了动态权重策略，用户满意度提升 7%，并全量上线”
>
> ✅ **不只是功能实现，还有性能优化**
>
> - “我通过缓存、异步、批处理将响应时间从 500ms 降到 150ms”
>
> ✅ **不只是开发，还有监控运维**
>
> - “我建立了完整的监控体系，通过 Grafana 实时追踪系统健康度”

---

## 6. 准备面试官的高频追问

### Q1：如果用户量暴增 10 倍，系统能撑住吗？

回答：

目前架构支持横向扩展：

1. **API 层**：通过 Nginx 负载均衡，增加 FastAPI 实例（无状态）。
2. **检索层**：Milvus 和 ES 都支持分布式扩展，增加节点。
3. **模型推理**：通过 Triton Server 支持多 GPU 并行。
4. **瓶颈**：LLM API 调用（有 QPS 限制），需要申请更高配额或自部署。

预估：当前架构可支持 10 倍流量，成本增加约 6 倍（计算资源线性增长，但缓存命中率提高）。

### Q2：系统的单点故障在哪里？

回答：

识别了 3 个潜在单点：

1. **Redis**：会话存储单点 → 已部署 Redis Cluster（3 主 3 从）。
2. **LLM API**：依赖外部服务 → 准备了本地部署的备份方案。
3. **向量库**：Milvus master 节点 → 已配置主从热备。

通过健康检查 + 自动故障转移，确保高可用。

### Q3：如何保证数据安全和隐私？

回答：

1. **敏感信息脱敏**：用户问题中的姓名、身份证号自动脱敏。
2. **对话加密**：WebSocket 连接使用 TLS 加密。
3. **数据隔离**：每个企业客户的文档库物理隔离。
4. **审计日志**：所有查询都记录日志，可追溯。
5. **合规**：符合 GDPR、PIPL 等数据保护法规。

---

> 😎 至此，解析、切分、检索、多轮对话、引用溯源、系统部署、A/B 测试全部深挖完毕！
>
> 你现在拥有一套完整、深入、可量化的面试材料。记住核心原则：
>
> 1. 永远从业务价值出发
> 2. 给出具体技术方案
> 3. 提供量化指标和对比
> 4. 展现踩坑经验和优化思路
> 5. 准备好应对追问
