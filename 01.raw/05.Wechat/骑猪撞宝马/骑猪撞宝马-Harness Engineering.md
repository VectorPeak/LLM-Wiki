## 2. Harness Engineering

Harness Engineering 是 2026 年行业的热门考点。业界有一种定义：**Agent − Model = Harness**。从工具使用、模型记忆配置、测试机制、Agent 架构选择——都属于 Harness 的范畴。

**学习路线建议：**

- **理解概念**（2.1–2.3）：梳理 Harness 的定义、演进脉络和实践要点。相关视频很多但内容大同小异，挑一个看就够了——理解概念和思想即可。
- **实战运用**（2.4）：基于 Raj 的 _Engineering Coding Harnesses Deep Dive_ 视频精读，给出了具体的 Harness 使用思路，配合大量实验和论文支撑，结合面试题讲解。对面试、做 Agent 项目、日常使用 AI 都有直接帮助。
- **案例拆解**（2.5–2.6）：解析 Anthropic 官方架构和 Claw Code 项目的 Harness 设计。深入体会靠自己在项目中不断实践。
- **面试速览**（2.7）：提炼面试可直接使用的回答模板。

完成路线 a、b 后，应对 Harness 面试问题基本无虞。

---

## 2.1 概念定义

### 一句话定义

Harness Engineering 是围绕 AI 模型构建"运行环境与管控基础设施"的工程实践，目的是让 AI Agent 在长时、复杂、多步骤的真实任务中稳定、可靠、高效地运行。

### 核心类比：从"马具"理解 Harness

Harness 的本意是马具——套在马身上用来驾驭的装备（缰绳、头套等）。马本身强大，但必须借助马具才能被人驾驭、为人所用。

迁移到 AI 颟域：

- **大模型 = 一匹脱缰的马** — 能力极强，但任由它自由奔跑就会发散思维、产生幻觉，无法稳定输出预期结果。
- **Harness = 驾驭大模型的马具** — 控制、约束、引导大模型的系统。

由此推导出常见公式：

> **Harness = Agent − Model**
>
> 即：一个完整的 Agent 减去大模型本身，剩余的所有东西都是 Harness。
>
> ⚠️ 注意：_Harness Engineering_ 是非常新的概念，业界尚未形成严格定义；该公式是目前较被认可的表述，并非学术定义。

**具体例子**：在 Claude Code 中，所有不属于 Claude 模型本身的部分都属于 Harness——`CLAUDE.md` 中规定的规则、可使用的工具列表、定时调度机制等。

---

## 2.2 演进脉络

| 阶段 | 时间 | 核心问题 | 人的角色 | 类比 |
|---|---|---|---|---|
| **Prompt Engineering** | 2023–2024 | "怎么把问题问清楚" — 如何组织 Prompt 让模型理解真实意图 | 导演 | 调一句话 |
| **Context Engineering** | 2025 | "怎么把信息给好" — 在最合适时机把最合适内容（Prompt、工具列表、对话历史等）放进 Context | 图书管理员 | 管一窗信息 |
| **Harness Engineering** | 2026 | "怎么搭好整个系统" — 围绕大模型搭建完整可靠的 Agent，覆盖权限管控、工具管理、调度机制等 | 架构师 | 搭一套系统 |

> 三者是**叠加关系**：Harness 内部的每个 session 仍需 Context Engineering；每次发给模型的 prompt 仍需 Prompt Engineering。

---

## 2.3 Harness 工程实践要点

- **外部持久记忆** — 用文件系统（JSON、Markdown、git log）代替模型内部记忆，解决"失忆"问题。
- **确定性验证轨道** — Linter、类型检查、单元测试等刚性门禁；AI 的输出必须通过测试才能被接受（杜绝"幻觉完成"）。
- **原子任务 + 上下文刷新** — 每个 Agent 只做一个小任务就销毁；新 Agent 从干净状态启动，彻底杜绝 Context Rot。
- **子 Agent 集群（Swarm）** — 用大量便宜快速的小模型并行工作，而非一个大模型顺序处理。
- **技能文件（Skills）** — 按需加载的专用指南；Agent 只看到与当前任务相关的工具和说明（建议不超过 30 个工具）。
- **Guard Rails + Checkpoints** — 在关键节点自动运行检查，防止 Agent 偏离轨道。
- **Handoffs** — session 之间通过进度文件、git commit 等传递状态，实现跨 session 连续性。
- **Human-in-the-loop** — 在关键阶段设置人工审核断点，弥补 AI 自验证的不足。
- **架构约束** — 通过 ArchUnit 等框架强制要求 Agent 生成的代码遵循特定模式。
- **垃圾回收 Agent** — 定期扫描修复代码库和文档中的不一致性，对抗系统熵增。

### 关键工程原则

- **轻量化，为删除而建** — 不要过度编码人类知识；模块要能快速移除替换（Manus 6个月5次重构、Vercel 删 80% 手工工具反而更好）。
- **模型无关性** — Harness 不绑定特定模型，新模型出来能快速替换。
- **将 Harness 视为数据集** — 每次 Agent 失败、漂移、异常都是珍贵的训练素材，用于迭代优化。

---

## 2.4 Harness 思想的运用

> 本节基于 Raj 的 _"Engineering Coding Harnesses Deep Dive"_ 视频精读。该视频足够细节，讲解了 Harness 在日常工作中的应用，且结论均经实验和论文支撑。对面试、实战、做项目都有直接帮助。

从四个方面展开：**Retrieval / Context & Memory / Loops & Tools / Orchestration**。每个部分都给出具体建议，并结合大量面试问题讲解。

---

### 2.4.1 Retrieval（检索）

#### 背景

需要根据任务场景为 AI 配备检索工具。Claude Code 内置了 `grep`，但它面向通用场景；我们的任务是定制的。

**示例**：100GB 代码库下，直接让 Claude Code 用 `grep` 线性扫盘会很慢；这时可以建 BM25 倒排索引，以 Skill 形式装上，让 CC 调用。

检索工具从"词法"到"语义"是一条谱系，而非非此即彼：

| 工具 | 优点 | 缺点 | 适用场景 |
|---|---|---|---|
| `grep` | 久经考验、快、关键词精准 | 文件多了线性扫描变慢 | 默认起手；代码库 < 5GB 或文件数 < 10w 时不用换 |
| BM25 倒排索引 | 索引化、查询快 | 仍是词法匹配，无法处理同义 | 代码库 > 5GB 或文件数 > 10w；`grep` 单次搜索 > 5s |
| Semantic Search (embedding) | 能处理同义关系（`physician ≈ doctor`） | 慢、有 chunk 成本 | 关键词散在多个同义词时（如"鉴权"→ `auth/login/session/jwt`）；日常代码定位不用 |
| Agentic RAG（推荐） | 模型自己重写 query、迭代检索，可不切块、文件级操作 | 多轮调用更贵（2–5× token） | 用 Opus/GPT-5 级别模型 + 愿意多付 token 时，是当前精度上限 |
| 结构化数据库 / 索引 | 支持按字段过滤、排序、join | 重，需建模 | 查询含 metadata join（按 author/时间/路径过滤排序）时 |

> 表中 ">5GB / >10w" 等阈值是工程经验值，源视频只笼统说 _"as you get more and more files"_。
>
> Raj 的实验结论："Agentic + 纯 BM25" 反超了 "One-shot + embedding 切块"——但这意味着 **"embedding 从必选变可选"**，而非 "BM25 取代 embedding"。

#### 最佳实践建议

- **默认 `grep` 起手**：90% 的代码搜索靠 `grep` 就够，不要一上来就上向量库。
- **代码库 > 5GB 或文件数 > 10w，加 BM25**：封装成 SKILL（`ripgrep --index` 或开源 BM25 库），让模型像调工具一样用。
- **跨语言/跨同义词的查找才用 embedding**：如"用户鉴权相关代码"关键词散在 `\auth/login/session/jwt`。日常代码定位别用。
- **配好模型（Opus/GPT-5 级别）就上 Agentic RAG**：让模型自己重写 query、按文件级迭代，比预先 chunk 切片更准；前提是愿意多花 2–5× token。底层用 BM25 / embedding / 混合均可。
- **文件级 > chunk 级**：能不切块就不切块，整文件交给模型，避免上下文撕裂。
- **何时迁数据库**：需要"按 author 过滤 + 按 commit 时间排序 + 按路径匹配"这种 metadata join 时才考虑结构化索引；纯文本搜索别上 DB。

#### 面试问题

**Q1：Harness 工程对你的工程实践有什么启发？**

最大启发：**不要把通用 AI 工具当万能工具，而要根据业务场景给它配检索工具**。Claude Code 内置的 `grep` 在通用场景下够用，但严肃业务都是定制的——代码库可能 100GB，文档可能跨多个仓库，查询可能带 metadata 过滤。通用工具会慢甚至搜不到。

具体做法三步：
1. 看任务量级和查询形态——文件多大、查询是纯文本还是带字段过滤；
2. 按谱系选工具——`grep` / `BM25` / `embedding` / `结构化 DB`，能用轻的就不上重的；
3. 用 Skill 封装定制工具让 Agent 调用。

这其实是 Harness 工程的核心——Agent 的能力上限不只取决于模型，更取决于你给它配的工具链。

---

**Q2：如何看待 RAG 的发展趋势？会不会被取代？**

判断：**目前没有被取代，但它在 stack 里的位置变了**。

趋势不再是"什么场景都先上 RAG"：
1. 中小项目，`grep / BM25 + 模型自身能力` 能解决大部分检索问题；
2. 高级场景中，**Agentic RAG**（哪怕底层只用 BM25）也能反超传统"切块 + embedding RAG"——模型变强后，"语义近似"不一定非要靠 embedding，模型自己重写 query 就行。

但这不等于 RAG 被取代：
1. Agentic RAG 本身就是 RAG，只是把"一次检索"换成"迭代检索"；
2. embedding 在跨语言、跨同义词、海量文档场景仍是性价比最高的选择；
3. 企业级场景需要 metadata join，又得叠结构化数据库 + RAG 的混合方案。

更准确的说法：**RAG 从"默认必选"降级成"按需启用的一档"**。判断要不要用，看三个条件：**模型强度、文档规模、查询是否需要跨同义词或跨字段**。

---

### 2.4.2 Context & Memory（上下文与记忆）

#### 背景

主流模型号称 1M token 上下文，但实测填越多越退化——通常超过一半就开始丢信息。"有 1M 窗口" ≠ "能用 1M 窗口"，可靠使用的往往只有前 30–50%。信息越来越多（长对话、错误日志、跨会话项目知识），但能放进窗口的就这么多——该把什么放进来、什么放出去、什么留到下次？

视频博主将记忆拆成三层：**Active Context Window、Working State、Durable Memory**。

> 记忆的分类有很多说法（短期/长期、工作记忆/情景记忆等），各开源架构（CC、OpenHands）也各有叫法。本质是一回事，只是切分粒度不同。本节更重要的是记忆背后的**最佳实践和蕴含的思想**。

#### 基础知识：三层记忆

**Layer 1：Active Context Window（当前上下文）**

这一轮 API 调用真正发给模型的 token。职责是**管好"现在"**——决定这次推理时模型能看到什么。因为窗口会退化，核心工作是"瘦身"：

- 用 sliding window 只保留最近几轮；
- 用 compaction 把老对话压成摘要；
- 用 rewind 把走错的分支直接砍掉，避免错误内容继续占窗口。

**Layer 2：Working State（临时工作文件）**

和跨会话记忆相同之处是都用外部文件存储；不同之处在于：这是给当前对话用的，对话完就丢。而长期记忆的文件是跨会话的。

启示：**不要什么东西都往上下文塞**，可以把一些结果保存在磁盘，运行时动态查找。因为上下文很宝贵。

任务进行中、塞不进窗口的中间状态落到**文件系统里**。职责是**管好"这次任务"**——给 Agent 一张比 context window 大得多的"草稿纸"。典型如 `\plan.md` / `\todo.md`：让 Agent 边做边勾选，目标不会在长循环中走丢。

更激进的做法是 **Recursive Language Models 范式**：把所有历史都落盘，用 Python REPL 按需检索，相当于"无限上下文"。任务结束这层可以扔掉。

**Layer 3：Durable Memory（跨会话长期记忆）**

跨会话留下来的知识，下次新开会话还能用。职责是**管好"这个项目 / 这个 Agent"**——把经验沉淀下来，不要每次重学。

两种主流形态：
- **AGENTS.md**：项目级事实（构建命令、目录约定、坑），主流 Harness 会自动注入 system prompt。
- **Skills**：可视为 Agent 持久记忆的新表现形式。

> 三层自下而上递进：窗口装不下 → 落到 working files；任务结束还想留 → 升级成 durable memory。

#### 最佳实践建议

**Layer 1：Active Context Window —— 管好"现在"**

1. **主动压缩上下文，不要等满了再压缩** — 模型能力随窗口增大而退化，主动压缩比被动等系统压缩更可控。

2. **不要过于依赖模型的自动 compaction** — 很多 compaction 是黑盒，你不知道它丢了什么。主动压缩、指定保留哪些信息是好的工程实践。

   使用 Claude Code 的 `/compact`，后加参数，明确告诉它"保留所有架构决策和待办事项"——指定保留什么比让它自己挑靠谱得多。

   示例命令：
   ```
   /compact 保留所有架构决策和待办事项。
   ```

3. **只保留关键信息在上下文中** — 长 stack trace、20000 行日志，先在 Agent 层截断/抽取关键帧再喂回去。使用 `rewind`（双击 ESC）把走错的分支直接砍掉，不让错误信息继续占窗口。

> 这些原则对实践与面试都有帮助——如"你用 CC 有什么心得？""你觉得 CC 比其他 coding 工具好在哪？"

---

**Layer 2：Working State —— 好"这次任务"**

- **长任务先写 todo markdown**：把计划落盘成 `\plan.md` / `\todo.md`，让 Agent 每完成一步勾选；避免任务在长循环中丢目标。（Langchain 的 Deep Agent 就是这么做的）
- **能落盘就别塞上下文**：中间产物（搜索结果、抓取的网页、生成的代码片段）写文件，让 Agent 按需读。上下文很贵，磁盘很便宜。
  > 博主举的例子：让 Agent 所有历史落盘，用 Python REPL 按需检索，相当于给 Agent 一张"无限大草稿纸"——效果更好。
- **任务结束就清理**：working files 是一次性的，完成后归档或删除，别污染下一次任务。

---

**Layer 3：Durable Memory —— 好"这个项目 / 这个 Agent"**

**`AGENTS.md` 铁律：**

1. **手写不自动生成**；
2. **只写"项目特有的事实"**（构建命令、目录约定、坑），不写通用编程知识；
3. **定期复盘删过时条目** — Boris（CC 开发者）建议每次大模型升级或每季度复盘一次；
4. **AGENTS.md 写废话反而会误导模型** — 详见论文部分。

**写 Skill 的判定标准：**

1. **同一类操作做过 3 次以上 + 步骤超过 5 步 + 通用模型容易做错** — 同时满足才值得沉淀成 Skill。一次性别做。
2. **Skill 建议配上 eval** — 如果 Skill 里写了很多模型已知常识，反而会降低性能。给每个 Skill 准备小评测集，定期跑 `with skill vs without skill` 对照；模型升级后重跑，发现负贡献立刻下线。

#### 面试问题

**Q1：分享一下使用 Claude Code 的小技巧。**

最大心得：**要主动管理上下文，别赌模型自己能管好**。底层原因——主流模型号称 1M 窗口，但实测填得越满越退化，可靠的部分往往只有前 30–50%。"窗口大" ≠ "能用满"，主动瘦身是必须的。

落到 Claude Code 上，两个原生功能：

1. **`/compact` 而不是等它自己压**：CC 自带自动 compaction 是黑盒。做法是上下文用到 50% 左右主动触发，且 `/compact` 后加参数，明确指定"保留所有架构决策和待办事项"——指定保留什么比让它自己挑靠谱得多。

2. **走错路用 Rewind（双击 ESC）直接砍掉**：如果模型沿错误方向跑了好几轮，最忌讳"说服它改回来"——错误推理过程已污染上下文，再多解释只是叠 buff。Rewind 直接把那段分支从历史里删掉，相当于"假装没发生过"，比纠错干净得多。

更普适的原则：**长 stack trace、几千行日志这种噪声，不要原样塞回窗口；要么截断，要么先落盘再按需读**。上下文是稀缺资源，要像管显存一样管它。

---

**Q2：Harness 工程给你使用 AI 工具带来什么启示？**

提供两个可参考方向的回答：

**版本一（记忆管理视角）**

把 Agent 的记忆分成三层：上下文窗口、临时工作文件、持久记忆。使用心得：

1. **上下文窗口非常宝贵** — 模型窗口越来越大（最大 1M），但上下文增大时性能也会退化。不必等到上下文慢了再压缩，可在达 50% 时就主动压缩。
2. **临时工作文件层** — 让 Agent 存当前任务的中间产物（搜索结果、长日志），不放上下文中而是放在磁盘里——磁盘很便宜。Agent 通过搜索磁盘文件可处理很久之前的任务记录，同时不污染上下文。
3. **持久记忆常见的有 `AGENTS.md` 和 `Skill`** — 手动写 `AGENTS.md`，不要依赖 AI 生成。Skill 若重复操作超 3 次才值得建立，同时应建立测试集评估——模型升级或 Skill 过啰嗦也会影响 Agent 性能，定期检查是好习惯。

**版本二（`AGENTS.md` 管理视角）**

最大启示：**项目级知识要外化，但要克制**。

以前习惯把所有约定写在 README 里靠人脑记，现在用 `AGENTS.md` 把"项目特有的事实"喂给 Agent——构建命令、目录约定、踩过的坑。

但管理 `AGENTS.md` 有几条铁律（实证支撑来自论文 _Evaluating AGENTS.md — Are Repository-Level Context Files Helpful for Coding Agents?_（arXiv 2602.11988））：

作者在 AGENTBENCH 上对比"无 context file / LLM 自动生成 / 人类手写"三档，发现：
- LLM 自动生成的 `AGENTS.md` 让任务成功率下降 ~3%、token 消耗上升 ~20%；
- 人工手写也只有 +4% 提升。原因：context file 里每条额外要求都是约束，Agent 会认真履行但也分散注意力。

所以做法是：
1. 手写不自动生成 — 自动生成充斥废话，论文实验里直接成了负贡献；
2. 只写项目特有的事实 — 构建命令、测试命令、特定工具（如"用 uv 不用 pip"）这类 AI 猜不到的；"保持代码整洁"这类废话不要写；
3. 定期复盘删过时条目 — 模型升级后，老的"提醒"可能成为干扰；
4. 简洁第一，少即是多 — `AGENTS.md` 越长，注入 system prompt 的开销越大，且容易稀释关键信息。

> **Harness 不是越多上下文越好，而是信号-噪声比的工程**。

---

**Q3：使用 Skill 有什么心得？**

核心心得：**Skill 不是越多越好，滥用会反向降低性能**。

直觉上 Skill 是好东西——把可复用流程外化成 `prompt + 代码 + 参考资料`，让 Agent 像调工具一样用。Cursor 有过用 200 行 Skill 替掉 15000 行编排代码的例子。

但实际用下来两个坑：
1. **Skill 写多了反而干扰模型** — 如果 Skill 里写了很多模型本来就知道的常识，等于在 system prompt 里加噪声，`with skill` 比 `without skill` 还差。
2. **Skill 会过时** — 新模型原生支持多模态文件解析后，老的"教它怎么解析 PDF"的 Skill 就成了负担。

两条纪律：
- **判定标准**：同一类操作做过 3 次以上 + 步骤超过 5 步 + 通用模型容易做错 — 同时满足才值得做成 Skill。一次性的别做。
- **每个 Skill 必须配 eval**：准备小评测集，定期跑 `with skill vs without skill` 对照；模型升级后重跑，发现负贡献立刻下线。

> **Skill 是杠杆，但它也有成本；要用 eval 来证明它真的在帮你，而不是凭感觉攒一堆。**

---

### 2.4.3 Loops, Tool Use, and Feedback（循环、工具与反馈）

#### 背景

Agent 之所以比单次 LLM 调用强，核心是**循环 + 反馈**——给它时间思考、跑工具、看结果、再调整。从 o1 开始，模型不再是"一锤子买卖"，而是默认要在 Harness 里循环跑、反复 refine。

但"循环跑起来"只是第一步。真正决定循环质量的是**循环周围的配套**：
- 循环本身要够聪明（不能盲目重试）；
- 工具不能反过来污染循环（20000 行日志就能撑爆窗口）；
- 循环不能放任 Agent 写出越来越乱的结构；
- 循环出错时不能炸掉真机（API key、`~/.ssh` 直接暴露）。

本节从四块展开：**让循环更聪明 + 让工具 I/O 不污染循环 + 给循环加结构性约束 + 给循环加安全边界**。

> SWE-bench 论文留下的三条设计原则贯穿全节：**actions 简单紧凑**、**environmental feedback 信息量足且简洁**、**guardrails 抑制错误扩散且便于恢复**。

#### 基础知识

**循环范式（Loop Strategies）** — 让循环本身更聪明

循环不是一种东西，而是从"暴力重试"到"假设-验证"的谱系，越靠后越省 token、越快收敛：

1. **Ralph Wiggum loop（最朴素）**：失败就清空重来、什么也不学 → 极度耗 token。
   > 视频里举了用这种方式硬怼出一个 C compiler 的例子。但这种方式极度耗 token，且易陷入死循环。

2. **Plan-then-Execute**：先规划再执行，中途守住计划。大多数现代 Harness 默认就这么做。

3. **Hypothesis → Verification loop（Karpathy 的 auto-research 范式）**：假设 → 跑实验 → 看结果 → 反馈进下一轮 → 螺旋上升。这是当前性价比最高的循环形态。

4. **Test-Driven Development for Agents**：把测试当作循环的成功判决。
   > Factory 的提醒——务必先写测试再写代码，反过来会把已有 bug 也"橡皮图章"进测试。

#### 最佳实践建议

**1. 循环范式**

- **能用"假设-验证"loop 就别用 Ralph Wiggum**：明确让模型先说"我猜问题在 X，我要跑 Y 来验证"，再跑——比"失败重试 10 次"省 5–10× token。
- **任务 ≥ 3 步先要计划**：复杂任务用"先 plan、再 execute、每步对照 plan"；简单一步任务不要强加 plan，反而拖慢。
- **TDD 严格"先测试，后代码"**：让 Agent 先写测试并跑红，再写实现到绿；反过来会让测试成为已有 bug 的"橡皮图章"。

**2. 工具 I/O 卫生**

- **所有工具输出加截断**：默认保留尾部 2000 行 / 50KB；长 stack trace 只保留报错块；命令输出 > 5MB 强制落盘成文件再让 Agent 按需读。
- **错误反馈要"短而准"**：与其把整段 traceback 喂回去，不如让 Harness 抽取 `error type + 出错文件:行号 + 最近一帧 + 失败的测试名`。

**3. 结构性约束**

- **写死结构约束进 system prompt**：例如 `单文件 ≤ 200 行`、`函数 ≤ 50 行`、`新增依赖必须先问` — 强制 Agent 分解而非堆一个巨大 god file。
  > 这条对应 OpenAI 那句 _"developer → manager"_ — 你不再亲写每一行，而是给系统定规则。
- **新增依赖必须先问**：防止循环里悄悄引入一堆库。

**4. 安全护栏**

- **永远在 sandbox 跑陌生 Agent**：容器 / VM / devcontainer 三选一；宿主机上的 `~/.aws`、`~/.ssh`、浏览器 cookie 别暴露给 Agent。
- **三档权限白名单**：
  - ✅ **自动允许**：读文件、跑测试、`git diff`
  - ⚠️ **需要确认**：写文件、安装依赖
  - ❌ **强制人工**：`rm -rf`、`git push --force`、删分支、改共享配置

> 本质：**用 Harness 替你做"代码 review"的硬性那一半，让模型不会沿错误方向越跑越远**。

#### 面试问题

**Q：介绍一下你了解的 Harness 工程的最佳实践？**

Harness 工程概念很大——业界说法：**Agent = Model + Harness**，围绕模型展开的一切（检索、记忆、循环、编排、安全）都可归入 Harness。

从体感最深的角度切入：**Agent 的循环**。这是 Agent 区别于单次 LLM 调用的核心——给它时间反复跑工具、看反馈、再调整。

围绕"让循环跑得好"，从四个层面讲：

**第一，循环本身要够聪明**

循环范式有从弱到强的谱系：
- 最朴素：Ralph Wiggum loop（失败清空重来，极耗 token）
- 好一点：Plan-then-Execute（先规划再执行）
- 性价比最高：Hypothesis → Verification loop（先猜问题在 X，跑 Y 验证）
- 进阶：TDD for Agents（先写测试跑红，再实现到绿）— Factory 团队踩过的坑。

**第二，工具 I/O 不能反过来污染循环**

一条 20000 行日志就能撑爆窗口 → Harness 必须替 Agent 做三件事：
- **截断**：默认只留尾部 2000 行
- **抽帧**：长 stack trace 只留报错那几帧 + 失败测试名
- **落盘**：超大输出（>5MB）直接写文件，Agent 按需读

**第三，给循环加结构性约束**

OpenAI 反复强调："开发者正在变成 AI 系统的管理者"——写代码不是瓶颈，给系统定边界才是。
具体做法：把约束写死进 system prompt，例如 `单文件 ≤ 200 行`、`函数 ≤ 50 行`、`新增依赖必须先问`。
本质：用 Harness 替你做"代码 review"的硬性一半，防模型越错越远。

**第四，给循环加安全护栏**

宿主机敏感信息（API key、SSH、cookie）一旦泄露代价巨大 → 两道防线：
1. **Sandbox 隔离**：容器 / VM / devcontainer 三选一
2. **三档审批白名单**：
   - ✅ 自动：读/测试/git diff
   - ⚠️ 确认：写/装依赖
   - ❌ 强制人工：`rm -rf` / `git push --force` / 改共享配置

> **总结**：四层背后是 SWE-bench 论文留下的同一原则——**actions 简单紧凑、environmental feedback 信息足且简洁、guardrails 抑制错误扩散**。Harness 的精髓不在于模型多强，而在于你为循环配的这一圈基础设施有多稳。

---

### 2.4.4 Orchestration（单 Agent vs 多 Agent）

> 本节内容与笔记中"多 Agent"部分高度重合。博主明确否定了"parallel mode 是好模型"的说法——多 Agent 极难管理通信与协调，且社交媒体常见的"同时开 100 个 agent 改 100 个 bug"在真实工程中几乎必塌。

#### 背景

直觉上："上下文窗口不够大，就拆给多个 Agent 并行做"听起来很对。但 Raj 给出的**反直觉真相**：**多 Agent 不是默认更好——多 benchmark 平均下来，Single Agent 表现优于 Multi-Agent**。

原因：**协调税（coordination tax）** — Agent 之间需同步状态、互相理解输出、处理冲突——这一层开销往往吃掉并行收益。

真正有效的多 Agent 场景是**结构化的**：
- **Orchestrator-Worker**：一个主 Agent 派任务，若干 Worker 干活，最后汇总
- **明确可并行的子任务**：如对 50 个独立文件做格式化，子任务间零依赖
- **Reflection / Critic**：一个 Agent 写代码，另一个专门挑毛病（如 Opus 写 + GPT 审）— 主副用不同厂家模型互补

> Factory 实战结论也印证：**串行 Orchestrator → Worker → Validator 比并行 swarm 100 个 Agent 靠谱得多**

#### 最佳实践建议

- **默认就用 Single Agent**：除非能说清"为什么需要并行"或"需要一个独立 critic"，否则不要拆。
- **要并行先验证"子任务零依赖"**：能否用一句 `for f in files: agent(f)` 描述清楚？不能就意味着有隐式依赖，并行会出乱子。
- **Orchestrator-Worker 模式的硬要求**：
  - worker 之间不能直接通信，只通过 orchestrator 中转
  - 每个 worker 的输入输出必须是可序列化的明确契约（JSON / 文件路径），不要靠"共享内存"
- **强烈推荐 Reflection 模式**：主写 + 副审是 ROI 最高的多 Agent 用法；建议主副用不同厂家模型（如 Opus 写 + GPT 审）让盲区互补。
- **限制 Agent 数量**：一个 orchestration 内活跃 Agent ≤ 5；超过此数协调成本指数上升。
- **不要让多 Agent 完全 event-driven**：自由互相调用 = 死锁/无限循环高发；坚持有明确层级的调度。
- **Reflection 的输出要可执行**：让 critic 直接产出 `diff` 或 `patch`，而不是写"建议你考虑改进 X" — 后者 main Agent 不一定听得懂。

> **Single Agent + Reflection 是当前性价比最高的组合；其他多 Agent 形态都要有明确理由再上。**

---

### 2.4.5 面试真题

> 源自 2026/05 字节暑期实习真题，用于检验对 2.4 节的理解深度。重点不在背答案，而在**理解与灵活运用**。

**8-4：如果让你用 Harness 完成工程，你会怎么做？**

按当前定义：**Agent 除了模型以外的部分都叫 Harness**。假设用 Claude Code 完成项目，Harness 思路如下：

1. **从检索工具的角度**：CC 默认用 `grep`，但会根据任务动态调整——文件太大时建 BM25 索引；搜索精度低时启用 Agentic RAG 或 embedding；避免让模型硬扛外部信息获取。

2. **建立明确的验证机制**：Agent 本身验证代码是否完成是主观的 → 定义测试标准与指标，让 Agent 跑这些工具完成"生成-检测-反馈"循环，保证代码质量。

3. **让 Agent 只做一件事，并保持上下文简短**：参考 OpenAI Harness 工程：每个 Agent 专注一个任务，做完就销毁；用新 Agent 接手后续工作，避免上下文膨胀导致性能退化。

> 其他角度（如 `AGENTS.md` 组织、安全隔离等）已在前文覆盖。

---

**8-5：对 Claude Code 的了解？哪些框架真正给你带来便利？**

CC 的便利性可从多维度谈：
- **记忆功能**：`rewind` / `compact` 让人能主动管理上下文，而非赌模型自己压缩；
- **架构方面**：`AGENTS.md` + `Skills` 体系把项目特有知识外化，且可控；
- **最佳实践**：主动管理上下文、用 Skill 封装高频操作、定期清理过时条目。

具体可结合本文内容展开：
- `rewind`：直接砍掉错误分支，比解释干净得多；
- `compact` 的参数化：指定保留"架构决策+待办事项"，比黑盒压缩可靠；
- `Skill` 的 eval 机制：必须配对照实验，避免负优化。

---

**8-6：这些内容怎么迁移？**

2.4 节所有内容都在讲 **Harness 工程的应用**，即"如何把 Harness 工程迁移到实际工作中"。各节的原则就是 Harness 工程迁移的最佳实践，均可直接用于回答。

### 2.4.6 参考视频

> [Raj - Engineering Coding Harnesses Deep Dive](https://www.youtube.com/watch?v=KijChx7q2nY&t=224s)

---

## 2.5 Anthropic Harness 架构详解

Anthropic 的 Harness 是目前业内被最广泛引用的长时任务管控架构范例。

### 2.5.1 设计哲学

- 核心理念：与其让一个天才持续工作到崩溃，不如让无数个"新手"接力完成，每人只干一件事。
- 传统做法：把一个强大模型（如 Claude Opus 4.6）扔进去从头干到尾 → 但无论模型多强，单一上下文终将被垃圾数据淹没，导致上下文腐化、失忆与幻觉。
- Anthropic 方案彻底绕开这个问题：**每个 Agent 只活一次，干完就死**。

### 2.5.2 总体结构

1. **App Spec / PRD：项目起点**
   Harness 通常从一份由人提供的需求说明开始。这份说明不是直接交给模型编码，而是作为整个系统初始化的输入，用于定义产品目标、功能范围与预期结果。
   → 项目进入系统的第一步不是"代码任务"，而是一份高层次目标描述。

2. **Initializer：初始化规划 Agent**
   职责不是产出业务代码，而是将需求文档转化为可执行的工程结构：
   - 读取需求，拆解出特性清单
   - 建立任务边界与验证标准
   - 完成项目骨架与代码仓库初始化
   → 把模糊产品目标整理成可持续推进、可被后续 Agent 反复读取执行的蓝图。

3. **Coding Loop：编码循环 Agent**
   系统进入执行阶段后，**不断启动新的 coding agent**，逐轮接力：
   - 每一轮 Agent 先读取当前任务状态与进度
   - 只选择一个明确的小任务去实现
   - 完成后退出，不长期驻留系统
   - 下一轮由全新 Agent 接手
   → 通过循环式接力而非持续长对话，避免上下文膨胀。

4. **External Memory：外部记忆系统**
   将项目状态从模型内部记忆中剥离，放入外部可持久化介质：
   - 特性清单（Feature List）
   - 进度文件（Progress Log）
   - Git 历史
   → 新 Agent 启动时只需重新读取这些状态即可接手，保障系统持续推进能力。

5. **Deterministic Validation：确定性验证机制**
   不把"是否完成"交给模型主观判断，而是通过外部确定性验证机制裁定结果：
   - 测试运行
   - 静态检查（Lint）
   - 人工审核点
   → 只有满足外部标准才更新状态并进入下一轮。**用工程规则替代模型"感觉完成了"**。

6. **Sandbox / Isolation：隔离执行环境**
   每个 Agent 运行于受控环境，限制可访问的工具范围，防止错误污染全局：
   - 隔离环境确保每轮执行都在明确边界内
   - 失败后的回滚、重试、重启变得可控
   → 把 Agent 的自由度压缩在足够安全、清晰的工作空间里。

![Anthropic Harness 架构图](https://img.vectorpeak.cn/obsidian/2026/05-06/20260526115926541.png?imageSlim)

### 2.5.3 局限性

> Anthropic 的 Harness 架构核心可概括为一种 **"初始化拆解 + 外部状态持久化 + 单任务循环执行 + 确定性验证门控"** 的长时任务运行体系。
>
> 关键不在于让单个大模型持续工作，而在于：
> - 先由 **Initializer** 将需求拆解为可执行的特性清单；
> - 再让一个个全新的 **Coding Agent** 逐轮读取状态文件与代码库，只完成一个原子任务；
> - 并通过**测试、提交与交接文件**立即更新系统状态后退出。
>
> 本质是**把项目记忆从模型内部迁移到外部系统**，把任务完成判断从模型主观输出转移到确定性验证机制，显著降低上下文腐化、幻觉完成和多步任务失控的风险。

**局限性**（注意：Harness Engineering 仍处于早期发展阶段，2026年3月本文写作时）：

- **Initializer 是单点高杠杆环节**：若初始拆分出错，后续全部跟着错——蓝图质量决定系统上限。
- **Handoff 质量不稳定**：进度文件有时总结得好，有时漏掉关键问题。一旦漏掉"为什么失败、怎么修复"，后面的 Agent 可能反复踩同一个坑。
- **多步可靠性仍会衰减**：即使单步成功率很高，步骤一多整体可靠性还是会下降。Harness 不是彻底解决了可靠性问题，而是显著缓解。
- **仍然需要 Human in the Loop**：Anthropic Harness 更像高度自动化但非完全放手——关键节点仍需人工检查。

---

## 2.6 ClawCode Harness 工程详解

Claude Code 泄漏发生后，韩国开发者 Sigrid Jin 发起了 **Claw Code 项目** — 用 AI 编排工具指挥多个 coding agent 并行工作，在 **3 天内**将 Claude Code 的核心功能从 TypeScript 重写为 Rust（48,599 行），产生 292 个 commit。人类几乎不写代码，只负责方向决策和任务分解。

该项目破了 GitHub 涨速最快记录，完整展示了一套使用 Harness 工程进行 Vibe Coding 的技巧——即：如何用 AI 工厂模式完成大规模代码迁移。

> 本节价值：无需深入源码即可快速掌握思路；且提供代码仓库地址，可供复现与动手实践。

### 2.6.1 整体方法论：五阶段流水线

核心思路：**先把"什么需要被实现"变成机器可查的清单，再边实现边用 mock Harness 自动验证行为对等性**。

| 阶段 | 内容 |
|---|---|
| **1** | 归档 + 快照 → 把原始 TS 代码表面提取为结构化 JSON（建立"真相基线"） |
| **2** | Python 镜像工作区 → 1:1 结构占位 + 架构模型（理解原始系统） |
| **3** | Parity Tracking → 量化覆盖率，进度可测量、可审计 |
| **4** | Mock Parity Harness → 确定性端到端测试，行为可验证 |
| **5** | 多 Agent 并行执行 → Discord 指挥 + clawhip/OmX/OmO 协调 |

> **1–4 阶段是准备，5 阶段才是真正的 coding。**

### 2.6.2 五个阶段详解

#### 归档 + 快照原始代码表面

把整个项目做一次拆解，将 Claude Code 代码变成可量化的文字——有多少工具、多少文件、多少 Commands。

Claude Code 的代码组织非常规整：
- 所有命令集中注册在 `src/commands.ts`
- 所有工具集中注册在 `src/tools.ts`
- 启动流程定义在 `src/entrypoints/cli.ts`
- 每个命令/工具都是一行标准的 `import` 语句

→ 格式统一，用逐行字符串匹配就能提取所有名字和路径，**不需要 AI 介入**。

具体做了三件事：

1. **获取原始 TypeScript 源码快照** — 存放在 `archive/claud_code_ts_snapshot/src`（`.gitignore` 里忽略，不公开上传），作为本地参考基准。

2. **`compat-harness` 自动提取清单** — 仓库中的 `rust/crates/compat-harness` 专门解析上游 TS 源码：
   - 扫描 `commands.ts` → 提取 207 个斜杠命令
   - 扫描 `tools.ts` → 提取 184 个工具模块
   - 扫描 `cli.tsx` → 提取启动流程的 7 个阶段
   → 这是"活"的提取器——上游 TS 代码更新时可重新运行，自动刷新清单。

3. **生成结构化快照 JSON** — 提取结果固化为四组 JSON 文件，存放在 `src/reference_data/`：
   - `archive_surface_snapshot.json`：原始仓库整体结构（18 个根文件、35 个子目录、1,902 个 TS 文件）
   - `commands_snapshot.json`：所有命令的 `name + source_hint + responsibility`（207 条）
   - `tools_snapshot.json`：所有工具模块的 `name + source_hint + responsibility`（184 条）
   - `subsystems/*.json`（29 个文件）：各子系统的模块数和样本文件名

这些清单的用途：
- 量化 scope（207 命令 + 184 工具 → 估算工作量）
- 定位参考代码（AI 收到工单时知道去哪个文件读原始逻辑）
- 覆盖率审计（BashTool 显示 18 个子模块最复杂）

> ⚠️ 局限性：字符串匹配**只适用于代码结构规整的项目**；若用动态注册或插件扫描，则此法不通。

---

#### Python 镜像工作区

这一步是建索引——上面把 Claude Code 拆解成 JSON，现在把它变成一个 **Python 骨架**。骨架代码没实现，但 AI 可以很快看出目录、知道如何启动、整个流程是什么。相当于给了 AI 一个空壳，通过空壳可快速了解项目结构与启动流程。

不直接从 TS 翻译 Rust → 直接翻译等于盲写，效率低且易遗漏。原始 TS 有 1,902 个文件、51 万行代码；AI Agent 若需在内部翻找架构信息，极易遗漏关键逻辑。

Claw Code 先建了一个 **Python 中间层** — 只有 67 个文件的轻量"沙盘模型"，让 AI Agent 后续 Rust 重写时可先查这个中间层快速定位，而不需要大海捞针。

Python 中间层包含四样东西：

1. **1:1 结构映射表** — `src/parity_audit.py` 定义了 TS → Python 的完整映射关系：18 个根文件和 35 个子目录全部有对应的 Python 占位文件。作用：让任何人（或 Agent）一眼看清原始系统有哪些组成部分，每个部分对应到 Python 层的哪个文件。

2. **占位包（29 个子目录的结构索引）** — 29 个子目录各有一个 `__init__.py`，但不实现业务逻辑。
   - 每个占位包只做一件事：从 JSON 加载该子系统的元数据，导出 `MODULE_COUNT`（模块数）和 `SAMPLE_FILES`（包含哪些文件）
   - 当 AI Agent 收到"实现 assistant 模块"工单时，读一下占位包就知道原始系统有 1 个模块、文件叫 `sessionHistory.ts`，然后直接去对应的 TS 源码中精准阅读

3. **关键架构模型（5 个 Python 文件复现核心决策逻辑）** — 把原始系统最关键的几条逻辑管线提取出来，编码为可运行的 Python 代码：
   - `bootstrap_graph.py`：启动流程的 7 个阶段
   - `command_graph.py`：把 207 个命令分类为 builtins (185)、plugin-like (20)、skill-like (2)
   - `query_engine.py`：复现查询引擎的 turn-loop 行为 — 轮次限制、token 预算执行、消息压缩触发。这里有真实的状态管理逻辑，不是 stub。
   - `setup.py`：建模 workspace 环境发现和启动 preflight 流程
   - `runtime.py`：建模运行时路由 — 把用户 prompt 分词、和所有命令/工具名字做匹配打分、返回 top-N 结果。这也是真实的匹配算法

4. **可运行的审核 CLI** — `python -m src.main`（40+ 个子命令），供人类和 AI Agent 随时验证中间层的自洽性：
   - `summary`：输出工作区摘要
   - `parity-audit`：对比覆盖率
   - `route <prompt>`：验证路由逻辑是否与预期一致
   - `bootstrap <prompt>`：跑通完整的启动→路由→执行→历史记录流程
   > 该 CLI 同时也是 Rust 重写的**行为基准**：Rust 版的路由结果应与 Python 版匹配，不匹配说明实现有偏差。

---

#### 量化重写进度

进度表。定义了文件覆盖率、目录覆盖率、目标覆盖率、命令覆盖率。同时将整个项目开发分成 **9 个可并行的模块**，这些设计需要对 Claude Code 项目本身有一定理解。`Parity.md` 就是进度表。

**核心思想**：把"重写进度"从感觉变成**机器可检查的量化指标**。通过三样东西实现：

1. **自动审计脚本**：`parity_audit.py` 中的 `run_parity_audit()`
   - 自动扫描当前代码库，计算四个维度的覆盖率：
     - 根文件覆盖率（18 个中实现了多少）
     - 目录覆盖率（35 个中覆盖了多少）
     - 命令覆盖率（207 个中实现了多少）
     - 工具覆盖率（184 个中实现了多少）
   - 测试中有断言确保覆盖率只升不降——写了新模块后不允许退化。

2. **PARITY.md 双层清单**
   - **顶层 `PARITY.md`**：记录 9 条开发 lane 的宏观状态 — 每 lane 的 feature commit hash、merge commit hash、diff 行数统计，全程可追溯。
   - **`rust/PARITY.md`**：更细粒度，对 40 个工具逐个标注实现深度，分四档：
     - `strong parity`：行为完全对齐
     - `good parity`：核心路径对齐
     - `moderate parity`：基本可用
     - `stub`：仅占位

---

#### 定性行为验证

不同厂商的 Harness 工程有差异，但对"确定性验证"这一点是统一的。**不要让 AI 判断是否完成，而是给出量化标准 + 脚本**。

解法：建一套确定性的端到端测试体系。

不靠"编译通过就算对"，也不靠每次测试都调真实 Anthropic API（贵、慢、结果不确定）。而是构建一个 **mock Anthropic 服务**：
- `rust/crates/mock-anthropic-service` 是独立 Rust crate
- 实现了 Anthropic 兼容的 `/v1/messages` 端点
- 不调真实模型，返回预编排的 SSE 流式响应，每次运行结果完全相同
- CLI 通过设置 `ANTHROPIC_BASE_URL` 指向本地服务，即可在完全离线、零成本环境下跑端到端测试

**10 个场景脚本**

`mock_parity_scenarios.json` 定义了 10 个测试场景，覆盖核心工具链路、权限拒绝、多工具同轮、插件路径等关键行为。每个场景通过 `parity_refs` 字段指向 `PARITY.md` 中的具体条目，确保测试与文档一一对应：

| 场景名 | 类型 | 说明 |
|---|---|---|
| `streaming_text` | baseline | 纯文本流式响应，无工具调用 |
| `read_file_roundtrip` | file-tools | 文件读取往返 |
| `grep_chunk_assembly` | file-tools | grep 分块 JSON 组装 |
| `write_file_allowed` | file-tools | workspace-write 模式下写入成功 |
| `write_file_denied` | permissions | read-only 模式下写入被拒 |
| `multi_tool_turn_roundtrip` | multi-tool | 同一 turn 内执行多个工具 |
| `bash_stdout_roundtrip` | bash | bash 执行和 stdout 往返 |
| `bash_permission_prompt_approved` | permissions | bash 权限提示 → 批准 |
| `bash_permission_prompt_denied` | permissions | bash 权限提示 → 拒绝 |
| `plugin_tool_roundtrip` | plugin | 加载外部插件工具并执行 |

> 关键设计：`run_mock_parity_diff.py` 做两件事：
> 1. 遍历每个场景脚本的 `parity_refs`，确认每条引用在 `PARITY.md` 中确实存在（找不到就报错）；
> 2. 再运行 `cargo test` 输出每个场景的通过状态。
> **`PARITY.md` 不只是给人看的文档——它是场景清单的锚点；文档改了但测试没更新，或测试加了但文档没跟进，都会被检测到**。

---

#### 多 Agent 协作执行

这一步才是真正的执行。执行有技巧——Claw Code 是并行的，多个 Agent，甚至专门写了 3 个工具负责 Agent 调度、执行、监控。

Anthropic 的 Harness 项目也用了多 Agent。自己做 Harness 时，参考多 Agent 的调度、监测、执行方式，面试时也会显得更深入。

如 `PHILOSOPHY.md` 所述，项目核心哲学：**人类提供方向，claws（AI agent）执行劳动**。前四个阶段建好了清单、中间层、进度条和测试题，第五阶段让多个 AI agent 并行干活，人类只在关键节点介入。

项目作者编写了三个专用编排工具（为这套 Vibe Coding 工作流定制）：

| 工具 | 名称与职责 | 仓库地址 |
|---|---|---|
| **OmX** (`oh-my-codex`) | **任务拆解器**：把指令转化为结构化工单，定义子任务、执行模式和验证标准 | [GitHub](https://github.com/Yeachan-Heo/oh-my-codex) |
| **clawhip** | **后台监控员**：监听 git commits、CI 结果、PR 状态、Agent 生命周期事件，在 Agent 上下文窗口之外独立运行，只推送通知不干扰执行 | [GitHub](https://github.com/Yeachan-Heo/clawhip) |
| **OmO** (`oh-my-openagent`) | **角色协调员**：管理 Architect / Executor / Reviewer 之间的分工和分歧解决，确保多 Agent 循环收敛而非无限争吵 | [GitHub](https://github.com/code-yeongyu/oh-my-openagent) |

> 三者协同，实现"人类发指令 → OmX 拆任务 → OmO 分配角色 → Agent 执行 → clawhip 监控 → 人类仅在失败/merge 时介入"的闭环。

---

#### 完整工作流

有了三个工具加上前四个阶段建好的清单和测试，实现 **"人类发指令、Agent 自主干活"** 的工作流：

1. 人类输入一句高层指令（通过 Vibe Coding 工具），例如："实现 Lane 3：给 file tool 加边界检查"
2. OmX 自动拆解成子任务：二进制检测、大小限制、路径穿越防护，确定执行模式（并行/串行）和验证标准
3. OmO 分配角色并启动 Agent：Architect 规划方案、Executor 写代码、Reviewer 审查质量 → 多组 Agent 在服务器上并行工作
4. Agent 自主循环：写代码 → 跑测试 → 失败 → 读错误 → 改代码 → 再跑测试；Reviewer 不满意就打回重做，OmO 协调分歧直到收敛
5. clawhip 在后台监控所有事件：lane.started、lane.commit.created、lane.red、lane.green、lane.pr.opened、lane.finished → 向人类推送状态通知，但**不打扰正在干活的 Agent 的上下文窗口**
6. 人类只在两种情况介入：Agent 自己恢复不了的失败（决定重试还是换方案）、lane 完成后判断能否 merge

---

#### 设计原则

核心是四条设计原则：

1. **人定标准，AI 执行** — 所有判断标准由人预先制定——覆盖率数字、parity 标签体系、mock 场景清单。AI Agent 不需要自己判断"够不够好"，只需对照验收标准逐项打勾。

2. **建中间层，降低 AI 认知成本** — 51 万行 TS 太大，AI 无法每次从头阅读。用 JSON 索引 + Python 骨架建轻量参考层，让 Agent 查一下就能定位和理解，而不需要大海捞针。

3. **用工具编排多 Agent，而非人工协调** — Python 脚本生成"做什么"（清单），OmX/clawhip/OmO 三件套负责"谁来做、怎么分发、怎么验收"。人类不需要坐在终端前逐个分配任务。

4. **人只做方向、分解、判断** — 基于架构理解把工作拆成 9 条独立 lane，定义 lane 边界和合入标准。292 个 commit 中人的贡献集中在：重写什么（方向）、怎么拆（分解）、何时 merge（判断）。剩下的全是 Agent 的事。

### 2.6.3 项目地址

项目本身是很好的学习 Harness 技巧的项目：
- 学习 Harness 设计方法
- 复现一个 Claude Code 的 Agent
- 在自己项目中设计 Harness 工程

> 项目仓库：[https://github.com/seavee/ClawCode](https://github.com/seavee/ClawCode)

### 2.6.4 讲解视频

- Bilibili 讲解视频：[BV1CqQcBqEBU](https://www.bilibili.com/video/BV1CqQcBqEBU/?vd_source=144bec9c3f54e465073138bed788be1b)

---

## 2.7 面试问题速览

> 本节提炼面试可直接使用的回答模板。

### 2.7.1 什么是 Harness Engineering？

Harness Engineering 是围绕 AI 模型构建**运行环境、调度机制和管控基础设施**的工程实践。目标不是让模型"更聪明"，而是让 AI Agent 在**长时、复杂、多步骤的真实任务中**稳定、可靠、可控地持续运行。

通俗说：**不再把 AI 当成一次性问答黑盒**，而是把它放进一个被设计好的工作系统里，让它按规则做事。

背后设计哲学：**模型只是原材料，环境才决定结果能否落地**。再强的模型裸跑长任务，也会遇到上下文腐化、失忆、幻觉完成、任务漂移等问题。Harness Engineering 的核心是通过**外部记忆、任务拆解、测试门禁、状态交接和人工审核**，把 AI 的执行过程工程化。

---

### 2.7.2 Harness Engineering 想解决的核心问题是什么？

主要解决 **AI 在长时任务里的可靠性问题**，三大症结：

1. **Context Rot（上下文腐化）** — 模型做长任务时，上下文窗口被历史对话、错误尝试、无关信息填满，最终丧失对原始目标的把握。

2. **Hallucinated Completion（幻觉完成）** — 模型迷失后不会老实说"我不会了"，而是输出看起来完成但实际不正确的结果。

3. **Model Drift（模型漂移）** — 多步执行中模型逐渐偏离最初目标，方向歪了。

> Harness Engineering 的价值不是让模型在单轮回答里更强，而是让它在**几十步、几百步的连续工作流里**依然能沿正确轨道走。

---

### 2.7.3 Harness Engineering 和 Prompt Engineering、Context Engineering 的关系？

是一个**演进关系**，而非替代关系：

- **Prompt Engineering** — 解决"对 AI 说什么"，即如何设计指令让单次输出更好。
- **Context Engineering** — 解决"让 AI 知道什么"，即在 session 或上下文窗口里给它什么信息、怎么组织。
- **Harness Engineering** — 解决"让 AI 在什么环境里做事"，即构建包含记忆、工具、循环、验证、人工干预的完整运行系统。

Harness 并没有取代前两者，而是把它们包进更大的系统里：Harness 内部的每个 session 仍需 Context Engineering，每次给 Agent 的任务描述仍需 Prompt Engineering。只是关注点从"优化一次对话"升级成了"设计一整套运行体系"。

---

### 2.7.4 Harness Engineering 的最佳实践是什么？

7 条关键实践原则：

1. **状态外部化** — 不要把连续性寄托在模型记忆里，把状态写进文件、Git 或数据库，让系统自身有记忆。
2. **任务原子化** — 不要让一个 Agent 一口气做大需求，拆成足够小、足够明确的原子任务，每次只做一件事。
3. **上下文刷新** — 小任务完成后销毁当前 Agent，启动全新 Agent 接手——从根本上避免上下文腐化。
4. **验证优先** — AI 的输出必须经过测试和规则检查，而非靠自我声明"完成了"。这是把主观判断变成工程确定性的关键。
5. **按需暴露工具和技能** — 不要一次性给模型上百个工具，通过 skills、toolkits 或 task routing 让它按需调用。
6. **在关键节点加入 Human-in-the-loop** — 尤其是高价值任务或多步流程中，人工审核断点不是系统失败的表现，而是提高整体可靠性的工程设计。
7. **保持轻量、模块化、与模型无关** — 模型变化很快，好的 Harness 应能在尽量少改动的情况下替换模型、替换技能、替换验证逻辑。

---

### 2.7.5 如果让你用 Harness 工程来实现一个项目，你怎么设计？

我会从一个 **Initializer + Coding Loop 的最小闭环**开始，而非一上来就做复杂的多 Agent 平台。

**第一步：准备一份清晰的 App Spec / PRD**
把产品目标、功能范围、验收标准定义清楚。在 Anthropic 架构里，系统起点不是"代码任务"，而是"可执行的任务蓝图"。

**第二步：实现一个 Initializer Agent**
职责不是写业务代码，而是：
- 读取需求文档
- 拆解出 feature list（类似 `feature_list.json`）
- 定义每个 feature 的验证标准
- 初始化项目骨架与代码仓库
→ 系统就有了"任务清单"和"状态来源"。

**第三步：实现一个 Coding Loop**
每一轮启动全新 coding agent：
- 只读取当前状态文件 + 代码库
- 只完成一个明确的小任务
- 完成后必须通过测试、提交代码、更新状态文件才能退出
- 下一轮由新 Agent 接手
→ 避免上下文膨胀，保障可持续性。

**第四步：把外部记忆做成系统核心**
依赖 `feature_list.json`、`progress.md`、`Git log` 等外部状态，而非 session memory。让每个新 Agent 启动时都能快速接手。

**第五步：在关键节点加入 Human-in-the-loop**
Initializer 输出有歧义时、某 lane 多次失败时、merge 前，由人工确认。

> 重点不是"怎么让一个模型做完所有事"，而是：**先拆解、再循环执行、靠外部状态保持连续性、用确定性验证保证质量**。

---

### 2.7.6 你看过哪些 Harness 工程的实际案例？

两个典型案例，一个从零启动新项目，一个重写已有大型系统——刚好互补。

**案例一：Anthropic 官方 Harness 架构**

- 核心思路：**"每个 Agent 只活一次，干完就死"**
- 流程：Initializer 读文档 → 拆 feature list + 验收标准 → Coding Loop → 每轮新 Agent 读状态+代码 → 完成原子任务 → 测试通过 → 更新状态 → 退出
- 核心 insight：**用"短命 Agent 接力"代替"长命 Agent 硬撑"**，从根本上避免上下文腐化。

**案例二：Claw Code 项目（2026年3月，Claude Code 泄露后）**

- 背景：3 天内将 48,599 行 TS 重写为 Rust，292 个 commit，人类几乎不写代码
- 与 Anthropic 最大区别：**不是从零新建，而是重写已有 51 万行系统**
- 关键创新：
  - 先建 **Python 中间层**（67 文件沙盘）降低 AI 认知成本
  - 用 **JSON 清单 + Parity.md** 量化进度与覆盖
  - 用 **mock API + cargo test** 实现确定性端到端验证
  - 用 **OmX/clawhip/OmO** 三工具实现多 Agent 协作调度
- 核心 insight：**"建中间层降低认知成本"应对已有代码库的复杂性**

**对比**：
- 两者底层原则一致：**状态外部化、任务原子化、确定性验证、人只做关键决策**
- Anthropic 方案更适合**从零开始的新项目**，核心 insight 是 _"Agent 用完即销"避免上下文腐化_；
- Claw Code 更适合**代码迁移和重写场景**，核心 insight 是 _"建中间层降低 Agent 认知成本"应对已有代码库的复杂性_。

---

## 参考资料

- [Anthropic: Engineering Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
