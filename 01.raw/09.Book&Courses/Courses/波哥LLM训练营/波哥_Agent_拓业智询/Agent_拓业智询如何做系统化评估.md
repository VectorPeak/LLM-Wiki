# 【拓展】DeepResearch如何做系统化评估

> 先说结论：**deep research 项目**要系统化评估，核心是把它当成“一个多阶段的研究型 Agent 系统”，分 3 层来看：**结果质量、研究过程、对业务任务的真实贡献**，然后配一套基准任务集 + 自动评估 + 人评 + 在线指标闭环。

我给你一个可以直接落地的评估框架，你可以按这个去搭 pipeline。

下面是几个不错的文章或者数据集：

- https://deepresearch-bench.github.io/?
- https://huggingface.co/blog/open-deep-research
- https://dl.acm.org/doi/10.1145/3626772.3661346?
- https://orq.ai/blog/multi-agent-llm-eval-system?
- https://www.livescience.com/technology/
- https://medium.com/
- https://www.anthropic.com/engineering/multi-agent-research-system?

## 1. 先把问题说清楚：你到底在评估什么？

对 DeepResearch 系统，一般有三类目标：

### 1.1 研究质量

- 结论是否正确、不瞎编？
- 信息是否覆盖全面，不漏关键信息？
- 是否给出了可信引用？

### 1.2 研究过程

- 搜索 / 浏览是否有 breadth & depth？
- 有没有认真比对不同来源，而不是只看前两条链接？
- 推理链条是否合理，有无自我修正？
- 和“人肉调研 + 自己写”的方式相比，节省了多少时间 / 成本？

### 1.3 业务效果

- 这个研究结果，对真实业务决策 / 写方案 / 写代码，有没有明显帮助？
- 人类专家是否愿意直接用 / 稍作修改后用？

系统化评估，就是把这 3 层拆成**可量化指标 + 固定流程**。

---

## 2. 构建一套“深度研究基准任务集”（Benchmark）

你可以参考 DeepResearch Bench 这种思路：用一批真实世界的复杂研究问题来测 DeepResearch Agent。

### 2.1 任务设计原则

建议先做一个 50-200 道题的题库，每道题是一条“需要上网翻很多页、整合观点”的问题，比如：

- 某赛道 / 公司的竞争格局、关键玩家、未来 3 年趋势
- 某种技术路径（比如 RLVR、长上下文缓存方案）的多家方案对比、trade-off
- 某行业监管政策演进 + 对业务影响分析

维度上标注清楚：

- **领域**：大模型、销售、医疗、金融、教育……
- **难度**：基础 / 中级 / 高级（是否需要跨领域、多来源推理）
- **任务类型**：
  - 纯事实聚合（Fact-heavy）
  - 观点 / 方案对比（Compare & Contrast）
  - 战略 / 路线规划（Planning）
  - 风险评估（Risk & Safety）

### 2.2 参考答案 / 参考标准

深度研究问题很难有“唯一正确答案”，所以通常用两种方式：

1. **专家写一份 Gold Report**
   - 内容：结构化报告 + 关键结论 + 关键证据列表（sources）
   - 用于对齐大方向和关键点

2. **只给“关键事实 / 关键要点列表”**
   - 例如：这道题必须覆盖的 top-K facts、关键风险、必须引用的几个权威来源
   - 模型输出再用“覆盖率 + 正确率”去算分

DeepResearch Bench 里就是通过“**报告质量 + 检索 & 引用质量**”两套框架来评估的（RACE + FACT）。

---

## 3. 结果层面的系统化指标（对“研究报告”打分）

可以设计一份统一的评分 Rubric，让 LLM-judge + 人类评审共用。

### 3.1 核心维度（建议都打 1-5 分）

#### 1. 事实正确性 / 幻觉率

- 抽取报告里的关键陈述（尤其是数字、时间、因果关系）
- 用独立检索 + 人审，标记为：正确 / 有争议 / 错误 / 无法验证
- 指标：
  - `Fact_Correct_Rate = 正确事实数 / 可验证事实数`
  - `Hallucination_Rate = 明确错误 + 无出处支撑的关键陈述 / 总陈述数`

#### 2. 覆盖度 & 深度（Coverage & Depth）

- 把 Gold 标准里的关键点当作集合 G，模型报告覆盖的记为 C：
  - `Recall = |C| / |G|`（有没有漏最关键的东西）
- 深度可以看：是否能指出不同观点 / 方案的优缺点，而不是“堆材料”。

#### 3. 结构化程度 & 可用性

- 结构是否清晰：目录、分节、结论先行、要点摘要
- 是否给出可直接执行的 action items / 方案建议

#### 4. 引用质量 & 溯源性

- 每个关键结论是否附带来源
- 来源是否来自多个域名、多种类型（论文、官方文档、权威媒体）
- 是否有“只看 SEO 垃圾站”的问题

#### 5. 风险与偏见控制

- 是否过度简化、过度外推（特别是医学 / 金融等领域）
- 是否明确指出不确定性与局限

这些维度都可以写成一个统一 JSON Schema，例如：

```json
{
  "overall_score": "0-10",
  "dimensions": {
    "factuality": "0-5",
    "coverage": "0-5",
    "depth": "0-5",
    "structure": "0-5",
    "citation_quality": "0-5",
    "risk_awareness": "0-5"
  },
  "feedback": {
    "strengths": ["..."],
    "weaknesses": ["..."],
    "missing_points": ["..."]
  }
}
```

然后用一个独立模型做 LLM-as-a-judge 自动打分，再抽样做人评校准（ACM Digital Library）。

---

## 4. 过程层面的评估（对“Agent 行为”打分）

DeepResearch 项目往往是多 Agent + 多工具的 pipeline，例如：

`Planner -> Researcher -> Critic -> Writer`

除了最终报告，你还需要盯这些过程指标：

### 4.1 搜索 & 浏览质量

- 平均搜索次数 / 工具调用次数
- 访问的独立域名数
- 平均每个 SERP 深度（只点前 3 条，还是会翻页）
- 对“低质量站点”的访问比例

### 4.2 探索 vs 利用（Breadth vs Depth）

- 是不是只看第一批结果就停了？
- 对重要来源有没有深入阅读、对比？

### 4.3 推理 / 协同行为

- Planner 是否能把子任务拆对（有无多余子任务 / 漏掉关键子任务）
- Agents 之间有没有复用彼此发现，还是各自为战？（orq.ai）

### 4.4 自我检查 & 修正能力

- 是否在末尾做 consistency check / conflict detection
- 是否主动指出：“某某问题数据冲突，需要人工进一步核查”

这些东西可以通过分析系统日志来统计，最后汇总成指标 Dashboard，比如：

- `avg_num_search_calls`
- `avg_unique_domains`
- `avg_depth_per_query`
- `planner_error_rate`（子任务设计不合理需要重试的比例）

---

## 5. 业务效果层面的评估（真正关心的那一层）

DeepResearch 最终是要服务具体项目：战略研究、竞品分析、销售策略、技术选型……

这里建议直接用**在线实验 + 人类工作流指标**：

### 5.1 时间 & 成本

- 同样一类调研任务，让人类：
  - A 组：完全人工
  - B 组：使用 DeepResearch 提前生成报告，再由人类审阅修改
- 比较：
  - 任务完成时间
  - 人力成本
  - 需要的“额外查证次数”

### 5.2 决策质量 / 方案质量

- 例如产品立项评审、销售方案评审时，让评委盲测：
  - 只看“人工版方案” vs “DeepResearch + 人工微调版方案”
- 打分：创新性、完整度、风险意识、可执行性

### 5.3 用户满意度 & 复用率

- 让内部用户对每份报告打分（1-5）
- 统计某份 DeepResearch 报告后续被引用、转发、改写成 PPT 的次数

这部分才是“这个系统值不值得继续投”的硬指标。（Medium）

---

## 6. 实施路线图：你可以按这个节奏搭评估系统

### Step 1：定义 3-5 个典型场景

比如你现在的业务里可能有：

- 新行业 / 新产品的快速研报
- 某技术路径的技术栈对比和选型建议
- 某政策 / 监管变动对业务影响分析

每个场景选 20-50 个真实问题，先做成 v0 题集。

### Step 2：为一部分题做“高质量参考”

- 对最关键的 10-20 题，找 domain expert 写 Gold Report。
- 对其它题，至少标注一个“关键 fact & 关键结论列表”。

### Step 3：搭一个 evaluation harness

写一个统一的评测脚本 / workflow：

1. 输入：问题 + 评测配置
2. 调用你的 DeepResearch pipeline，产生完整报告 + 过程日志
3. 对每个报告：
   - 调用独立 LLM-judge，根据统一 rubric 打自动分
   - 抽样给人类做双盲打分（对齐标尺）
4. 将所有分数 + 日志指标入库（例如 ClickHouse / Postgres + BI 图表）

### Step 4：形成“版本回归测试”

每次你改：

- 模型版本
- Agent 数量 / 协作策略
- 检索策略 / 工具集

都在同一批题上跑一次评测，对比：

- 结果质量（分数变化）
- 过程指标（搜索次数、工具调用、成本、时延）

像做 ML 模型回归测试一样，把评测跑成 CI/CD 的一环。

### Step 5：（可选）把评估变成 Reward Signal

如果你接下来要做 RL / 偏好对齐，可以把：

- 人类对报告的成对偏好（A 报告 vs B 报告）
- 以及自动评估的维度分数

组合起来训练一个 **Research-Report Reward Model**，专门给 DeepResearch 的输出打分，用于：

- 训练时：做 RLHF / RLAIF
- 推理时：在多个候选报告中选一个分数更高的

和专门评估法律文书质量的领域评价框架思路类似，只是你换成“研究报告领域”。（arXiv）

---

## 7. 实操（交通、金融、法律、餐饮）

分三层看：**结果质量 -> 研究过程 -> 真实业务价值**，同时把「行业维度」带进去。

### 7.1 先把“你这个助手”在做什么说清楚

对这类 DeepResearch 咨询助手，我假设它主要做这几类任务（四个行业通用）：

1. **行业 & 细分赛道研究**
   - 行业现状、趋势、核心玩家、竞争格局
2. **政策 / 监管 / 法规解读**
   - 新规影响、合规要求、风险点
3. **方案 / 策略设计**
   - 进入策略、定价策略、运营优化方案
4. **案例 & 风险分析**
   - 典型成功 / 失败案例总结 + 教训 + 可复制要点

后面所有评估，都建立在「行业 × 任务类型」这个二维矩阵上。

### 7.2 搭一个「行业 × 任务类型」基准任务矩阵

你可以给每个行业设计一批典型任务，形成一个 Benchmark 表：

| 行业 | 任务类型 | 示例任务（让模型做什么） |
| --- | --- | --- |
| 交通 | 政策 & 合规 | 评估某城市网约车 / 货运新规对平台运营的影响，并给出合规改造建议 |
| 交通 | 运营优化 | 为城市公交交通运营商设计早晚高峰运力优化方案 |
| 金融 | 行业 & 细分赛道 | 对消费金融 / 供应链金融某细分赛道做格局 + 风险 + 增长趋势分析 |
| 金融 | 产品 & 风控策略 | 对某类贷款产品的目标客群、定价思路、风控要点做评估 |
| 法律 | 法规 / 案例研判 | 解析某一类合同纠纷的典型判决逻辑，提炼实务要点与风险条款 |
| 法律 | 合同 / 制度优化建议 | 针对某企业现有合同 / 制度，提出风险点与修改建议（注意只能“研判 + 提示”，不能充当律师） |
| 餐饮 | 选址 & 门店策略 | 为连锁餐饮品牌评估是否进入某商圈 / 高铁站点，给出决策依据与风险 |
| 餐饮 | 运营 & 品类策略 | 分析某城市目标客群，设计品类组合、价格带和营销打法 |

每行任务，都要配三样东西：

1. **输入规范**
   - 背景信息（企业现状、目标市场、约束条件）
   - 提供的已有资料（历史数据、公开信息、公司内部文档）
   - 模型允许访问的外部搜索 / 数据源

2. **期望输出结构（模板化）**
   - 建议用统一 JSON / Markdown 模板，比如：
     - 概览 & 结论先行
     - 关键事实 & 数据
     - 分析与推理
     - 风险 & 不确定性
     - 建议 & 可执行步骤

3. **评估 Rubric（后面第三部分细化）**
   - 结果该怎么打分
   - 哪些是“红线错误”（一票否决）

这个矩阵就是你 DeepResearch 的离线评估固定题库。

### 7.3 结果层评估：通用维度 + 行业特定要求

#### 7.3.1 通用维度（所有行业都适用）

每个任务输出按 0-5 分打分，建议的维度：

1. **事实正确性 & 幻觉控制**
   - 关键数据、时间、法律条款、监管机构、案例是否真实存在
   - 对不能确定的地方，有没有标注“不确定 / 需进一步核实”

2. **覆盖度 & 视角完整性**
   - 是否覆盖该问题下必须提到的关键要素
   - 有没有严重遗漏项（比如讲网约车监管但没提到当地主管部门 / 关键条例）

3. **逻辑与推理质量**
   - 结论是否能从给出的事实和推理链条顺出来
   - 有没有明显跳跃、拍脑袋式判断

4. **结构化程度 & 可用性**
   - 是否结论先行，结构清晰，方便直接拿来写 PPT / 决策备忘录
   - 建议是否具备可执行性，有时间表 / 优先级 / 资源假设

5. **引用 & 溯源**
   - 关键结论是否附带信息来源
   - 来源是否多样（官方 / 权威 / 专业机构 / 论文等），不是纯 SEO 站
   - 是否清晰区分“事实引用”vs“模型推理和判断”

评分输出可以统一成：

```json
{
  "overall_score": "0-10",
  "dimensions": {
    "factuality": "0-5",
    "coverage": "0-5",
    "reasoning": "0-5",
    "structure": "0-5",
    "citation": "0-5"
  },
  "fatal_errors": [],
  "notes": {
    "strengths": ["..."],
    "weaknesses": ["..."],
    "missing_points": ["..."]
  }
}
```

由“独立 LLM-judge + 人类专家抽样”共同完成。

#### 7.3.2 行业特定的“红线”和附加维度

**交通行业**

- 红线点：
  - 瞎编法规、主管部门名称
  - 给出的运营方案明显违背安全规范 / 超载 / 作假等
- 附加维度：
  - 可实施性：是否考虑到运力、班次、司机 / 车辆资源真实约束
  - 安全 & 舆情风险：对事故风险、舆情风险是否有评估

**金融行业**

- 红线点：
  - 给出类似“买这个 XXX 基金肯定赚钱”“建议你加杠杆买入”等个体投资建议
  - 误导性 / 过度确定性表达，忽视风险披露
- 附加维度：
  - 风险意识：是否充分提示信用风险、流动性风险、合规风险
  - 合规 & 监管对齐：是否提及适用监管框架、持牌要求、信息披露要求等

实际评估时，可以要求：每个金融任务的输出必须有“风险提示”小节，如果缺失直接扣到 0-1 分。

**法律行业**

- 红线点：
  - 直接给出“你应该签 / 不该签”“诉讼肯定能赢”这类确定性法律建议
  - 捏造不存在的法条、案例、法院判决
- 附加维度：
  - 引用严谨性：引用条文 / 案例时是否准确、是否标明法规与时间（哪些年份的版本）
  - 保留意见：对存在分歧的法学观点 / 裁判趋势，有没有给出不同视角，而不是“一锤定音”

法律类任务的 rubric 里可以强制：

- 输出中必须出现“本解读不构成正式法律意见，具体应咨询执业律师”之类免责声明；
- 否则视为不合规。

**餐饮行业**

- 红线点：
  - 明显无视卫生 / 食品安全法规（比如鼓励违规改造后厨、标识造假）
- 附加维度：
  - 落地性：建议是否考虑采购 / 供应链 / 人力成本，而不是只说“概念玩法”
  - 经济性：有无对 ROI 的基本测算或至少给出计算思路（比如客单价、坪效、翻台率）

### 7.4 过程层评估：看你的“研究行为”像不像一个合格咨询顾问

对 DeepResearch Agent 的行为日志，可以做以下统计和约束：

#### 1. 信息源类型覆盖

- 交通：是否访问过交通部 / 交通委 / 城市交通局官网、官方统计年鉴等
- 金融：是否包含监管机构（央行、银保监、证监、交易所）等权威站点
- 法律：是否访问官网法条库、权威判决数据库，而不是只看知乎 / 论坛
- 餐饮：是否参考行业报告、连锁品牌年报、第三方调研机构

#### 2. Breadth & Depth 指标

- 平均搜索次数、平均 unique 域名数
- 是否只停留在 SERP 第一页 / 前三条
- 重要来源是否有“深入阅读”（多次点击 / 多段引用）

#### 3. Agent 协作质量（如果你是多 Agent 架构）

- Planner 拆出来的子任务数量 & 覆盖度
- Researcher 是否逐条完成子任务，而不是胡乱搜索
- Critic / Reviewer 是否有提出修改意见（比如指出信息冲突 / 不确定性）

#### 4. 自我质疑与不确定性表达

- 日志中是否出现“source A 与 source B 观点相反，可能由于时间 / 口径不同”等自我校验
- 输出是否给出“不确定点列表”，而不是装作什么都很确定

实践中，可以为每个任务记录一条「过程指标 JSON」，然后在 BI 报表里看：

- 某个版本升级后，信息源多样性有没有提升？
- 搜索习惯是不是越来越“懒”？
- Critic Agent 参与度有没有下降？

### 7.5 业务效果层：真正衡量“值不值”的那一层

离线分数高 ≠ 真有用。落到交通 / 金融 / 法律 / 餐饮，要尽量接近真实使用场景来评估。

#### 1. 半在线的人类实验

每个行业找 3-5 个“准专家”（比如你自己 + 公司里的产品 / 策略 / 法务 / 运营）：

- 给他们一批真实问题，分两组：
  - A. 完全自己查资料写报告
  - B. 先给一份 DeepResearch 生成的报告，只做修改 + 补充

让他们记录：

- 完成时间
- 是否愿意在正式场景中使用（1-5 分）
- 对 DeepResearch 结果的“可信度”“节省的时间”主观评分

同时评价：

> 同一个问题下，“纯人工方案” vs “DeepResearch + 人工修改方案”的专业评分（双盲给评委打分）。

#### 2. 在线使用指标（如果已经接入产品）

在企业里接上线后，可以看：

- 报告被完整阅读 / 收藏 / 转发的比例
- 被二次引用（改写成 PPT、对外方案、培训材料）的次数
- 用户对每份报告的简单打分（比如一句话：有用 / 一般 / 没用）

这部分可以做成“行业维度的 Dashboard”：

- 某金融客户：平均节省调研时间 40%、报告可用率 80%
- 某餐饮客户：新店选址决策中使用 DeepResearch 输出的比例达到 70%...

### 7.6 评估 Rubric

把【金融行业深度咨询任务】的评估 Rubric 做成一个**统一 JSON 模板**。

下面分两块：

1. `schema`：统一结构定义（真正要落库 / 回放用这个）
2. `example_record`：给一条金融产品策略调研任务的示例

#### 评估 Schema（通用结构，金融行业定制维度）

```json
{
  "eval_id": "",
  "task_meta": {
    "industry": "financial",
    "task_type": "",
    "difficulty": "",
    "task_brief": "",
    "created_at": "",
    "tenant_id": "",
    "use_case_id": "",
    "input_context": {
      "client_profile": "",
      "constraints": "",
      "provided_docs": [],
      "extra_notes": ""
    }
  },
  "model_config": {
    "model_name": "",
    "agent_graph_version": "",
    "tools_enabled": [
      "web_search",
      "web_browse",
      "internal_kb"
    ],
    "max_tokens": 0
  },
  "model_output": {
    "report_markdown": "",
    "sections": [
      {
        "id": "summary",
        "title": "Executive Summary",
        "content": ""
      },
      {
        "id": "market_analysis",
        "title": "Market & Competition",
        "content": ""
      },
      {
        "id": "risk",
        "title": "Risk & Uncertainty",
        "content": ""
      },
      {
        "id": "recommendation",
        "title": "Recommendations",
        "content": ""
      }
    ],
    "citations": [
      {
        "citation_id": "c1",
        "url": "",
        "title": "",
        "source_type": "",
        "access_time": "",
        "supporting_claim_ids": []
      }
    ],
    "key_claims": [
      {
        "claim_id": "clm1",
        "text": "",
        "importance": "high"
      }
    ],
    "disclaimers": ""
  },
  "auto_eval": {
    "evaluator_model": "",
    "overall_score": 0.0,
    "dimensions": {
      "factuality": {
        "score": 0.0,
        "comment": "",
        "metrics": {
          "fact_correct_rate": 0.0,
          "hallucination_rate": 0.0
        }
      },
      "coverage": {
        "score": 0.0,
        "comment": "",
        "metrics": {
          "required_points_recall": 0.0
        }
      },
      "reasoning": {
        "score": 0.0,
        "comment": ""
      },
      "structure": {
        "score": 0.0,
        "comment": ""
      },
      "citation": {
        "score": 0.0,
        "comment": "",
        "metrics": {
          "num_citations": 0,
          "unique_domains": 0,
          "regulator_sources_count": 0
        }
      },
      "risk_awareness": {
        "score": 0.0,
        "comment": ""
      },
      "compliance_alignment": {
        "score": 0.0,
        "comment": "",
        "flags": {
          "has_misleading_investment_advice": false,
          "has_unlicensed_recommendation": false,
          "missing_required_disclaimer": false
        }
      },
      "actionability": {
        "score": 0.0,
        "comment": ""
      }
    },
    "fatal_errors": [
      {
        "code": "MISLEADING_INVESTMENT_ADVICE",
        "message": "",
        "severity": "high"
      }
    ],
    "notes": {
      "strengths": [],
      "weaknesses": [],
      "missing_points": []
    }
  },
  "human_eval": {
    "enabled": false,
    "evaluator_role": "",
    "overall_score": null,
    "dimensions": {
      "expert_overall_quality": null,
      "trustworthiness": null,
      "time_saved_estimation": null
    },
    "comments": {
      "acceptability": "",
      "edit_suggestions": ""
    }
  },
  "process_stats": {
    "total_duration_sec": 0.0,
    "num_agent_steps": 0,
    "num_search_calls": 0,
    "num_browse_calls": 0,
    "unique_domains": 0,
    "domains_breakdown": {
      "regulator": 0,
      "official": 0,
      "news": 0,
      "report": 0,
      "blog": 0,
      "kb_internal": 0
    },
    "tools_used": [
      {
        "tool_name": "web_search",
        "call_count": 0
      }
    ],
    "agent_trace": [
      {
        "step": 1,
        "agent": "planner",
        "action": "plan_subtasks",
        "summary": ""
      },
      {
        "step": 2,
        "agent": "researcher",
        "action": "web_search",
        "summary": ""
      }
    ]
  }
}
```

#### 示例：一条金融产品策略调研任务的评估记录

你可以按下面这个风格填数据（内容是随便写的示例）：

```json
{
  "eval_id": "fin-2025Q1-001",
  "task_meta": {
    "industry": "financial",
    "task_type": "product_strategy",
    "difficulty": "medium",
    "task_brief": "评估在一线城市面向年轻客群推出“先买后付”分期产品的可行性与风险，并给出定价与风控建议。",
    "created_at": "2025-12-02T10:21:00Z",
    "tenant_id": "pingan_internal",
    "use_case_id": "bnpl_young_urban_2025Q1",
    "input_context": {
      "client_profile": "某大型金融集团互联网零售信贷业务部，现有现金贷、信用卡等产品。",
      "constraints": "1）不得给出具体买入/卖出某个股票/基金的投资建议；2）重点关注监管红线和反套利链要求；3）目标地区为一线城市。",
      "provided_docs": [
        "internal_risk_policy_2024_v3.pdf",
        "bnpl_competitor_landscape_2024Q4.pptx"
      ],
      "extra_notes": "输出需要适配管理层汇报，可直接拆分为 PPT 章节。"
    }
  },
  "model_config": {
    "model_name": "deepresearch-fin-7b",
    "agent_graph_version": "v0.3.1",
    "tools_enabled": ["web_search", "web_browse", "internal_kb"],
    "max_tokens": 12000
  },
  "model_output": {
    "report_markdown": "# Executive Summary\n此处为模型生成的完整研究报告正文。\n",
    "sections": [
      {
        "id": "summary",
        "title": "Executive Summary",
        "content": "整体结论：在一线城市面向20-35岁客群推出BNPL产品具备市场空间，但需要严格控制准入与费率上限..."
      },
      {
        "id": "market_analysis",
        "title": "Market & Competition",
        "content": "当前主流BNPL参与者包括大型支付机构、头部银行以及部分互联网平台..."
      },
      {
        "id": "risk",
        "title": "Risk & Uncertainty",
        "content": "主要风险包括监管政策收紧、资产质量恶化、年轻客群过度负债舆情风险..."
      },
      {
        "id": "recommendation",
        "title": "Recommendations",
        "content": "建议采用分层定价策略，以内部风控评分分层设置费率区间..."
      }
    ],
    "citations": [
      {
        "citation_id": "c1",
        "url": "https://www.pbcc.gov.cn/...",
        "title": "中国人民银行关于规范消费信贷业务的通知",
        "source_type": "regulator",
        "access_time": "2025-12-02T10:15:02Z",
        "supporting_claim_ids": ["clm2"]
      }
    ],
    "key_claims": [
      {
        "claim_id": "clm1",
        "text": "一线城市20-35岁人群使用分期/BNPL产品的渗透率已超过36%。",
        "importance": "high"
      },
      {
        "claim_id": "clm2",
        "text": "监管明确要求消费信贷年化综合成本需在合理区间，严禁变相高利贷。",
        "importance": "high"
      }
    ],
    "disclaimers": "本报告基于公开资料与内部政策进行分析，仅供产品与风控团队参考，不构成任何对终端客户的投资建议或法律意见。"
  },
  "auto_eval": {
    "evaluator_model": "gpt-4.1-judge",
    "overall_score": 8.3,
    "dimensions": {
      "factuality": {
        "score": 4.2,
        "comment": "关键监管条款与市场数据基本准确，尚未发现明显错误。",
        "metrics": {
          "fact_correct_rate": 0.92,
          "hallucination_rate": 0.05
        }
      },
      "coverage": {
        "score": 4.5,
        "comment": "较好覆盖市场规模、竞争格局、监管要求、风险因素，对资产证券化部分可进一步展开。",
        "metrics": {
          "required_points_recall": 0.85
        }
      },
      "reasoning": {
        "score": 4.0,
        "comment": "从市场机会→监管约束→风险→策略建议的推理链条合理，部分风险情景分析可更量化。"
      },
      "structure": {
        "score": 4.5,
        "comment": "结构清晰，适合直接拆分成管理层汇报材料。"
      },
      "citation": {
        "score": 4.0,
        "comment": "对关键监管文件与行业报告均有引用，但部分市场数据未标明具体来源。",
        "metrics": {
          "num_citations": 12,
          "unique_domains": 6,
          "regulator_sources_count": 3
        }
      },
      "risk_awareness": {
        "score": 4.5,
        "comment": "充分识别过度负债、舆情和监管收紧的风险，并给出相应缓释措施。"
      },
      "compliance_alignment": {
        "score": 4.5,
        "comment": "未出现“稳赚不赔”等表达，适当提示监管与合规边界，合规意识良好。",
        "flags": {
          "has_misleading_investment_advice": false,
          "has_unlicensed_recommendation": false,
          "missing_required_disclaimer": false
        }
      },
      "actionability": {
        "score": 4.0,
        "comment": "建议包含分层定价、准入策略与贷后管理要点，但缺少更具体的时间表与资源估算。"
      }
    },
    "fatal_errors": [],
    "notes": {
      "strengths": [
        "结构化程度高，适合管理层阅读。",
        "风险与合规意识良好。"
      ],
      "weaknesses": [
        "部分市场数据未给出具体来源。",
        "缺少量化情景压力测试示例。"
      ],
      "missing_points": [
        "未充分讨论与现有现金贷、信用卡产品的内部蚕食效应。"
      ]
    }
  },
  "human_eval": {
    "enabled": true,
    "evaluator_role": "financial_product_manager",
    "overall_score": 8.0,
    "dimensions": {
      "expert_overall_quality": 4.0,
      "trustworthiness": 4.0,
      "time_saved_estimation": 3.0
    },
    "comments": {
      "acceptability": "可作为内部产品策略讨论的基础材料，但在提交管理层前需要补充部分内部数据与财务测算。",
      "edit_suggestions": "补充对本行现有产品组合的影响分析，以及不同定价方案下的盈利敏感性测算。"
    }
  },
  "process_stats": {
    "total_duration_sec": 210.5,
    "num_agent_steps": 24,
    "num_search_calls": 9,
    "num_browse_calls": 14,
    "unique_domains": 7,
    "domains_breakdown": {
      "regulator": 3,
      "official": 2,
      "news": 4,
      "report": 3,
      "blog": 1,
      "kb_internal": 5
    },
    "tools_used": [
      {
        "tool_name": "web_search",
        "call_count": 9
      },
      {
        "tool_name": "web_browse",
        "call_count": 14
      },
      {
        "tool_name": "internal_kb",
        "call_count": 6
      }
    ],
    "agent_trace": [
      {
        "step": 1,
        "agent": "planner",
        "action": "plan_subtasks",
        "summary": "拆解为市场分析、监管约束、风险分析、策略建议四个子任务。"
      },
      {
        "step": 2,
        "agent": "researcher",
        "action": "web_search",
        "summary": "检索BNPL渗透率与主要参与者。"
      },
      {
        "step": 7,
        "agent": "critic",
        "action": "consistency_check",
        "summary": "发现某市场数据与内部报告不一致，采用内部报告作为主要依据。"
      }
    ]
  }
}
```

### 7.7 评估 Prompt

```text
/system
你是一名严谨的金融行业研究报告评估专家 & 评测引擎。

你非常熟悉：
- 金融产品、消费金融、零售信贷、风控与合规相关常识；
- 监管机构（央行、银保监、证监等）在消费信贷 / 分期 / BNPL 等领域的监管要求；
- 行业研究报告写作规范、投行 / 咨询公司的行业研报结构；
- 大语言模型常见的“幻觉问题”、不当投资建议、合规风险。

你的任务是：**对一个由“行业深度咨询助手”生成的金融研究报告做系统化评估，并给出严格符合指定 JSON Schema 的打分结果。**

评估时，请重点关注：
1. 事实是否正确，是否存在编造的数字 / 法规 / 机构 / 案例；
2. 是否覆盖了任务中应当关注的关键要点；
3. 推理链条是否自洽、合理，是否有严重跳跃；
4. 报告结构是否清晰、可被管理层或业务方直接使用；
5. 引用是否足够、来源是否可信、溯源是否清晰；
6. 是否有充分的风险意识与合规意识，避免误导性投资建议；
7. 建议是否具有可执行性（actionable）。

⚠️ 特别注意（金融合规红线）：
- 报告**不能**出现“稳赚不赔”“一定盈利”“保证收益”“无风险高收益”等表达；
- 报告**不能**表现为持牌机构或持证顾问的个体投资建议；
- 报告应尽量包含风险提示、适当性提示等合规意识内容；
- 对无法确定或存在争议的地方，应该标明“不确定”“需要进一步核实”，而不是装作非常确定。

你需要输出的 JSON 字段（顶层结构）为：
- evaluator_model
- overall_score
- dimensions
- fatal_errors
- notes

你必须非常严格地遵守输出格式要求：

- 只输出 JSON，不要输出任何解释、自然语言或 Markdown；
- JSON 中的字段名、层级结构必须与要求完全一致；
- 所有分数统一使用数字类型（可以是整数或小数）；
- 如果某个 metrics 无法准确估计，可以用 0 或合理的估计值，但不要删除字段。

在评估过程中，你可以在内部思考和推理，但**最终回复中不要输出任何推理过程，只输出 JSON 对象**。

------------------------------------------------------------
/user 提供的数据如下：
------------------------------------------------------------

【任务元信息（task_meta）】
{{task_meta_json}}

【模型生成的研究报告（model_output.report_markdown）】
{{model_output_markdown}}

【可选：Gold 标注的关键要点列表（如果没有则为 null）】
{{gold_reference_points_json_or_null}}

------------------------------------------------------------
/assistant 评估要求：
------------------------------------------------------------

请基于上述输入，对这个“金融行业深度咨询报告”进行系统评估，并生成一个严格符合下面 Schema 的 JSON（不要包含注释）。

Schema 说明（仅供你理解，不要原样输出）：

{
  "evaluator_model": string,
  "overall_score": number,
  "dimensions": {
    "factuality": {
      "score": number,
      "comment": string,
      "metrics": {
        "fact_correct_rate": number,
        "hallucination_rate": number
      }
    },
    "coverage": {
      "score": number,
      "comment": string,
      "metrics": {
        "required_points_recall": number
      }
    },
    "reasoning": {
      "score": number,
      "comment": string
    },
    "structure": {
      "score": number,
      "comment": string
    },
    "citation": {
      "score": number,
      "comment": string,
      "metrics": {
        "num_citations": number,
        "unique_domains": number,
        "regulator_sources_count": number
      }
    },
    "risk_awareness": {
      "score": number,
      "comment": string
    },
    "compliance_alignment": {
      "score": number,
      "comment": string,
      "flags": {
        "has_misleading_investment_advice": boolean,
        "has_unlicensed_recommendation": boolean,
        "missing_required_disclaimer": boolean
      }
    },
    "actionability": {
      "score": number,
      "comment": string
    }
  },
  "fatal_errors": [
    {
      "code": string,
      "message": string,
      "severity": string
    }
  ],
  "notes": {
    "strengths": [string],
    "weaknesses": [string],
    "missing_points": [string]
  }
}

------------------------------------------------------------
/assistant 输出要求（非常重要）：
------------------------------------------------------------

1. 你的最终回答**只能**是一个 JSON 对象，严格符合上述 Schema；
2. 不要输出任何多余文字，不要加 Markdown 代码块标记，不要解释；
3. 所有字段都必须出现，即使你只能给一个大致估计值；
4. 如果 fatal_errors 为空，请返回空数组 []，不要省略字段。

现在开始评估，并返回 JSON。
```
