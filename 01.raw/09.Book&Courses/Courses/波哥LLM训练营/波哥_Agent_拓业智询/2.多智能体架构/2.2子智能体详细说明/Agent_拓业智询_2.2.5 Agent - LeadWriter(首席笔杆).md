# 2.2.5 Agent - LeadWriter（首席笔杆）

## 目录

- [1 职责定位](#1-职责定位)
- [2 核心代码位置](#2-核心代码位置)
- [3 Prompt 设计](#3-prompt-设计)
  - [3.1 `SECTION_WRITING_PROMPT`（第30-80行）](#31-section_writing_prompt第30-80行)
  - [3.2 `SYNTHESIS_PROMPT`（第82-179行）](#32-synthesis_prompt第82-179行)
  - [3.3 `REVISION_PROMPT`（第181-209行）](#33-revision_prompt第181-209行)
- [4 核心实现](#4-核心实现)
  - [4.1 `process()` 入口（第220-227行）](#41-process-入口第220-227行)
  - [4.2 `_write_report()` 撰写报告（第229-272行）](#42-_write_report-撰写报告第229-272行)
  - [4.3 `_write_section()` 撰写单个章节（第274-357行）](#43-_write_section-撰写单个章节第274-357行)
  - [4.4 `_synthesize_report()` 整合报告（第358-435行）](#44-_synthesize_report-整合报告第358-435行)
  - [4.5 `_revise_report()` 修订报告（第436-488行）](#45-_revise_report-修订报告第436-488行)
- [5 Markdown 格式规范](#5-markdown-格式规范)
  - [5.1 标题编号](#51-标题编号)
  - [5.2 引用格式](#52-引用格式)
  - [5.3 图表占位符](#53-图表占位符)
- [6 两种模式对比](#6-两种模式对比)
- [7 模型选择](#7-模型选择)
- [8 SSE 事件流](#8-sse-事件流)
- [9 引用规范化](#9-引用规范化)
  - [9.1 收集引用来源](#91-收集引用来源)
  - [9.2 生成参考文献](#92-生成参考文献)
  - [9.3 前端渲染](#93-前端渲染)
- [10 报告结构示例](#10-报告结构示例)
- [11 总结](#11-总结)

## 1 职责定位
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260618105319577.png?imageSlim)
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260618105328455.png?imageSlim)
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260618105338184.png?imageSlim)

LeadWriter 是报告生成团队的“首席笔杆”，负责把 DeepScout、DataAnalyst、CodeWizard、ChiefArchitect 等智能体产生的零散事实、数据、图表与大纲，整合成逻辑严密、格式规范、引用完整的专业研究报告。

核心职责：

1. 深度写作：撰写有逻辑、有深度的行业分析内容。
2. Markdown 排版：生成适合前端和文档系统展示的专业 Markdown。
3. 图文混排：把文字、数据图表、图表占位符放入合适位置。
4. 参考文献：规范引用来源，保证链接可点击。
5. 两种模式：支持初稿撰写与审核反馈后的报告修订。

## 2 核心代码位置

核心文件：

```text
backend/app/service/deep_research_v2/agents/writer.py
```

该文件约 489 行，主要包括三类 Prompt 与五个核心方法：

- `SECTION_WRITING_PROMPT`
- `SYNTHESIS_PROMPT`
- `REVISION_PROMPT`
- `process()`
- `_write_report()`
- `_write_section()`
- `_synthesize_report()`
- `_revise_report()`

## 3 Prompt 设计

### 3.1 `SECTION_WRITING_PROMPT`（第30-80行）

`SECTION_WRITING_PROMPT` 用于撰写单个章节。它把研究主题、当前章节信息、事实、数据点、洞察和图表信息一起注入模型，让模型输出结构化的章节正文、要点、引用和改进建议。

```python
SECTION_WRITING_PROMPT = """你是一位顶级投行研究部的首席分析师，擅长撰写深度行业研究报告。

## 研究主题
{query}

## 当前章节信息
标题：{section_title}
描述：{section_description}
类型：{section_type}

## 可用素材

### 相关事实
{facts}

### 数据点
{data_points}

### 已有洞察
{insights}

### 相关图表
{charts_info}

## 写作要求
1. **专业性**：使用行业术语，体现专业深度
2. **逻辑性**：论点清晰，论据充分，层层递进
3. **数据支撑**：关键观点必须有数据或事实支撑
4. **引用规范**：使用可点击链接格式 [来源名称](URL)，如 [艾瑞咨询](https://www.iresearch.cn)
5. **图表整合**：在合适位置插入图表引用 ![图表标题](chart_id)
6. **字数控制**：本章节 500-1000 字
7. **不要重复标题**：正文开头不要再写章节标题

## 输出格式
JSON:
{
  "content": "章节正文内容（Markdown格式，不包含章节标题）",
  "key_points": ["本章节的核心要点"],
  "citations": [
    {"source": "来源名称", "url": "完整URL"}
  ],
  "suggested_improvements": ["如果有更多信息可以改进的地方"]
}

## 写作风格示例
- 好的开头："2024年，中国AI芯片市场正经历深刻变革。根据[IDC数据](https://www.idc.com)，市场规模达到..."
- 避免的开头："关于AI芯片，首先我们来看..."
- 数据引用示例："市场规模达5000亿元（[艾瑞咨询报告](https://www.iresearch.cn/report)）"

开始撰写："""
```

关键要求：

1. 专业性：使用行业术语，体现分析深度。
2. 逻辑性：观点清晰、论据充分、层层递进。
3. 数据支撑：关键观点必须有数据或事实支撑。
4. 引用规范：统一使用 `[来源名称](URL)` 的可点击链接格式。
5. 图表整合：在合适位置插入 `![图表标题](chart_id)`。
6. 字数控制：单章节 500-1000 字。
7. 不重复标题：章节正文开头不再重复章节标题。

输出结构是 JSON，核心字段包括：

```json
{
  "content": "章节正文内容（Markdown格式，不包含章节标题）",
  "key_points": ["本章节的核心要点"],
  "citations": [
    {
      "source": "来源名称",
      "url": "完整URL"
    }
  ],
  "suggested_improvements": ["如果有更多信息可以改进的地方"]
}
```

### 3.2 `SYNTHESIS_PROMPT`（第82-179行）

`SYNTHESIS_PROMPT` 用于把各章节合成为完整报告。它要求模型生成执行摘要、完整报告、核心结论、未来展望和参考文献。

```python
SYNTHESIS_PROMPT = """你是首席笔杆，需要将各章节整合成完整的研究报告。

## 研究主题
{query}

## 各章节内容
{sections_content}

## 收集的所有引用来源
{all_sources}

## 任务
1. 撰写报告摘要（Executive Summary）
2. 整合各章节，确保逻辑连贯，使用层级编号
3. 撰写结论与展望
4. 整理参考文献列表（确保链接可点击）

## 关键要求

### 1. 标题编号规则（必须严格遵守）
- 一级标题：1、2、3...（如：1 市场概况）
- 二级标题：1.1、1.2、2.1...（如：1.1 市场规模）
- 三级标题：1.1.1、1.1.2...（如：1.1.1 全球市场）
- 禁止标题重复：每个标题必须唯一，不要在正文中重复章节标题

### 2. 引用格式规则（确保可点击）
- 行内引用：使用 [来源名称](URL) 格式，如 [艾瑞咨询](https://www.iresearch.cn)
- 数据引用：在数据后标注来源，如 "市场规模达5000亿元（[IDC报告](https://www.idc.com)）"
- 文末参考文献：使用有序列表 + 可点击链接格式

### 3. 报告结构规范
- 不要在报告开头使用 # 一级标题
- 直接从"执行摘要"开始
- 各章节使用 ## 二级标题
- 子章节使用 ### 三级标题

## 输出格式
JSON:
{
  "executive_summary": "执行摘要（300-500字）",
  "full_report": "完整报告（Markdown格式，按下方结构生成）",
  "conclusions": ["核心结论1", "核心结论2"],
  "outlook": "未来展望",
  "references": [
    {"id": 1, "title": "来源标题", "url": "完整URL", "author": "作者/机构", "date": "日期"}
  ]
}

## 报告结构模板
Markdown:
## 执行摘要

[300-500字的研究摘要]

---

## 1 [第一章标题]

[章节引言段落]

### 1.1 [子章节标题]

[内容，包含数据引用如：根据[来源名](URL)，...]

### 1.2 [子章节标题]

#### 1.2.1 [三级标题]

[更详细的内容]

---

## 2 [第二章标题]

### 2.1 [子章节标题]

...

---

## 结论与展望

### 核心结论
1. [结论1]
2. [结论2]

### 未来展望
[展望内容]

---

## 参考文献

1. [来源标题1](URL1) - 作者/机构，日期
2. [来源标题2](URL2) - 作者/机构，日期
...
"""
```

整合阶段的重点：

1. 生成 300-500 字执行摘要。
2. 合并各章节并统一编号。
3. 生成结论与展望。
4. 整理参考文献列表，确保链接可点击。
5. 报告开头不使用 `#` 一级标题，直接从“执行摘要”开始。

### 3.3 `REVISION_PROMPT`（第181-209行）

`REVISION_PROMPT` 用于审核反馈后的报告修订。它会接收原始报告、审核反馈和补充信息，然后输出修订后的内容以及修订说明。

```python
REVISION_PROMPT = """你是首席笔杆，需要根据审核反馈修订报告。

## 原始报告
{original_content}

## 审核反馈
{feedback}

## 补充的新信息
{new_info}

## 任务
根据反馈修订报告，解决指出的问题。

## 修订原则
1. 针对性修改：只修改有问题的部分
2. 补充来源：对缺少来源的观点补充引用
3. 修正错误：纠正事实错误或逻辑漏洞
4. 保持风格：修订后保持报告整体风格一致

输出JSON:
{
  "revised_content": "修订后的内容",
  "changes_made": ["修改1", "修改2"],
  "addressed_issues": ["已解决的问题ID"],
  "unable_to_address": ["无法解决的问题及原因"]
}"""
```

修订原则：

1. 针对性修改：只改有问题的部分。
2. 补充来源：对缺少来源的观点补充引用。
3. 修正错误：纠正事实错误或逻辑漏洞。
4. 保持风格：修订后与报告整体风格一致。

## 4 核心实现

### 4.1 `process()` 入口（第220-227行）

`process()` 根据当前阶段分流：

- `WRITING` 阶段进入 `_write_report()`。
- `REVISING` 阶段进入 `_revise_report()`。
- 其他阶段直接返回状态。

```python
async def process(self, state: ResearchState) -> ResearchState:
    """处理入口"""
    if state["phase"] == ResearchPhase.WRITING.value:
        return await self._write_report(state)
    elif state["phase"] == ResearchPhase.REVISING.value:
        return await self._revise_report(state)
    else:
        return state
```

### 4.2 `_write_report()` 撰写报告（第229-272行）

`_write_report()` 是初稿模式的主流程：

1. 发送写作开始事件。
2. 逐章节调用 `_write_section()`。
3. 调用 `_synthesize_report()` 整合完整报告。
4. 发送写作完成事件。
5. 将阶段更新为 `REVIEWING`。

```python
async def _write_report(self, state: ResearchState) -> ResearchState:
    """撰写报告"""
    self.add_message(state, "research_step", {
        "step_id": f"step_writing_{uuid.uuid4().hex[:8]}",
        "step_type": "writing",
        "title": "内容生成",
        "subtitle": "撰写研究报告",
        "status": "running",
        "stats": {"sections_count": len(state["outline"]), "word_count": 0}
    })

    self.add_message(state, "thought", {
        "agent": self.name,
        "content": "开始撰写深度研究报告..."
    })

    # 逐章节撰写
    for section in state["outline"]:
        if section.get("status") not in ["final", "drafted"]:
            await self._write_section(state, section)

    # 整合报告
    await self._synthesize_report(state)

    # 发送完成事件
    word_count = len(state.get("final_report", ""))
    self.add_message(state, "research_step", {
        "step_type": "writing",
        "status": "completed",
        "stats": {
            "sections_count": len(state["outline"]),
            "word_count": word_count,
            "references_count": len(state.get("references", []))
        }
    })

    # 更新阶段
    state["phase"] = ResearchPhase.REVIEWING.value
    return state
```

### 4.3 `_write_section()` 撰写单个章节（第274-357行）
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260618105408107.png?imageSlim)

`_write_section()` 负责把当前章节所需素材组织成 Prompt，然后调用 LLM 生成章节正文。

输入素材包括：

- 与当前 `section_id` 相关的事实。
- 数据点 `data_points`。
- 已有洞察 `insights`。
- 当前章节对应的图表 `charts`。

```python
async def _write_section(self, state: ResearchState, section: Dict) -> None:
    """撰写单个章节"""
    section_id = section["id"]

    # 收集相关素材
    related_facts = [f for f in state["facts"] if section_id in f.get("related_sections", [])]
    if not related_facts:
        related_facts = state["facts"][:10]

    # 格式化事实
    facts_text = []
    for fact in related_facts:
        facts_text.append(f"- {fact.get('content')} (来源: {fact.get('source_name')}, 可信度: {fact.get('credibility_score')})")

    # 格式化数据点
    data_text = []
    for dp in state["data_points"][:10]:
        data_text.append(f"- {dp.get('name')}: {dp.get('value')} {dp.get('unit', '')} ({dp.get('year', 'N/A')})")

    # 格式化图表信息
    charts_info = []
    for chart in state["charts"]:
        if chart.get("section_id") == section_id:
            charts_info.append(f"- 图表: {chart.get('title')} (ID: {chart.get('id')})")

    prompt = self.SECTION_WRITING_PROMPT.format(
        query=state["query"],
        section_title=section.get("title", ""),
        section_description=section.get("description", ""),
        section_type=section.get("section_type", "mixed"),
        facts="\n".join(facts_text) if facts_text else "（暂无相关事实）",
        data_points="\n".join(data_text) if data_text else "（暂无数据点）",
        insights="\n".join([f"- {i}" for i in state["insights"][:5]]) if state["insights"] else "（暂无洞察）",
        charts_info="\n".join(charts_info) if charts_info else "（暂无图表）"
    )

    response = await self.call_llm(
        system_prompt="你是顶级的行业研究分析师，擅长撰写专业研究报告。",
        user_prompt=prompt,
        json_mode=True,
        temperature=0.4,
        max_tokens=16000
    )

    result = self.parse_json_response(response)

    if result and result.get("content"):
        section_content = result["content"]
        state["draft_sections"][section_id] = section_content
        section["status"] = "drafted"

        # 收集引用
        for citation in result.get("citations", []):
            state["references"].append({
                "id": len(state["references"]) + 1,
                "marker": citation.get("marker"),
                "source": citation.get("source"),
                "url": citation.get("url", "")
            })

        # 发送章节内容到过程报告
        self.add_message(state, "section_content", {
            "agent": self.name,
            "section_id": section_id,
            "section_title": section.get("title"),
            "content": section_content,
            "word_count": len(section_content),
            "key_points": result.get("key_points", [])
        })
```

核心逻辑：

1. 优先使用与章节相关的事实。
2. 如果没有相关事实，则回退使用前 10 条事实。
3. 将事实、数据点、洞察、图表统一格式化为文本。
4. 使用 `json_mode=True` 要求模型返回可解析 JSON。
5. 写入 `state["draft_sections"]`。
6. 把引用补充到 `state["references"]`。
7. 通过 `section_content` 事件把章节内容流式发送给前端。

### 4.4 `_synthesize_report()` 整合报告（第358-435行）

`_synthesize_report()` 负责将已生成的章节合并成完整报告，并整理参考文献。

```python
async def _synthesize_report(self, state: ResearchState) -> None:
    """整合完整报告"""
    self.add_message(state, "thought", {
        "agent": self.name,
        "content": "正在整合各章节，生成完整研究报告..."
    })

    sections_content = []
    for section in state["outline"]:
        section_id = section["id"]
        content = state["draft_sections"].get(section_id, "")
        if content:
            sections_content.append(f"## {section.get('title')}\n\n{content}")

    all_sources = []
    for ref in state["references"]:
        all_sources.append(f"- {ref.get('source')} ({ref.get('url', 'N/A')})")

    for fact in state["facts"]:
        source_entry = f"- {fact.get('source_name')} ({fact.get('source_url', 'N/A')})"
        if source_entry not in all_sources:
            all_sources.append(source_entry)

    prompt = self.SYNTHESIS_PROMPT.format(
        query=state["query"],
        sections_content="\n\n".join(sections_content) if sections_content else "（暂无章节内容）",
        all_sources="\n".join(all_sources[:30]) if all_sources else "（暂无来源）"
    )

    response = await self.call_llm(
        system_prompt="你是资深的研究报告主编，擅长整合和打磨最终报告。",
        user_prompt=prompt,
        json_mode=True,
        temperature=0.3,
        max_tokens=16000
    )

    result = self.parse_json_response(response)

    executive_summary = ""
    conclusions = []

    if result and result.get("full_report"):
        state["final_report"] = result.get("full_report", "")
        executive_summary = result.get("executive_summary", "")
        conclusions = result.get("conclusions", [])

        # 更新参考文献
        for ref in result.get("references", []):
            if ref not in state["references"]:
                state["references"].append(ref)
    else:
        # JSON解析失败时的备选方案
        fallback_report = f"# {state['query']} 研究报告\n\n"
        for section in state["outline"]:
            section_id = section["id"]
            content = state["draft_sections"].get(section_id, "")
            if content:
                fallback_report += f"## {section.get('title', section_id)}\n\n{content}\n\n"
        state["final_report"] = fallback_report

    # 发送报告完成事件
    self.add_message(state, "report_draft", {
        "agent": self.name,
        "content": state["final_report"],
        "executive_summary": executive_summary,
        "conclusions": conclusions,
        "word_count": len(state["final_report"]),
        "references_count": len(state["references"])
    })
```

整合流程：

1. 发送“正在整合报告”的 `thought` 事件。
2. 从 `outline` 与 `draft_sections` 拼接章节内容。
3. 从 `references` 和 `facts` 收集所有来源。
4. 调用 `SYNTHESIS_PROMPT` 生成完整报告。
5. 如果 JSON 解析失败，则使用 fallback 报告。
6. 通过 `report_draft` 事件发送最终草稿。

### 4.5 `_revise_report()` 修订报告（第436-488行）

`_revise_report()` 在 `REVISING` 阶段执行，用于根据 CriticMaster 的审核反馈修订最终报告。

```python
async def _revise_report(self, state: ResearchState) -> ResearchState:
    """根据反馈修订报告"""
    self.add_message(state, "thought", {
        "agent": self.name,
        "content": "根据审核反馈修订报告..."
    })

    unresolved = [f for f in state["critic_feedback"] if not f.get("resolved")]
    feedback_text = []
    for issue in unresolved:
        feedback_text.append(f"- [{issue.get('severity')}] {issue.get('description')} | 建议: {issue.get('suggestion')}")

    new_facts = state["facts"][-5:] if state["facts"] else []
    new_info = "\n".join([f"- {f.get('content', '')[:200]}" for f in new_facts])

    prompt = self.REVISION_PROMPT.format(
        original_content=state.get("final_report", "")[:6000],
        feedback="\n".join(feedback_text) if feedback_text else "无具体反馈",
        new_info=new_info if new_info else "无补充信息"
    )

    response = await self.call_llm(
        system_prompt="你是负责任的报告资深编辑。",
        user_prompt=prompt,
        json_mode=True,
        temperature=0.3,
        max_tokens=16000
    )

    result = self.parse_json_response(response)

    if result and result.get("revised_content"):
        state["final_report"] = result["revised_content"]

        for issue_id in result.get("addressed_issues", []):
            for feedback in state["critic_feedback"]:
                if feedback.get("id") == issue_id:
                    feedback["resolved"] = True

        self.add_message(state, "revision_complete", {
            "agent": self.name,
            "changes_count": len(result.get("changes_made", [])),
            "addressed_issues": result.get("addressed_issues", []),
            "unable_to_address": result.get("unable_to_address", [])
        })

    state["phase"] = ResearchPhase.REVIEWING.value
    return state
```

修订流程：

1. 收集未解决的 `critic_feedback`。
2. 取最近 5 条事实作为补充信息。
3. 截断原报告前 6000 字，避免上下文过长。
4. 调用 `REVISION_PROMPT` 生成修订内容。
5. 更新 `final_report`。
6. 标记已解决的问题。
7. 发送 `revision_complete` 事件。
8. 阶段回到 `REVIEWING`。

## 5 Markdown 格式规范

### 5.1 标题编号

LeadWriter 生成报告时必须保持层级编号清晰：

```markdown
## 1 市场概况

### 1.1 市场规模

#### 1.1.1 全球市场

---

## 2 竞争格局

### 2.1 头部企业
```

规则：

- 一级业务章节：`## 1`、`## 2`、`## 3`。
- 二级章节：`### 1.1`、`### 1.2`、`### 2.1`。
- 三级章节：`#### 1.1.1`、`#### 1.1.2`。
- 标题必须唯一，避免同名标题反复出现。
- 正文中不要再次重复章节标题。

### 5.2 引用格式

行内引用：

```markdown
根据[艾瑞咨询](https://www.iresearch.cn)数据，2024年中国AI市场规模达5000亿元。
```

数据引用：

```markdown
市场规模达5000亿元（[IDC报告](https://www.idc.com/report/2024)）
```

文末参考文献：

```markdown
## 参考文献

1. [艾瑞咨询2024年中国AI市场研究报告](https://www.iresearch.cn/report/2024) - 艾瑞咨询，2024-03-15
2. [IDC中国AI市场预测](https://www.idc.com/report/2024) - IDC，2024-02-20
```

### 5.3 图表占位符

报告正文中可以插入图表占位符：

```markdown
根据市场数据，AI市场持续增长：

![中国AI市场规模趋势](chart_trend_001)

从图中可以看出，市场规模从2020年的3200亿元增长到2024年的8500亿元。
```

前端替换逻辑：

1. 遍历 `state["charts"]`。
2. 找到 `id == "chart_trend_001"` 的图表。
3. 将 Markdown 中的图表占位符替换为实际图表组件。
4. 渲染方式可以是 ECharts 组件，也可以是图片标签。

## 6 两种模式对比

| 特性 | 初稿模式 | 修订模式 |
| --- | --- | --- |
| 触发阶段 | `WRITING` | `REVISING` |
| 输入 | 事实、数据、大纲 | 原报告 + 审核反馈 + 新信息 |
| 处理流程 | 逐章节撰写 -> 整合 | 直接修订全文 |
| temperature | `0.4`（更有创造性） | `0.3`（更保守） |
| 输出 | 完整报告草稿 | 修订后的报告 |
| 更新状态 | `draft_sections` + `final_report` | 只更新 `final_report` |

## 7 模型选择

配置位置：

```text
backend/app/config/llm_config.py
```

Writer 默认模型配置：

```python
writer: ModelConfig = field(default_factory=lambda: ModelConfig(
    model="deepseek-v3.2",
    temperature=0.4,  # 初稿模式
    max_tokens=16000
))
```

设计思路：

- 初稿阶段使用 `temperature=0.4`，让写作更自然、有一定表达空间。
- 修订阶段在调用时使用 `temperature=0.3`，让修改更稳定、更克制。
- `max_tokens=16000` 适合长报告章节与完整报告生成。

## 8 SSE 事件流

LeadWriter 会向前端持续发送写作过程事件，便于展示实时进度。

| 事件类型 | 说明 | 示例 |
| --- | --- | --- |
| `research_step` | 开始或完成写作步骤 | `{"step_type": "writing", "status": "running"}` |
| `thought` | Agent 思考过程 | `{"content": "开始撰写深度研究报告..."}` |
| `action` | Agent 动作 | `{"tool": "writing_section", "section": "市场概况"}` |
| `section_content` | 单章节完整内容 | `{"section_title": "...", "content": "...", "word_count": 800}` |
| `report_draft` | 完整报告草稿 | `{"content": "...", "executive_summary": "...", "word_count": 5000}` |
| `revision_complete` | 修订完成 | `{"changes_count": 3, "addressed_issues": [...]}` |

其中最关键的是：

- `section_content`：逐章节把已写好的内容发送出去。
- `report_draft`：最终整合后的完整报告草稿。
- `revision_complete`：修订阶段的完成事件。

## 9 引用规范化

### 9.1 收集引用来源

LeadWriter 会从两个地方收集引用来源：

1. 章节写作结果里的 `citations`。
2. 事实库 `facts` 中的 `source_name` 和 `source_url`。

```python
# 从章节写作结果收集
for citation in result.get("citations", []):
    state["references"].append({
        "id": len(state["references"]) + 1,
        "marker": citation.get("marker"),
        "source": citation.get("source"),
        "url": citation.get("url", "")
    })

# 从事实库补充
for fact in state["facts"]:
    source_entry = f"- {fact.get('source_name')} ({fact.get('source_url', 'N/A')})"
    if source_entry not in all_sources:
        all_sources.append(source_entry)
```

### 9.2 生成参考文献

最终参考文献使用结构化 JSON：

```json
{
  "references": [
    {
      "id": 1,
      "title": "艾瑞咨询2024年中国AI市场研究报告",
      "url": "https://www.iresearch.cn/report/2024",
      "author": "艾瑞咨询",
      "date": "2024-03-15"
    }
  ]
}
```

### 9.3 前端渲染

前端或 Markdown 渲染层可以把结构化引用渲染为可点击的参考文献列表：

```markdown
## 参考文献

1. [艾瑞咨询2024年中国AI市场研究报告](https://www.iresearch.cn/report/2024) - 艾瑞咨询，2024-03-15
```

## 10 报告结构示例

```markdown
## 执行摘要

中国AI市场正经历快速增长。根据[艾瑞咨询](https://www.iresearch.cn)数据，2024年市场规模达5000亿元，同比增长32%。计算机视觉、自然语言处理成为主要增长引擎。

---

## 1 市场概况

### 1.1 市场规模

2024年，中国AI市场规模突破5000亿元大关。

![中国AI市场规模趋势](chart_market_size)

从2020年的3200亿元增长到2024年的5000亿元，CAGR达12.5%（[IDC](https://www.idc.com)）。

### 1.2 增长驱动因素

主要驱动因素包括：

1. 政策支持：国家AI发展规划
2. 技术突破：大模型技术成熟
3. 应用落地：企业数字化转型需求

---

## 2 竞争格局

### 2.1 头部企业

百度、阿里巴巴、腾讯占据市场前三位...

---

## 结论与展望

### 核心结论

1. 中国AI市场保持高速增长
2. 计算机视觉、NLP 是核心增长引擎
3. 政策支持力度持续加大

### 未来展望

预计到2026年，中国AI市场规模将突破8000亿元...

---

## 参考文献

1. [艾瑞咨询2024年中国AI市场研究报告](https://www.iresearch.cn/report/2024) - 艾瑞咨询，2024-03-15
2. [IDC中国AI市场预测](https://www.idc.com/report/2024) - IDC，2024-02-20
```

## 11 总结

LeadWriter 是 Deep Research 系统中的报告生成核心 Agent。

核心能力：

1. 逐章节撰写：根据事实、数据点、洞察和图表生成章节正文。
2. 整合报告：把多个章节合成为完整研究报告。
3. 双模式运行：支持 `WRITING` 初稿模式与 `REVISING` 修订模式。
4. Markdown 规范：统一标题编号、引用格式与图表占位符。
5. 引用规范化：从章节输出和事实库收集来源，生成参考文献。
6. 流式输出：通过 `section_content`、`report_draft`、`revision_complete` 等事件持续反馈进度。

与其他 Agent 的协作关系：

- DeepScout 提供事实 `facts`。
- DataAnalyst 和 CodeWizard 提供数据分析与图表 `charts`。
- ChiefArchitect 提供报告大纲 `outline`。
- CriticMaster 提供审核反馈 `critic_feedback`。

LeadWriter 的下一个关键协作对象是 CriticMaster（毒舌评审家），由 CriticMaster 对报告进行严格评审，再由 LeadWriter 根据反馈完成二次修订。
