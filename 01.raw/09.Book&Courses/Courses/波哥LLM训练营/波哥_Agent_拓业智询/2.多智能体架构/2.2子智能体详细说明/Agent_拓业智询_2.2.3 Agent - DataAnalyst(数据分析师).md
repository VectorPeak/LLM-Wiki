# 2.2.3 Agent - DataAnalyst（数据分析师）

## 1. 职责定位

> DataAnalyst 负责从搜索结果中提取结构化数据，构建知识图谱，生成 ECharts 可视化配置。

核心职责：

1. 从文本中提取结构化数据点
2. 构建实体关系知识图谱（nodes + edges）
3. 生成 ECharts 图表配置（JSON）
4. 识别数据趋势和洞察
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260618105510199.png?imageSlim)

![DataAnalyst 知识图谱与图表可视化效果](https://img.vectorpeak.cn/obsidian/2026/05-06/dataanalyst_visual_examples_upload.png?imageSlim)

## 2. 核心代码位置

文件路径：`backend/app/service/deep_research_v2/agents/data_analyst.py`（479 行）

## 3. Prompt 设计（位置标注）

### 3.1 DATA_EXTRACTION_PROMPT（第 31-98 行）

用于从文本中提取结构化数据。

````python
# 数据提取 Prompt
DATA_EXTRACTION_PROMPT = """你是专业的数据分析师，擅长从文本中提取结构化数据。

## 研究主题
{query}

## 搜索结果
{search_results}

## 任务
从以上搜索结果中提取所有可量化的数据点，包括:
1. 市场规模数据（金額、单位、年份）
2. 增长率数据（百分比、时间段）
3. 市场份额数据（企业/领域、占比）
4. 排名数据（企业、产品、技术）
5. 时间序列数据（同一指标在不同年份的值）

## 输出要求
请输出JSON格式:
```json
{{
    "data_points": [
        {{
            "id": "dp_001",
            "name": "中国AI市场规模",
            "value": 5000,
            "unit": "亿元",
            "year": 2024,
            "source": "艾瑞咨询",
            "category": "market_size",
            "confidence": 0.9
        }}
    ],
    "time_series": [
        {{
            "id": "ts_001",
            "metric": "AI市场规模",
            "unit": "亿元",
            "data": [
                {{"year": 2020, "value": 3200}},
                {{"year": 2021, "value": 4100}},
                {{"year": 2024, "value": 8500}}
            ],
            "source": "艾瑞咨询"
        }}
    ],
    "distributions": [
        {{
            "id": "dist_001",
            "name": "细分领域市场份额",
            "year": 2024,
            "data": [
                {{"category": "计算机视觉", "value": 32, "unit": "%"}},
                {{"category": "自然语言处理", "value": 28, "unit": "%"}}
            ],
            "source": "IDC"
        }}
    ],
    "insights": [
        "中国AI市场规模在2024年突破5000亿元",
        "计算机视觉是最大的细分领域，占比32%"
    ]
}}
```

注意:
- 只提取有明确来源的数据
- confidence表示数据可信度（0-1）
- 如果没有找到相关数据，返回空数组
"""
````

输出格式：

```json
{
  "data_points": [
    {
      "id": "dp_001",
      "name": "中国AI市场规模",
      "value": 5000,
      "unit": "亿元",
      "year": 2024,
      "source": "艾瑞咨询",
      "category": "market_size",
      "confidence": 0.9
    }
  ],
  "time_series": [
    {
      "id": "ts_001",
      "metric": "AI市场规模",
      "unit": "亿元",
      "data": [
        {"year": 2020, "value": 3200},
        {"year": 2024, "value": 8500}
      ],
      "source": "艾瑞咨询"
    }
  ],
  "distributions": [
    {
      "id": "dist_001",
      "name": "细分领域市场份额",
      "year": 2024,
      "data": [
        {"category": "计算机视觉", "value": 32, "unit": "%"},
        {"category": "自然语言处理", "value": 28, "unit": "%"}
      ],
      "source": "IDC"
    }
  ],
  "insights": [
    "中国AI市场规模在2024年突破5000亿元"
  ]
}
```

### 3.2 KNOWLEDGE_GRAPH_PROMPT（第 100-141 行）

用于构建知识图谱。

> 上一步的结果，在这一步生成三元组。
>
> Prompt #1（SEARCH_ANALYSIS_PROMPT）中，LLM 返回 `entities_discovered`：
>
> `[{"name": "比亚迪", "type": "company", "relations": ["与宁德时代竞争"]}]`
>
> 然后 `_update_knowledge_graph(state, entities)` 添加节点（nodes）和边（edges）。这里需要注意：关系中的 target 只是字符串，没有独立实体 ID。

````python
# 知识图谱构建 Prompt
KNOWLEDGE_GRAPH_PROMPT = """你是知识图谱专家，擅长从文本中提取实体和关系。

## 研究主题
{query}

## 文本内容
{content}

## 任务
从以上文本中提取实体和关系，构建知识图谱。

## 实体类型定义
- core: 核心概念（如：人工智能、大模型）
- tech: 技术（如：深度学习、计算机视觉、NLP）
- company: 企业（如：百度、阿里巴巴、华为）
- policy: 政策（如：AI发展规划、数据安全法）
- product: 产品（如：ChatGPT、文心一言）
- person: 人物（如：创始人、CEO）

## 输出要求
请输出JSON格式:
```json
{{
    "nodes": [
        {{"id": "ai", "name": "人工智能", "type": "core", "importance": 10}},
        {{"id": "baidu", "name": "百度", "type": "company", "importance": 8}},
        {{"id": "cv", "name": "计算机视觉", "type": "tech", "importance": 7}}
    ],
    "edges": [
        {{"source": "baidu", "target": "ai", "relation": "布局"}},
        {{"source": "cv", "target": "ai", "relation": "属于"}},
        {{"source": "baidu", "target": "cv", "relation": "研发"}}
    ]
}}
```

注意:
- importance范围1-10，表示节点重要性
- 核心概念（core）的importance最高
- 提取5-15个最重要的实体
- 关系要简洁，2-4个字
"""
````

实体类型：

- `core`：核心概念（如：人工智能、大模型）
- `tech`：技术（如：深度学习、计算机视觉）
- `company`：企业（如：百度、阿里巴巴）
- `policy`：政策（如：AI发展规划）
- `product`：产品（如：ChatGPT、文心一言）
- `person`：人物（如：创始人、CEO）

输出格式：

```json
{
  "nodes": [
    {"id": "ai", "name": "人工智能", "type": "core", "importance": 10},
    {"id": "baidu", "name": "百度", "type": "company", "importance": 8},
    {"id": "cv", "name": "计算机视觉", "type": "tech", "importance": 7}
  ],
  "edges": [
    {"source": "baidu", "target": "ai", "relation": "布局"},
    {"source": "cv", "target": "ai", "relation": "属于"},
    {"source": "baidu", "target": "cv", "relation": "研发"}
  ]
}
```

所以可以看到，这一步之后，原本是零散的实体点，现在有关联了。

![DataAnalyst 生成的知识图谱关系示例](https://img.vectorpeak.cn/obsidian/2026/05-06/dataanalyst_knowledge_graph_upload.png?imageSlim)

### 3.3 CHART_GENERATION_PROMPT（第 143-242 行）

用于生成 ECharts 图表配置。

````python
# 图表生成 Prompt
CHART_GENERATION_PROMPT = """你是数据可视化专家，擅长生成ECharts图表配置。

## 研究主题
{query}

## 可用数据
{data}

## 任务
根据数据生成合适的ECharts图表配置，选择最能展示数据特点的图表类型。

## 图表类型选择规则
- 时间序列数据 -> line（折线图）
- 分类比较数据 -> bar（柱状图）
- 占比分布数据 -> pie（饼图）
- 进度/百分比 -> horizontal_bar（横向进度条）
- 多维对比 -> radar（雷达图）

## 设计要求
1. 配色使用简约专业色系:
   - 主色: #1677ff（蓝）
   - 辅助色: #52c41a（绿）, #722ed1（紫）, #fa8c16（橙）, #eb2f96（粉）
2. 标题简洁明了
3. 不要过多装饰，保持简约

## 输出要求
请输出JSON格式:
```json
{{
    "charts": [
        {{
            "id": "chart_001",
            "title": "中国AI市场规模",
            "subtitle": "2020-2024年市场规模（亿元）",
            "type": "line",
            "echarts_option": {{
                "grid": {{"left": "3%", "right": "4%", "bottom": "3%", "containLabel": true}},
                "xAxis": {{
                    "type": "category",
                    "data": ["2020", "2021", "2022", "2023", "2024"],
                    "axisLine": {{"lineStyle": {{"color": "#e8e8e8"}}}},
                    "axisLabel": {{"color": "#666"}}
                }},
                "yAxis": {{
                    "type": "value",
                    "axisLine": {{"show": false}},
                    "splitLine": {{"lineStyle": {{"color": "#f0f0f0"}}}}
                }},
                "series": [{{
                    "type": "line",
                    "data": [3200, 4100, 5200, 6800, 8500],
                    "smooth": true,
                    "symbol": "circle",
                    "symbolSize": 8,
                    "itemStyle": {{"color": "#1677ff"}},
                    "lineStyle": {{"width": 3}},
                    "areaStyle": {{
                        "color": {{
                            "type": "linear",
                            "x": 0, "y": 0, "x2": 0, "y2": 1,
                            "colorStops": [
                                {{"offset": 0, "color": "rgba(22,119,255,0.2)"}},
                                {{"offset": 1, "color": "rgba(22,119,255,0)"}}
                            ]
                        }}
                    }}
                }}]
            }}
        }},
        {{
            "id": "chart_002",
            "title": "细分领域市场份额",
            "subtitle": "2024年各技术领域占比",
            "type": "horizontal_bar",
            "echarts_option": {{
                "grid": {{"left": "25%", "right": "15%", "top": "5%", "bottom": "5%"}},
                "xAxis": {{"type": "value", "show": false, "max": 100}},
                "yAxis": {{
                    "type": "category",
                    "data": ["计算机视觉", "自然语言处理", "机器学习平台", "智能语音", "其他"],
                    "axisLine": {{"show": false}},
                    "axisTick": {{"show": false}},
                    "axisLabel": {{"color": "#333", "fontSize": 13}}
                }},
                "series": [{{
                    "type": "bar",
                    "data": [
                        {{"value": 32, "itemStyle": {{"color": "#1677ff"}}}},
                        {{"value": 28, "itemStyle": {{"color": "#722ed1"}}}},
                        {{"value": 24, "itemStyle": {{"color": "#1677ff"}}}},
                        {{"value": 10, "itemStyle": {{"color": "#52c41a"}}}},
                        {{"value": 6, "itemStyle": {{"color": "#fa8c16"}}}}
                    ],
                    "barWidth": 12,
                    "label": {{
                        "show": true,
                        "position": "right",
                        "formatter": "{{c}}%",
                        "color": "#666"
                    }},
                    "backgroundStyle": {{"color": "#f5f5f5"}},
                    "showBackground": true
                }}]
            }}
        }}
    ]
}}
```
"""
````

图表类型选择规则：

- 时间序列数据 → `line`（折线图）
- 分类比较数据 → `bar`（柱状图）
- 占比分布数据 → `pie`（饼图）
- 进度/百分比 → `horizontal_bar`（横向进度条）
- 多维对比 → `radar`（雷达图）

配色方案：

- 主色：`#1677ff`（蓝）
- 辅助色：`#52c41a`（绿）、`#722ed1`（紫）、`#fa8c16`（橙）、`#eb2f96`（粉）

## 4. 核心实现

### 4.1 `process()` 入口（第 253-318 行）

```python
async def process(self, state: ResearchState) -> ResearchState:
    """处理入口"""
    if state["phase"] == ResearchPhase.ANALYZING.value:
        return await self._analyze_data(state)
    return state
```

### 4.2 `_analyze_data()` 数据分析流程（第 259-318 行）

```python
async def _analyze_data(self, state: ResearchState) -> ResearchState:
    """执行数据分析"""
    self.logger.info("Starting data analysis...")

    # 发送开始事件
    self.add_message(state, "research_step", {
        "step_id": f"step_analyze_{uuid.uuid4().hex[:8]}",
        "step_type": "analyzing",
        "title": "数据分析",
        "subtitle": "生成可视化",
        "status": "running",
        "stats": {"results_count": 0, "charts_count": 0, "entities_count": 0}
    })

    # 1. 提取结构化数据
    extracted_data = await self._extract_data(state)

    # 2. 构建知识图谱
    knowledge_graph = await self._build_knowledge_graph(state)

    # 3. 生成可视化图表
    charts = await self._generate_charts(state, extracted_data)

    # 更新状态
    if knowledge_graph:
        state["knowledge_graph"] = knowledge_graph
        # 发送知识图谱事件
        self.add_message(state, "knowledge_graph", {
            "graph": knowledge_graph,
            "stats": {
                "entities_count": len(knowledge_graph.get("nodes", [])),
                "relations_count": len(knowledge_graph.get("edges", []))
            }
        })

    if charts:
        state["charts"].extend(charts)
        # 发送图表事件
        self.add_message(state, "charts", {
            "charts": charts
        })

    # 发送完成事件
    self.add_message(state, "research_step", {
        "step_type": "analyzing",
        "status": "completed",
        "stats": {
            "results_count": len(state.get("facts", [])),
            "charts_count": len(charts) if charts else 0,
            "entities_count": len(knowledge_graph.get("nodes", [])) if knowledge_graph else 0
        }
    })

    return state
```

### 4.3 `_extract_data()` 数据提取（第 320-358 行）

```python
async def _extract_data(self, state: ResearchState) -> Dict[str, Any]:
    """从搜索结果中提取结构化数据"""
    # 收集搜索结果
    search_results_text = []
    for fact in state.get("facts", [])[:20]:
        search_results_text.append(f"- {fact.get('content', '')} (来源: {fact.get('source_name', '未知')})")

    if not search_results_text:
        return {"data_points": [], "time_series": [], "distributions": [], "insights": []}

    prompt = self.DATA_EXTRACTION_PROMPT.format(
        query=state["query"],
        search_results="\n".join(search_results_text)
    )

    response = await self.call_llm(
        system_prompt="你是专业的数据分析师，擅长从文本中提取结构化数据。请输出JSON格式。",
        user_prompt=prompt,
        json_mode=True,
        temperature=0.2
    )

    result = self.parse_json_response(response)

    # 更新数据点到状态
    if result.get("data_points"):
        for dp in result["data_points"]:
            state["data_points"].append(dp)

    # 更新洞察
    if result.get("insights"):
        state["insights"].extend(result["insights"])

    return result
```

### 4.4 `_build_knowledge_graph()` 知识图谱构建（第 360-395 行）

```python
async def _build_knowledge_graph(self, state: ResearchState) -> Dict[str, Any]:
    """构建知识图谱"""
    # 收集内容
    content_parts = []
    for fact in state.get("facts", [])[:15]:
        content_parts.append(fact.get("content", ""))

    if not content_parts:
        return {"nodes": [], "edges": []}

    prompt = self.KNOWLEDGE_GRAPH_PROMPT.format(
        query=state["query"],
        content="\n".join(content_parts)
    )

    response = await self.call_llm(
        system_prompt="你是知识图谱专家，擅长从文本中提取实体和关系。请输出JSON格式。",
        user_prompt=prompt,
        json_mode=True,
        temperature=0.2
    )

    result = self.parse_json_response(response)

    # 添加节点大小（基于importance）
    if result.get("nodes"):
        for node in result["nodes"]:
            importance = node.get("importance", 5)
            node["size"] = 20 + importance * 3  # 20-50 range

    return result
```

节点大小计算：

- `importance` 范围 1-10
- 节点大小 = 20 + importance × 3
- 最小 23，最大 50

### 4.5 `_generate_charts()` ECharts 图表生成（第 397-442 行）

```python
async def _generate_charts(self, state: ResearchState, extracted_data: Dict[str, Any]) -> List[Dict[str, Any]]:
    """生成可视化图表"""

    # 准备数据
    data_for_charts = {
        "data_points": extracted_data.get("data_points", []),
        "time_series": extracted_data.get("time_series", []),
        "distributions": extracted_data.get("distributions", []),
        "existing_data_points": state.get("data_points", [])[:10]
    }

    # 如果没有足够数据，跳过
    total_data = (len(data_for_charts["data_points"]) +
                  len(data_for_charts["time_series"]) +
                  len(data_for_charts["distributions"]))

    if total_data == 0:
        self.logger.warning("没有足够数据生成图表，跳过")
        return []

    prompt = self.CHART_GENERATION_PROMPT.format(
        query=state["query"],
        data=str(data_for_charts)
    )

    response = await self.call_llm(
        system_prompt="你是数据可视化专家，擅长生成ECharts图表配置。请输出JSON格式。",
        user_prompt=prompt,
        json_mode=True,
        temperature=0.3
    )

    result = self.parse_json_response(response)
    charts = result.get("charts", [])

    # 为每个图表添加唯一ID
    for chart in charts:
        if not chart.get("id"):
            chart["id"] = f"chart_{uuid.uuid4().hex[:8]}"

    return charts
```

## 5. ECharts 配置示例

### 5.1 折线图（时间序列）

```json
{
  "id": "chart_001",
  "title": "中国AI市场规模",
  "subtitle": "2020-2024年市场规模（亿元）",
  "type": "line",
  "echarts_option": {
    "grid": {"left": "3%", "right": "4%", "bottom": "3%", "containLabel": true},
    "xAxis": {
      "type": "category",
      "data": ["2020", "2021", "2022", "2023", "2024"],
      "axisLine": {"lineStyle": {"color": "#e8e8e8"}},
      "axisLabel": {"color": "#666"}
    },
    "yAxis": {
      "type": "value",
      "axisLine": {"show": false},
      "splitLine": {"lineStyle": {"color": "#f0f0f0"}}
    },
    "series": [{
      "type": "line",
      "data": [3200, 4100, 5200, 6800, 8500],
      "smooth": true,
      "symbol": "circle",
      "symbolSize": 8,
      "itemStyle": {"color": "#1677ff"},
      "lineStyle": {"width": 3},
      "areaStyle": {
        "color": {
          "type": "linear",
          "x": 0,
          "y": 0,
          "x2": 0,
          "y2": 1,
          "colorStops": [
            {"offset": 0, "color": "rgba(22,119,255,0.2)"},
            {"offset": 1, "color": "rgba(22,119,255,0)"}
          ]
        }
      }
    }]
  }
}
```

### 5.2 横向进度条（市场份额）

```json
{
  "id": "chart_002",
  "title": "细分领域市场份额",
  "subtitle": "2024年各技术领域占比",
  "type": "horizontal_bar",
  "echarts_option": {
    "grid": {"left": "25%", "right": "15%", "top": "5%", "bottom": "5%"},
    "xAxis": {"type": "value", "show": false, "max": 100},
    "yAxis": {
      "type": "category",
      "data": ["计算机视觉", "自然语言处理", "机器学习平台", "智能语音", "其他"],
      "axisLine": {"show": false},
      "axisTick": {"show": false},
      "axisLabel": {"color": "#333", "fontSize": 13}
    },
    "series": [{
      "type": "bar",
      "data": [
        {"value": 32, "itemStyle": {"color": "#1677ff"}},
        {"value": 28, "itemStyle": {"color": "#722ed1"}},
        {"value": 24, "itemStyle": {"color": "#1677ff"}},
        {"value": 10, "itemStyle": {"color": "#52c41a"}},
        {"value": 6, "itemStyle": {"color": "#fa8c16"}}
      ],
      "barWidth": 12,
      "label": {
        "show": true,
        "position": "right",
        "formatter": "{c}%",
        "color": "#666"
      },
      "backgroundStyle": {"color": "#f5f5f5"},
      "showBackground": true
    }]
  }
}
```

## 6. 知识图谱结构

### nodes（节点）

```json
[
  {
    "id": "ai",
    "name": "人工智能",
    "type": "core",
    "importance": 10,
    "size": 50
  },
  {
    "id": "baidu",
    "name": "百度",
    "type": "company",
    "importance": 8,
    "size": 44
  },
  {
    "id": "cv",
    "name": "计算机视觉",
    "type": "tech",
    "importance": 7,
    "size": 41
  }
]
```

### edges（边）

```json
[
  {
    "source": "baidu",
    "target": "ai",
    "relation": "布局"
  },
  {
    "source": "cv",
    "target": "ai",
    "relation": "属于"
  },
  {
    "source": "baidu",
    "target": "cv",
    "relation": "研发"
  }
]
```

## 7. 模型选择

配置位置：`backend/app/config/llm_config.py`

```python
data_analyst: ModelConfig = field(default_factory=lambda: ModelConfig(
    model="qwen-max",
    temperature=0.2,
    max_tokens=8000
))
```

## 8. SSE 事件流
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260618105611295.png?imageSlim)

DataAnalyst 发送的 SSE 事件：

| 事件类型 | 说明 | 示例 |
| --- | --- | --- |
| `research_step` | 开始/完成分析 | `{"step_type": "analyzing", "status": "running"}` |
| `knowledge_graph` | 知识图谱 | `{"graph": {...}, "stats": {...}}` |
| `charts` | 图表配置 | `{"charts": [...]}` |

## 9. 数据提取类型

### 9.1 数据点（data_points）

单个数据值：

```json
{
  "name": "中国AI市场规模",
  "value": 5000,
  "unit": "亿元",
  "year": 2024,
  "source": "艾瑞咨询",
  "category": "market_size",
  "confidence": 0.9
}
```

### 9.2 时间序列（time_series）

同一指标在不同时间的值：

```json
{
  "metric": "AI市场规模",
  "unit": "亿元",
  "data": [
    {"year": 2020, "value": 3200},
    {"year": 2021, "value": 4100},
    {"year": 2024, "value": 8500}
  ],
  "source": "艾瑞咨询"
}
```

### 9.3 分布数据（distributions）

占比或分类数据：

```json
{
  "name": "细分领域市场份额",
  "year": 2024,
  "data": [
    {"category": "计算机视觉", "value": 32, "unit": "%"},
    {"category": "自然语言处理", "value": 28, "unit": "%"}
  ],
  "source": "IDC"
}
```

## 10. 总结

> DataAnalyst 专注于数据和可视化，核心能力：
>
> 1. 结构化提取：从文本中提取数据点、时间序列、分布数据
> 2. 知识图谱：构建实体关系图（nodes + edges）
> 3. ECharts 配置：生成标准的 ECharts JSON 配置
> 4. 数据洞察：识别趋势和关键发现
> 5. 节点大小：根据 importance 自动计算节点可视化大小

与 CodeWizard 的区别：

- DataAnalyst：生成 ECharts JSON 配置（纯配置，不执行代码）
- CodeWizard：生成并执行 Python 代码，输出图片（base64）

下一章节将介绍 CodeWizard（数据极客）。
