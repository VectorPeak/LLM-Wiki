# 【RAG项目深挖-03】检索召回模块

> 😎 检索模块。这是 RAG 系统的灵魂，也是面试官最关注的部分。（混合检索+动态权重+精排）的思路已经很好了，但需要大幅增加技术深度。

## 1. 为什么需要混合检索？（先讲清楚动机）

**不要直接说“我用了混合检索”，先说为什么：**

在保险 RAG 系统中，用户的 query 分为两类：

**类型1：语义查询（适合向量检索）**

- “孩子摔伤住院能赔吗？”
- “意外险和医疗险有什么区别？”
- 特点：没有精确关键词，需要理解语义

**类型2：精确查询（适合关键词检索）**

- “核辐射是否在保障范围？”
- “等待期是多久？”
- “犹豫期内退保扣费吗？”
- 特点：包含专业术语，需要精确匹配

**单一检索方式的问题：**

- **只用向量检索**：对“核辐射”这种低频专业词，向量表征不够精确，可能召回“辐射”“核武器”等无关内容
- **只用关键词检索**：对“孩子摔伤”这种口语化表达，无法匹配文档中的“未成年人意外伤害”

**实验数据：**

所以我设计了 **混合检索 + 动态权重** 的方案。

## 2. 混合检索的架构设计

### 2.1 整体流程

```text
Query输入
  ↓
意图识别（分类：精确 vs 语义）
  ↓
  ├── 向量检索（Dense Retrieval） → Top-K candidates + scores
  ↓
  └── 关键词检索（Sparse Retrieval） → Top-K candidates + scores

分数归一化 + 动态加权融合
  ↓
去重 + 合并（RRF / 加权求和）
  ↓
粗排结果（Top-10）
  ↓
精排（Cross-Encoder重排序）
  ↓
最终Top-5 → 输入LLM
```

## 3. 向量检索（Dense Retrieval）的技术细节

### 3.1 Embedding模型的选择

**我们很多同学说“转化为向量”，但没说明什么模型，这是面试官必问的：**

**我的选型过程：**

| 模型 | 维度 | 中文效果 | 推理速度 | 最终选择 |
| --- | --- | --- | --- | --- |
| OpenAI text-embedding-ada-002 | 1536 | 好 | 慢（API调用） | ❌ 成本高 |
| bge-large-zh-v1.5 | 1024 | 很好 | 中 | ✅ 当前使用 |
| m3e-base | 768 | 一般 | 快 | ❌ 效果差 |
| bge-m3（多语言） | 1024 | 好 | 慢 | ⚠️ 备选 |

> 😎 **为什么选 bge-large-zh-v1.5？**
>
> 1. **在保险领域的效果最好**：我在 500 个保险 QA 对上测试，Recall@5 达到 0.87（vs m3e 的 0.71）
> 2. **开源可部署**：可以本地部署，降低成本
> 3. **支持中文长文本**：最大输入 512 tokens（保险条款通常 200-400 tokens）

### 3.2 向量库的选择和优化

**我们很多同学写“在 milvus 库中的向量做相似度计算”，但没说为什么选 Milvus、怎么优化：**

#### 为什么选 Milvus？

**相比 ES，Milvus 同时支持本地和云服务，而且便捷切换**

| 特性 | Milvus | Faiss | Elasticsearch | Pinecone |
| --- | --- | --- | --- | --- |
| 分布式 | ✅ | ❌ | ✅ | ✅ |
| 实时更新 | ✅ | ❌ | ✅ | ✅ |
| 混合检索 | ✅ | ❌ | ✅ | ⚠️ |
| 成本 | 开源 | 开源 | 开源 | 付费 |
| 选择 | ✅ | - | - | - |

**Milvus的关键配置：**

```python
# 索引类型：HNSW（层次化小世界图）
index_params = {
    "index_type": "HNSW",
    "metric_type": "IP",  # 内积（余弦相似度的等价形式）
    "params": {
        "M": 16,              # 每层的邻居数（越大越精确，但更慢）
        "efConstruction": 200 # 构建索引时的搜索宽度
    }
}

# 搜索参数
search_params = {
    "metric_type": "IP",
    "params": {"ef": 64}  # 搜索宽度（越大越精确）
}
```

#### 为什么选 HNSW 而不是 IVF_FLAT？

- **HNSW**：图索引，查询速度快（10ms），召回率高（95%+）
- **IVF_FLAT**：倒排索引，需要先量化，召回率略低（92%）

**我做的实验：**

| 索引类型 | 查询延迟 | Recall@10 | 内存占用 |
| --- | --- | --- | --- |
| FLAT（暴力搜索） | 150ms | 1 | 2.5GB |
| IVF_FLAT | 25ms | 0.92 | 1.8GB |
| HNSW | **12ms** | **0.97** | **2.2GB** |

结论：HNSW 是最佳选择

### 3.3 向量检索的查询优化

**问题：用户 query 通常很短（5-15字），但文档 chunk 很长（200-400字），向量相似度计算不准**

**我的优化方案：Query扩展**

```python
def expand_query(query, method='llm'):
    """
    Query扩展：将短query扩展为更丰富的表达

    方法1：用LLM改写
    方法2：用同义词库扩展
    方法3：用历史query学习
    """
    if method == 'llm':
        # 用LLM生成query的多种表达
        prompt = f"""
        用户问题：{query}

        请生成3个语义相同但表达不同的问题，用于检索：
        1. 更口语化的表达
        2. 更专业化的表达
        3. 包含相关术语的表达
        """
        expanded_queries = llm.generate(prompt)

        # 对每个扩展query做向量检索，合并结果
        all_results = []
        for q in expanded_queries:
            results = vector_search(q, top_k=3)
            all_results.extend(results)

        # 去重 + 重新排序
        return rerank(all_results)
```

> 😎 **实际例子：**
>
> - 原 query：“孩子摔伤能赔吗”
> - 扩展后：
>   1. “未成年人意外伤害是否在保障范围”
>   2. “儿童摔倒受伤的医疗费用赔付”
>   3. “少儿意外险对摔伤的理赔条件”
>
> **效果：**
>
> - Recall@5 从 0.87 提升到 **0.91**
> - 但查询延迟增加 2 倍（需要 3 次向量检索）
>
> **权衡：**
>
> - 只对**核心业务场景**（理赔咨询）使用 query 扩展
> - 对简单 FAQ 不扩展

### 3.4 负样本挖掘（Hard Negative Mining）

**面试官可能问：你们有没有微调 Embedding 模型？如果有，怎么做的？**

**我的做法（如果你有微调经验，可以这么说）：**

> 虽然 bge-large-zh 已经很强，但在保险领域仍有提升空间。我构建了保险领域的微调数据：

**数据构建：**

```python
# 三元组：(query, positive_doc, negative_doc)
training_data = [
    {
        'query': '核辐射在保障范围吗',
        'positive': '第3条 责任免除：核辐射、核爆炸...',
        'negative': '第2条 保险责任：本保险承保...'
    },
    ...
]
```

**关键：负样本怎么选？**

**策略1：随机负样本**（简单但效果差）

- 随机选一个不相关的 chunk
- 问题：太简单，模型学不到东西

**策略2：难负样本（Hard Negative）**（我用的方法）

- 用当前模型检索，**选择排名 2-10 但不相关的 chunk**
- 这些 chunk “看起来相关”（包含部分关键词），但语义不对
- 模型需要学习更细粒度的区分

```python
def mine_hard_negatives(query, positive_doc, top_k=10):
    """
    挖掘难负样本
    """
    # 用当前模型检索
    candidates = vector_search(query, top_k=top_k)

    # 排除正样本
    hard_negatives = [c for c in candidates if c != positive_doc]

    # 取 top 2-5（这些是"看起来相关但实际不相关"的）
    return hard_negatives[1:5]
```

**微调设置：**

- 损失函数：**Contrastive Loss**（对比学习）
  - 拉近 query 和 positive 的距离
  - 推远 query 和 negative 的距离
- 训练数据：2000 个三元组（从真实用户 query 中挖掘）
- 训练轮数：3 epochs
- 学习率：2e-5

**效果：**

| 模型 | Recall@5 | MRR |
| --- | --- | --- |
| bge-large-zh（原始） | 0.87 | 0.78 |
| bge-large-zh（微调后） | **0.93** | **0.84** |

**提升最明显的场景：**

- 专业术语查询（“等待期”“犹豫期”“现金价值”）
- 否定性查询（“哪些不赔”“排除责任”）

## 4. 关键词检索（Sparse Retrieval）的技术细节

### 4.1 为什么用 BM25 而不是 TF-IDF？

**“利用BM25计算相关性得分”，虽然现在 BM25 的设置基本一键设置，但要还是要理解为什么：**

| 算法 | 核心思想 | 问题 | 适用场景 |
| --- | --- | --- | --- |
| TF-IDF | 词频 × 逆文档频率 | 对文档长度不敏感，长文档得分虚高 | 短文本 |
| BM25 | 考虑词频饱和 + 文档长度归一化 | - | **长文本**（保险文档） |

**BM25的公式：**

```text
score(q,d) = Σ IDF(qi) × [f(qi,d) × (k1+1)] / [f(qi,d) + k1×(1-b+b×\lvert d\rvert/avgdl)]
```

- `f(qi,d)`：词 qi 在文档 d 中的频率
- `\lvert d\rvert`：文档长度
- `avgdl`：平均文档长度
- `k1`：词频饱和参数（通常1.2-2.0）
- `b`：长度归一化参数（通常0.75）

**为什么 BM25 更好？**

> 保险文档长度差异大（100-2000 tokens）：
>
> - TF-IDF：长文档（如完整条款）因为包含更多词，得分虚高
> - BM25：通过长度归一化，让短文档（如FAQ）也有机会排在前面

**我的实验：**

| query类型 | TF-IDF Recall@5 | BM25 Recall@5 |
| --- | --- | --- |
| 短 query（<5字） | 0.68 | **0.82** |
| 长 query（>15字） | 0.79 | **0.84** |

### 4.2 文本预处理的关键优化

**“分词和normalization”，要具体说怎么做：**

```python
def preprocess_text(text):
    """
    关键词检索的文本预处理
    """
    # Step 1: 分词（用jieba + 自定义词典）
    words = jieba.cut(text)

    # Step 2: 去除停用词
    stopwords = load_stopwords()  # "的", "了", "在"等
    words = [w for w in words if w not in stopwords]

    # Step 3: 同义词替换（关键！）
    synonym_dict = {
        '小孩': '儿童',
        '孩子': '儿童',
        '未成年人': '儿童',
        '摔伤': '意外伤害',
        '摔倒': '意外伤害',
        ...
    }
    words = [synonym_dict.get(w, w) for w in words]

    # Step 4: 提取关键词（可选，用于长文本）
    if len(words) > 20:
        words = extract_keywords(text, top_k=10)  # 用TF-IDF提取

    return words
```

**关键词优化：自定义分词词典**

**问题：**

> jieba 默认词典对保险术语分词不准：
>
> - “意外伤害” → 分成“意外” + “伤害”（错误）
> - “犹豫期” → 分成“犹豫” + “期”（错误）

**解决：**

```python
# 构建保险领域词典
custom_dict = {
    '意外伤害': 100,      # 权重
    '犹豫期': 100,
    '等待期': 100,
    '现金价值': 100,
    '保险责任': 100,
    '责任免除': 100,
    '核辐射': 50,
    '战争': 50,
    ...
}

# 加载自定义词典
for word, freq in custom_dict.items():
    jieba.add_word(word, freq=freq)
```

**效果：**

- 保险术语的分词准确率从73%提升到**96%**
- BM25召回率从0.79提升到**0.84**

### 4.3 Milvus的索引优化

**要说怎么配置Milvus：**

```json
{
  "settings": {
    "analysis": {
      "analyzer": {
        "insurance_analyzer": {
          "type": "custom",
          "tokenizer": "ik_max_word",
          "filter": [
            "lowercase",
            "insurance_synonym",
            "insurance_stop"
          ]
        }
      },
      "filter": {
        "insurance_synonym": {
          "type": "synonym",
          "synonyms": [
            "孩子,儿童,小孩,未成年人",
            "摔伤,摔倒,跌倒 => 意外伤害",
            ...
          ]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "content": {
        "type": "text",
        "analyzer": "insurance_analyzer",
        "fields": {
          "keyword": {
            "type": "keyword"
          }
        }
      },
      "section_title": {
        "type": "text",
        "boost": 2.0
      }
    }
  }
}
```

**关键配置说明：**

1. **自定义分词器**：集成同义词、停用词
2. **多字段索引**：同时支持分词检索和精确匹配
3. **字段权重**：标题权重×2（标题包含关键词，说明高度相关）

## 5. 混合检索的融合策略

### 5.1 分数归一化

你说“做一个归一化”，但要说清楚怎么做：

**问题：**

> - 向量检索的分数范围：0.6-0.95（余弦相似度）
> - BM25 的分数范围：0-50+（无上界）
>
> 不能直接相加！

**解决：Min-Max归一化**

```python
def normalize_scores(scores):
    """
    将分数归一化到[0, 1]
    """
    min_score = min(scores)
    max_score = max(scores)

    if max_score == min_score:
        return [0.5] * len(scores)  # 避免除零

    normalized = [(s - min_score) / (max_score - min_score) for s in scores]
    return normalized
```

**更好的方法：Z-score归一化（我用的）**

```python
def z_score_normalize(scores):
    """
    Z-score归一化：处理异常值更鲁棒
    """
    mean = np.mean(scores)
    std = np.std(scores)

    if std == 0:
        return [0.5] * len(scores)

    z_scores = [(s - mean) / std for s in scores]

    # 映射到[0, 1]（用sigmoid）
    normalized = [1 / (1 + np.exp(-z)) for z in z_scores]
    return normalized
```

### 5.2 动态权重的设计

**这是方案的亮点，要深挖！**

#### 意图识别的实现

**“用prompt做意图识别”，给出具体prompt：**

```python
INTENT_CLASSIFIER_PROMPT = """
你是一个保险问答系统的意图分类器。

用户的问题可以分为两类：
1. 精确查询：包含专业术语、明确的概念，需要精确匹配
   - 例子：核辐射在保障范围吗？等待期是多久？犹豫期能退保吗？

2. 语义查询：口语化表达、描述场景，需要理解语义
   - 例子：孩子摔伤能赔吗？买了两份保险都能赔吗？意外险和医疗险有啥区别？

请判断以下问题属于哪一类，只回答"精确"或"语义"：

问题：{query}

分类：
"""

def classify_intent(query):
    """
    用LLM做意图识别
    """
    prompt = INTENT_CLASSIFIER_PROMPT.format(query=query)
    response = llm.generate(prompt, max_tokens=5)

    if "精确" in response:
        return "exact"
    elif "语义" in response:
        return "semantic"
    else:
        # 兜底：用启发式规则
        return heuristic_classify(query)

def heuristic_classify(query):
    """
    启发式规则（作为LLM的备份）
    """
    exact_keywords = ['等待期', '犹豫期', '现金价值', '核辐射', '战争', '免责']
    semantic_keywords = ['怎么', '为什么', '区别', '能不能', '可以吗']

    for kw in exact_keywords:
        if kw in query:
            return "exact"

    for kw in semantic_keywords:
        if kw in query:
            return "semantic"

    # 默认：如果query很短（<5字），倾向于精确查询
    if len(query) < 5:
        return "exact"
    else:
        return "semantic"
```

**也训练一个小模型（如果你有资源）**

```python
# 用BERT训练一个二分类器
# 训练数据：人工标注500个query（精确 vs 语义）

from transformers import BertForSequenceClassification

intent_classifier = BertForSequenceClassification.from_pretrained(
    'bert-base-chinese',
    num_labels=2
)

# 训练后，推理速度快（5ms），准确率95%
```

#### 权重的动态调整

**我们“xxxx权重设置高一点”，要给出具体数值和理由：**

```python
def get_fusion_weights(intent):
    """
    根据意图返回融合权重

    返回：(vector_weight, bm25_weight)
    """
    if intent == "exact":
        # 精确查询：更依赖关键词匹配
        return (0.3, 0.7)
    elif intent == "semantic":
        # 语义查询：更依赖向量检索
        return (0.7, 0.3)
    else:
        # 不确定：平均权重
        return (0.5, 0.5)
```

**为什么是 0.3/0.7 而不是 0.2/0.8？**

**我做了网格搜索实验：**

| Vector权重 | BM25权重 | 精确查询MRR | 语义查询MRR | 整体MRR |
| --- | --- | --- | --- | --- |
| 0.2 | 0.8 | 0.89 | 0.76 | 0.81 |
| **0.3** | **0.7** | **0.91** | 0.79 | **0.84** |
| 0.4 | 0.6 | 0.88 | 0.82 | 0.84 |
| 0.5 | 0.5 | 0.84 | 0.85 | 0.84 |
| 0.6 | 0.4 | 0.78 | 0.88 | 0.82 |
| **0.7** | **0.3** | 0.73 | **0.91** | **0.81** |
| 0.8 | 0.2 | 0.69 | 0.90 | 0.78 |

**结论：**

- 精确查询：0.3/0.7 最优（MRR 0.91）
- 语义查询：0.7/0.3 最优（MRR 0.91）
- 整体：两种策略都能达到 MRR 0.84

### 5.3 结果融合算法

**“根据权重做一个加权”的具体算法：**

#### 方法1：加权求和（Weighted Sum）

```python
def weighted_fusion(vector_results, bm25_results, weights):
    """
    加权求和融合
    """
    vector_weight, bm25_weight = weights

    # 构建所有候选文档的得分字典
    doc_scores = {}

    # 累加向量检索得分
    for doc_id, score in vector_results:
        doc_scores[doc_id] = vector_weight * score

    # 累加BM25得分
    for doc_id, score in bm25_results:
        if doc_id in doc_scores:
            doc_scores[doc_id] += bm25_weight * score
        else:
            doc_scores[doc_id] = bm25_weight * score

    # 排序
    ranked = sorted(doc_scores.items(), key=lambda x: x[1], reverse=True)
    return ranked[:10]  # Top-10
```

#### 方法2：倒数排名融合（RRF, Reciprocal Rank Fusion）（更鲁棒）

```python
def rrf_fusion(vector_results, bm25_results, k=60):
    """
    RRF融合：对排名融合，而不是分数融合

    公式：RRF(d) = Σ 1/(k + rank_i(d))
    """
    doc_scores = {}

    # 向量检索的排名贡献
    for rank, (doc_id, _) in enumerate(vector_results, start=1):
        doc_scores[doc_id] = 1 / (k + rank)

    # BM25的排名贡献
    for rank, (doc_id, _) in enumerate(bm25_results, start=1):
        if doc_id in doc_scores:
            doc_scores[doc_id] += 1 / (k + rank)
        else:
            doc_scores[doc_id] = 1 / (k + rank)

    # 排序
    ranked = sorted(doc_scores.items(), key=lambda x: x[1], reverse=True)
    return ranked[:10]
```

**RRF的优势：**

1. **不需要归一化**：直接对排名融合，避免了分数 scale 不一致的问题
2. **更鲁棒**：对异常分数（极高或极低）不敏感
3. **效果好**：在多个 benchmark 上优于加权求和

**我的实验对比：**

| 融合方法 | MRR | Recall@5 | 实现复杂度 |
| --- | --- | --- | --- |
| 加权求和 | 0.84 | 0.91 | 简单 |
| RRF | **0.87** | **0.93** | 简单 |
| CombSUM | 0.85 | 0.92 | 中 |
| 学习排序（LTR） | 0.88 | 0.94 | 复杂 |

**最终选择：RRF**

- 效果比加权求和好 3 个百分点
- 实现简单，不需要调参

## 6. 精排（Reranking）的技术细节

### 6.1 为什么需要精排？

**粗排的问题：**

> - 向量检索：只考虑 query 和 chunk 的向量相似度，是**独立打分**
> - BM25：只考虑词匹配，无法理解**语义相关性**
>
> 举例：
>
> - Query：“孩子摔伤住院，意外险能赔吗？”
> - Chunk A：“第2条 保险责任：本保险承保意外伤害导致的医疗费用...”
> - Chunk B：“第3条 责任免除：未成年人在校园内的伤害不予赔付...”
>
> 粗排可能给 Chunk B 更高分（因为包含“未成年人”“伤害”等关键词），但实际上 Chunk A 才是正确答案。
>
> **精排要做的：理解 query 和 chunk 的深层语义关系**

### 6.2 Cross-Encoder的原理

原来“将 query 和候选段落拼接在一起输入 RoBERTa”，要理解为什么这么做：

**对比：Bi-Encoder vs Cross-Encoder**

| 特性 | Bi-Encoder（粗排） | Cross-Encoder（精排） |
| --- | --- | --- |
| 输入 | query 和 doc 分别编码 | query 和 doc 拼接后一起编码 |
| Attention | query 和 doc **不交互** | query 和 doc **充分交互** |
| 速度 | 快（可预计算 doc 向量） | 慢（需要实时计算） |
| 精度 | 中 | 高 |

**Cross-Encoder的架构：**

```text
输入：[CLS] query [SEP] document [SEP]
        ↓
RoBERTa Encoder（12层Transformer）
        ↓
Cross-Attention（query和doc的token充分交互）
        ↓
[CLS] token的输出向量
        ↓
全连接层 → sigmoid
        ↓
相关性分数（0-1）
```

**关键：Cross-Attention**

在 Transformer 的每一层，query 的每个 token 都会 attend 到 document 的每个 token，反之亦然。这样模型可以学习到：

- “孩子摔伤”和“意外伤害”是同义
- “责任免除”和 query 的意图是相反的（负相关）

### 6.3 模型选择和微调

**“调用 Cross-Encoder（RoBERTa model）”，要说清楚：**

**开源模型对比：**

| 模型 | 基座 | 中文效果 | 速度 | 选择 |
| --- | --- | --- | --- | --- |
| cross-encoder/ms-marco-MiniLM-L-6-v2 | MiniLM | 差（英文） | 快 | ❌ |
| bge-reranker-large | XLM-RoBERTa | **很好** | 中 | ✅ |
| bge-reranker-base | XLM-RoBERTa | 好 | 快 | ⚠️备选 |

**为什么选 bge-reranker-large？**

1. 在中文检索任务上效果最好（C-MTEB 排行榜第一）
2. 开源，可本地部署
3. 推理速度可接受（单次 30ms）

**微调数据构建：**

```python
# 训练样本格式：(query, document, label)
training_data = [
    {
        'query': '孩子摔伤能赔吗',
        'document': '第2条 保险责任：本保险承保意外伤害...',
        'label': 1  # 相关
    },
    {
        'query': '孩子摔伤能赔吗',
        'document': '第5条 保险交纳：投保人应按约定...',
        'label': 0  # 不相关
    },
    ...
]
```

**数据来源：**

1. **人工标注**：500 个 query × 10 个候选 doc，人工判断是否相关（5000对）
2. **弱监督**：从用户点击日志中挖掘（点击的 doc 标记为相关，未点击标记为不相关）
3. **对抗样本**：用粗排模型检索到的高排名但不相关的 doc 作为难负样本

**微调设置：**

- 损失函数：**Binary Cross-Entropy**
- 训练轮数：5 epochs
- 学习率：2e-5
- Batch size：32

**效果对比：**

| 模型 | MRR | NDCG@10 |
| --- | --- | --- |
| bge-reranker-large（原始） | 0.87 | 0.82 |
| bge-reranker-large（微调后） | **0.92** | **0.88** |

### 6.4 精排的工程优化

**问题：精排太慢**

> - 粗排返回Top-10，精排需要对每个候选做一次Cross-Encoder推理
> - 10个候选 × 30ms = 300ms（太慢）

**优化方案1：减少候选数量**

```python
# 只对Top-5做精排（而不是Top-10）
coarse_results = coarse_ranking(query, top_k=5)
reranked = rerank(query, coarse_results)
```

**优化方案2：批量推理**

```python
# 将10个候选打包成batch，一次推理
inputs = [
    f"[CLS]{query}[SEP]{doc}[SEP]"
    for doc in candidates
]
scores = reranker.predict(inputs)  # batch推理，50ms
```

**优化方案3：模型量化**

```python
# 用INT8量化，速度提升2x，精度损失<1%
from optimum.onnxruntime import ORTModelForSequenceClassification

reranker = ORTModelForSequenceClassification.from_pretrained(
    "bge-reranker-large",
    export=True,
    provider="CUDAExecutionProvider",
)
```

**最终性能：**

- 精排延迟：300ms → **80ms**
- MRR：保持0.92

## 7. 检索失败的case分析（体现深度）

**面试官可能问：检索效果不好时，如何debug？**

### 7.1 建立监控体系

```python
def log_retrieval_metrics(query, retrieved_docs, ground_truth):
    """
    记录每次检索的指标
    """
    metrics = {
        'query': query,
        'timestamp': datetime.now(),
        'retrieved_doc_ids': [doc.id for doc in retrieved_docs],
        'ground_truth_doc_id': ground_truth.id,
        'hit': ground_truth.id in [doc.id for doc in retrieved_docs],
        'mrr': calculate_mrr(retrieved_docs, ground_truth),
        'retrieval_time': elapsed_time,
    }

    # 存入数据库
    db.insert('retrieval_logs', metrics)
```

**每周分析badcase：**

```sql
SELECT query, retrieved_doc_ids, ground_truth_doc_id
FROM retrieval_logs
WHERE hit = False
ORDER BY timestamp DESC
LIMIT 100;
```

### 7.2 典型失败case及解决方案

**Case 1：同义词问题**

- Query："小孩摔伤能赔吗"
- Ground truth："未成年人意外伤害"
- 问题：关键词检索无法匹配"小孩"和"未成年人"
- 解决：扩充同义词词典

**Case 2：否定性查询**

- Query："核辐射能赔吗"
- 错误召回："本保险承保意外伤害、疾病..."（未提到核辐射）
- 正确答案："责任免除：核辐射..."
- 问题：向量检索倾向于召回"承保"相关的正面描述
- 解决：用LLM做query改写："核辐射是否在责任免除范围"

**Case 3：多跳推理**

- Query："买了两份意外险都能赔吗"
- 需要检索到：
  - "意外险的赔付原则"
  - "多份保险的理赔规则"
- 问题：单次检索无法覆盖两个知识点
- 解决：Query分解 + 多路召回

```python
def multi_hop_retrieval(query):
    """
    多跳检索
    """
    # Step 1: LLM分解query
    sub_queries = llm.decompose(query)
    # ["意外险的赔付原则是什么", "多份保险能同时理赔吗"]

    # Step 2: 对每个sub-query检索
    all_docs = []
    for sq in sub_queries:
        docs = retrieve(sq, top_k=3)
        all_docs.extend(docs)

    # Step 3: 去重 + 重排序
    return rerank(all_docs, query)
```

## 8. 量化指标总结

**面试时必须脱口而出：**

| 模块 | 指标 | 优化前 | 优化后 | 提升 |
| --- | --- | --- | --- | --- |
| 向量检索 | Recall@5 | 0.79 | 0.93 | 0.18 |
| 关键词检索 | Recall@5 | 0.76 | 0.84 | 0.11 |
| 混合检索 | MRR | 0.78 | 0.87 | 0.12 |
| 精排 | MRR | 0.87 | 0.92 | 0.06 |
| 整体 | MRR | 0.72 | **0.92** | 0.28 |
| 延迟 | P99 | 350ms | 150ms | -57% |

## 9. 高阶优化方向（展现技术视野）

**面试官可能问：还有哪些改进空间？（以下的技术实际上没太大用，但是可以作为谈资）**

**1. 多路召回（Multi-Recall）**

> 目前只有2路（向量+BM25），可以增加：
>
> - **BM25F**：增强版BM25，对不同字段加权（标题权重×2）
> - **ColBERT**：late interaction模型，比Bi-Encoder更精准
> - **稀疏向量（SPLADE）**：结合密集和稀疏向量的优势

**2. 学习排序（Learning to Rank）**

> 用LightGBM训练排序模型，特征包括：
>
> - 向量相似度、BM25分数、查询长度
> - 文档类型（FAQ vs 条款）
> - 历史点击率

**3. 个性化检索**

> 根据用户画像调整检索策略：
>
> - 新手用户：优先召回FAQ
> - 专业用户：优先召回详细条款

**4. 实时反馈学习**

> 收集用户反馈（点赞/点踩），用于：
>
> - 更新难负样本
> - 微调排序模型

## 10. 总结：检索模块的核心价值

✅不要说："我用混合检索，向量+BM25"

✅要说："我设计了动态权重的混合检索系统，用LLM做意图识别，对精确查询和语义查询采用不同的融合策略，通过RRF算法融合，再用微调的Cross-Encoder精排，MRR从0.72提升到0.92"

✅不要说："用了bge模型"

✅要说："我对比了3个开源模型，选择bge-large-zh，并在2000个保险QA对上微调，用难负样本挖掘提升模型对专业术语的识别能力，Recall@5从0.87提升到0.93"

✅不要说："用Cross-Encoder重排序"

✅要说："我用bge-reranker-large做精排，通过批量推理+模型量化将延迟从300ms降到80ms，同时MRR提升到0.92，并建立了badcase分析体系，每周迭代优化。"
