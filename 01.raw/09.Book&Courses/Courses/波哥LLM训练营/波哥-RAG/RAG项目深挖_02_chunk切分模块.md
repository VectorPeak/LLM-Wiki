# 【RAG项目深挖-02】chunk切分模块

> 😎 **切分模块（Chunking）** 看似简单，但其实是 RAG 系统的核心瓶颈之一。面试官会重点考察你对**信息完整性 vs 检索精度**这个 trade-off 的理解。

---

## 1. 为什么切分很重要？（先讲清楚业务价值）

不要直接说“怎么做”，先说“为什么”。

在保险 RAG 系统中，切分质量直接影响两个核心指标：

1. **检索召回率**：chunk 太大，噪音多，相似度计算不准；chunk 太小，语义容易被割裂。
2. **答案质量**：chunk 边界不合理，关键信息会被截断，LLM 无法正确理解。

举个实际例子：

- 保险条款：“第3条 责任范围：本保险承保...但以下情况除外：（1）战争...（2）核辐射...”
- 如果切分点在“但以下情况除外”之前，检索时只返回前半段，LLM 会遗漏免责条款，给出错误答案。

我们线上出过一次事故：用户问“核辐射在保障范围内吗”，系统回答“是”。原因是 chunk 只包含“本保险承保...”，导致客户投诉。所以我重新设计了语义感知的切分策略。

---

## 2. 切分策略的演进（体现你的思考深度）

### 2.1 三代方案对比

| 方案 | 做法 | 问题 | 检索 F1 |
|---|---|---|---|
| V1：固定长度切分 | 每 512 tokens 切一刀，overlap 50 | 会截断句子，语义破碎 | - |
| V2：句子级切分 | 按句号切分，累积到 1024 tokens | 长句子会超限；无法保留章节结构 | - |
| V3：语义感知切分（当前） | 基于文档结构 + 语义完整性 | - | - |

面试官会问：为什么 V3 效果好？

因为它考虑了保险文档的 3 个特点：

1. 章节、条款结构强。
2. 免责、责任、费率等关键条款不能被截断。
3. 表格和图片经常携带核心信息，不能简单按普通文本切。

---

## 3. V3 方案的技术细节（重点展开）

### 3.1 切分策略的核心逻辑

```python
def semantic_chunking(parsed_doc):
    """
    基于文档结构的语义切分。

    核心思想：
    1. 优先按“章节”切分，保留完整语义单元
    2. 章节过长时，按“小节”切分
    3. 小节仍过长时，按“段落”切分
    4. 特殊元素（表格/图片）单独成 chunk
    """
    chunks = []

    # Step 1: 识别文档结构
    sections = extract_hierarchy(parsed_doc)

    for section in sections:
        # Step 2: 计算章节 token 数
        section_tokens = count_tokens(section.content)

        if section_tokens <= MAX_CHUNK_SIZE:  # 1024
            # 情况1：章节长度合适，直接作为 chunk
            chunks.append(create_chunk(section))
        else:
            # 情况2：章节过长，递归切分
            chunks.extend(split_large_section(section))

    # Step 3: 添加 overlap
    chunks = add_overlap(chunks, overlap_size=100)

    return chunks
```

---

### 3.2 关键技术点 1：文档结构识别

如果只说“根据解析到的结构化信息”会太模糊，要具体说怎么识别。

问题：保险文档的结构很复杂。

- 有的用数字编号：`1. → 1.1 → 1.1.1`
- 有的用中文编号：`第一条 → （一） → 1.`
- 有的用标题大小：`标题1 → 标题2 → 标题3`
- 还有混合编号：`第3条 保险责任 → 3.1 基本责任 → （1）身故保险金`

我的解决方案是多策略融合。

```python
def extract_hierarchy(parsed_doc):
    """
    提取文档层级结构。

    优先级：
    1. 法律编号（第x条） > 数字编号（1.1） > 字母编号（a）
    2. 字体大小：H1 > H2 > H3
    3. 缩进层级
    """

    # 策略1：正则匹配常见编号模式
    patterns = [
        r'^第[一二三四五六七八九十百]+条',  # 第三条
        r'^\d+\.\d+\.\d+',                  # 1.1.1
        r'^[（(][一二三四五][）)]',          # （一）
        r'^\d+\.',                          # 1.
    ]

    # 策略2：利用解析模块输出的样式信息
    # parsed_doc 包含：font_size、bold、indent_level

    # 策略3：训练一个层级分类器（XGBoost）
    # 特征：编号类型、字体大小、是否加粗、缩进、位置
    hierarchy_level = hierarchy_classifier.predict(features)

    return build_tree(hierarchy_level)
```

为什么不用纯规则？

我们测试了 1000 份保险文档，发现有 23% 的文档编号不规范：

- 有的跳号：`第1条 → 第3条`
- 有的重复：两个“第5条”
- 有的混用编号：`1. → （1） → a.`

所以我训练了一个层级分类器，特征包括：

- 编号类型（one-hot 编码）
- 字体大小相对值（font_size / avg_font_size）
- 是否加粗（binary）
- 缩进层级（0-5）
- 相对位置（在页面的哪个区域）

在 500 份标注数据上训练后，层级识别准确率达到 **94%**。

---

### 3.3 关键技术点 2：超长章节的递归切分

“再进一步切分”太笼统，要说清楚怎么切。

```python
def split_large_section(section, max_size=1024, min_size=256):
    """
    超长章节的切分策略。

    原则：尽量保持语义完整性。
    """
    chunks = []

    # 策略1：先尝试按“小节”切
    subsections = section.get_subsections()
    if subsections:
        for sub in subsections:
            if count_tokens(sub) <= max_size:
                chunks.append(sub)
            else:
                # 递归切分
                chunks.extend(split_large_section(sub))
        return chunks

    # 策略2：没有小节，按“段落”切
    paragraphs = section.get_paragraphs()
    current_chunk = []
    current_tokens = 0

    for para in paragraphs:
        para_tokens = count_tokens(para)

        # 关键判断：是否应该合并到当前 chunk
        if current_tokens + para_tokens <= max_size:
            current_chunk.append(para)
            current_tokens += para_tokens
        else:
            # 保存当前 chunk
            if current_tokens >= min_size:  # 避免太小的 chunk
                chunks.append(merge(current_chunk))
                current_chunk = [para]
                current_tokens = para_tokens

    # 最后一个 chunk
    if current_chunk:
        chunks.append(merge(current_chunk))

    # 策略3：单个段落仍超长，按句子切（最后手段）
    chunks = [
        split_by_sentence(c) if count_tokens(c) > max_size else c
        for c in chunks
    ]

    return chunks
```

#### 关键优化：语义完整性检查

```python
def should_merge(para1, para2):
    """
    判断两个段落是否应该合并。

    场景：
    1. 列表项：para1="包括以下情况：" para2="（1）..." → 应该合并
    2. 转折句：para1="本保险承保..." para2="但以下除外..." → 应该合并
    3. 独立段落：para1="第3条..." para2="第4条..." → 不合并
    """

    # 规则1：如果 para1 以冒号/分号结尾，大概率是列表前导
    if para1.strip().endswith(('：', ':', '；', ';')):
        return True

    # 规则2：如果 para2 是列表项编号
    if re.match(r'^[（(]\d+[）)]|^[①②③④⑤]|^[a-z]\.', para2.strip()):
        return True

    # 规则3：如果 para2 以转折词开头
    if para2.strip().startswith(('但', '然而', '除外', '不包括')):
        return True

    # 规则4：用语义相似度判断（Sentence-BERT）
    similarity = compute_similarity(para1, para2)
    if similarity > 0.75:
        return True

    return False
```

实际效果：

- 优化前：23% 的 chunk 在语义边界处截断（人工抽检 100 个 chunk）。
- 优化后：截断率降到 **4%**。

---

### 3.4 关键技术点 3：特殊元素处理

原来我们讲“表格/图片作为单独整体”，但还不够细。

#### 表格的切分策略

问题：保险文档中的表格差异很大。

- 小表格：3 行 5 列，300 tokens，可以整体作为 chunk。
- 大表格：50 行 10 列，5000 tokens，超过 max_size。

我的方案：

```python
def handle_table(table, max_size=1024):
    """
    表格的智能切分。
    """
    table_tokens = count_tokens(table)

    if table_tokens <= max_size:
        # 情况1：表格不大，整体作为 chunk
        return [create_table_chunk(table)]

    else:
        # 情况2：大表格，按“语义单元”切分

        # 策略A：如果表格有分组（如“基本责任”、“可选责任”）
        if has_row_groups(table):
            return split_by_row_groups(table)

        # 策略B：按固定行数切分，但保留表头
        else:
            chunks = []
            header = table.header
            rows_per_chunk = estimate_rows_per_chunk(table, max_size)

            for i in range(0, len(table.rows), rows_per_chunk):
                chunk_rows = table.rows[i:i + rows_per_chunk]
                # 关键：每个 chunk 都包含表头
                chunk = Table(header=header, rows=chunk_rows)
                chunks.append(create_table_chunk(chunk))

            return chunks
```

为什么每个 chunk 都要包含表头？

举例：一个费率表有 50 行，如果只给 LLM 第 30-40 行，但不包含表头，它不知道每列是什么含义，无法回答“30 岁男性的费率是多少”。

#### 图片的处理

```python
def handle_image(image):
    """
    图片的处理策略。
    """

    # 策略1：用多模态模型生成描述
    if is_chart_or_diagram(image):
        # 对于流程图、示意图
        description = gpt4v.generate_description(image)
        return create_chunk(
            content=description,
            metadata={'type': 'image', 'image_path': image.path}
        )

    # 策略2：对于数据图表，提取结构化数据
    elif is_data_chart(image):
        # 用 DePlot 模型提取数据
        data = deplot.extract(image)
        return create_chunk(
            content=f"图表数据：{data}",
            metadata={'type': 'chart', 'image_path': image.path}
        )

    # 策略3：OCR 提取文字
    else:
        text = ocr.extract(image)
        return create_chunk(content=text, metadata={'type': 'image'})
```

---

### 3.5 关键技术点 4：Overlap 策略

“overlap 是 100”，但要说为什么这么设置。

#### Overlap 的作用

防止关键信息被切分到两个 chunk 的边界，导致检索遗漏。

举例：

```text
Chunk 1: "...本保险承保意外伤害导致的身故或残疾"
          [边界]
Chunk 2: "，但以下情况除外：（1）战争..."
```

如果用户 query 是“战争是否在保障范围”，相似度计算时：

- Query 向量和 Chunk 1：相似度低（Chunk 1 没提到“战争”）。
- Query 向量和 Chunk 2：相似度低（Chunk 2 缺少前文“承保什么”）。

加入 overlap 后：

```text
Chunk 1: "...本保险承保意外伤害导致的身故或残疾"
Chunk 2: "...意外伤害导致的身故或残疾，但以下情况除外：（1）战争..."
          ^^^^^^^^^ overlap 部分 ^^^^^^^^^
```

现在 Chunk 2 包含完整语义，检索准确率提升。

#### Overlap 大小的选择

我做了实验对比：

| Overlap 大小 | 检索召回率 | 存储开销 | 检索速度 |
|---:|---:|---:|---|
| 0 | 0.79 | 1x | 快 |
| 50 tokens | 0.84 | 1.05x | 快 |
| **100 tokens** | **0.89** | **1.1x** | 中 |
| 200 tokens | 0.90 | 1.2x | 慢 |
| 300 tokens | 0.91 | 1.3x | 慢 |

结论：**100 tokens 是性价比最优点**。

- 召回率提升显著（+10%）。
- 存储只增加约 10%。
- 检索速度影响可接受。

#### 为什么不用更大的 overlap？

Overlap 越大，重复内容越多，会导致：

1. 检索时返回多个相似 chunk，内容重复。
2. LLM 输入变长，增加成本。

#### 智能 Overlap（我的优化）

固定 overlap 有个问题：可能在句子中间截断。

我的改进：基于句子边界的 overlap。

```python
def add_smart_overlap(chunks, overlap_tokens=100):
    """
    智能 overlap：确保 overlap 边界是完整句子。
    """
    result = []

    for i, chunk in enumerate(chunks):
        if i == 0:
            result.append(chunk)
            continue

        # 获取前一个 chunk 的最后 N 个 tokens
        prev_chunk = chunks[i - 1]
        overlap_text = get_last_n_tokens(prev_chunk.content, overlap_tokens)

        # 关键：找到最近的句子边界
        overlap_text = truncate_to_sentence_boundary(overlap_text)

        # 合并
        new_content = overlap_text + chunk.content
        result.append(create_chunk(new_content, chunk.metadata))

    return result


def truncate_to_sentence_boundary(text):
    """
    截断到最近的句子边界。
    """
    sentence_ends = ['.', '。', '?', '？', '!', '！']
    last_end = -1

    for end in sentence_ends:
        pos = text.rfind(end)
        if pos > last_end:
            last_end = pos

    if last_end > 0:
        return text[last_end + 1:]  # 返回最后一个完整句子之后的部分
    else:
        return text  # 找不到句子边界，返回原文
```

效果：

- 避免了 87% 的“句子被截断”问题。
- 检索召回率从 0.89 提升到 **0.91**。

---

## 4. Chunk 的元数据设计（容易被忽略但很重要）

面试官可能会问：chunk 除了文本，还有什么？

```python
class Chunk:
    def __init__(self):
        self.content = ""          # 文本内容
        self.metadata = {
            # 基础信息
            'doc_id': '',          # 文档 ID
            'chunk_id': '',        # chunk 唯一 ID
            'page_num': 0,         # 页码

            # 结构信息（关键）
            'section_title': '',   # 所属章节标题
            'section_path': '',    # 章节路径，如“第3条 > 3.1 > （1）”
            'hierarchy_level': 0,  # 层级深度

            # 类型信息
            'content_type': '',    # text/table/image
            'is_key_clause': False,# 是否关键条款（责任、免责、费率）

            # 位置信息
            'bbox': [],            # 在原 PDF 中的坐标
            'prev_chunk_id': '',   # 前一个 chunk，用于上下文扩展
            'next_chunk_id': '',   # 后一个 chunk
        }
```

### 为什么需要这些元数据？

1. **section_path：用于答案溯源**

   - 用户问：“核辐射在保障范围内吗？”
   - 系统回答：“根据第3条 保险责任 > 3.2 责任免除 > （2），核辐射不在保障范围。”

2. **is_key_clause：用于检索加权**

   - 关键条款（责任、免责、费率）的权重 × 1.5。
   - 识别方法：关键词匹配 + 章节标题判断。

3. **prev/next_chunk_id：用于上下文扩展**

   - 如果检索到的 chunk 语义不完整，自动拉取前后 chunk。
   - 例如检索到“但以下除外：”，自动拉取前一个 chunk 的“承保范围”。

---

## 5. 切分质量评估（必须有量化指标）

面试官会问：怎么评估切分效果？

### 5.1 评估指标

| 指标 | 定义 | 测量方法 | 目标值 |
|---|---|---|---|
| 语义完整性 | chunk 是否包含完整语义 | 人工标注 + LLM 判断 | >95% |
| 信息密度 | 有效信息占比 | 关键词覆盖率 | >70% |
| 检索召回率 | 相关 chunk 被召回的比例 | 测试集 QA 评估 | >90% |
| 边界准确性 | 切分点是否在合理位置 | 句子截断率 | <5% |

### 5.2 评估方法：QA 测试

我构建了一个评估数据集：

- 200 份保险文档。
- 每份文档人工编写 10 个问题，覆盖不同难度。
- 共 2000 个 QA 对。

评估流程：

```python
def evaluate_chunking(questions, ground_truth_chunks):
    """
    评估切分效果。
    """
    recall_list = []

    for q, gt_chunk in zip(questions, ground_truth_chunks):
        # 用当前切分方案检索
        retrieved_chunks = retrieve(q, top_k=5)

        # 判断 ground truth chunk 是否被召回
        if gt_chunk in retrieved_chunks:
            recall_list.append(1)
        else:
            recall_list.append(0)

    recall = np.mean(recall_list)
    return recall
```

结果对比：

- V1 固定长度切分：召回率 67%。
- V2 句子级切分：召回率 74%。
- V3 语义感知切分：召回率 **91%**。

---

## 6. 实际踩过的坑（体现经验）

### 坑 1：chunk 太小导致语义不完整

问题：

初版系统设置 `chunk_size=512`，导致一些复杂条款被切碎。

例如：

> 本保险承保意外伤害（定义见第 X 条），包括但不限于...，但以下情况除外：...

被切成 3 个 chunk，LLM 看不到完整逻辑，回答错误。

解决：

- 增大 `chunk_size` 到 1024。
- 对关键条款（责任、免责）设置更大的 `max_size`（1536）。

### 坑 2：表格被切分后表头丢失

问题：

大表格按行切分后，每个 chunk 只包含部分行。LLM 看不到表头，不知道每列是什么。

解决：

- 每个 chunk 都复制表头。
- 在 metadata 中标注“这是表格的第 X 部分，共 Y 部分”。

### 坑 3：列表项被单独切成 chunk

问题：

```text
Chunk N: "（1）战争、军事行动"
Chunk N+1: "（2）核辐射、核爆炸"
```

每个 chunk 都缺少“这是免责条款”的上下文。

解决：

- 识别列表结构，将前导句和所有列表项合并。
- 如果仍超长，至少保留前导句。

---

## 7. 优化思路（展现你的技术视野）

面试官可能问：还有哪些改进空间？

### 7.1 Late Chunking（最新研究）

传统方法：先切分，再 embedding。

Late Chunking：先整篇 embedding，再切分。

优势：每个 chunk 的向量包含全文上下文信息。

参考：Jina AI 的 late chunking 技术。

适用场景：新闻、博客等语义边界明显的文档。

### 7.2 语义切分（Semantic Chunking）

不用固定长度，而是用语义相似度判断切分点。

方法：

- 计算相邻句子的 embedding 相似度。
- 相似度突然下降的地方作为切分点。

### 7.3 动态 chunk size

不同文档类型使用不同的 chunk size：

- 技术文档：1024（需要完整代码块）。
- 法律文档：1536（条款复杂）。
- FAQ 文档：512（问题独立）。

### 7.4 Chunk 的后处理

切分完成后，用 LLM 做一遍质量检查：

- 识别语义不完整的 chunk，自动扩展。
- 识别信息密度低的 chunk（全是“参见第 X 条”），自动合并。

---

## 8. 准备面试官的追问

### Q1：为什么 chunk_size 选 1024？

回答思路：

我做了实验对比，选 1024 是因为：

1. 召回率最优（0.91）。
2. 答案质量显著提升（相对 512）。
3. 成本可控（相对 2048）。
4. 保险条款平均长度在 800-1200 tokens，1024 覆盖 90% 的场景。

### Q2：如何处理跨页的章节？

回答：

解析模块已经处理了跨页问题，输出的是连续的文本流。但我们会保留 `page_num` 信息，用于答案溯源：

- 检索到的 chunk 来自第 5 页和第 6 页。
- 告诉用户：“详见合同第 5-6 页”。

### Q3：如何避免重要信息被 overlap 覆盖？

回答：

Overlap 是“前一个 chunk 的尾部 + 当前 chunk 的全部”，不存在信息被覆盖，只是有重复。

重复内容会导致检索时返回多个相似 chunk，我们用 MMR（Maximal Marginal Relevance）去重。

---

## 9. 总结：切分模块的核心价值

✅ 不要说：“我用固定长度切分，overlap 100。”

✅ 要说：“我设计了基于文档结构的语义切分，通过层级分类器识别章节，用智能边界检测避免语义截断，召回率从 67% 提升到 91%。”

✅ 不要说：“表格单独成 chunk。”

✅ 要说：“大表格会按语义单元切分，每个 chunk 保留完整表头，避免 LLM 理解错误。”

✅ 不要说：“设置了 overlap。”

✅ 要说：“我用基于句子边界的智能 overlap，避免了 87% 的句子截断问题，并通过实验确定 100 tokens 是性价比最优点。”
