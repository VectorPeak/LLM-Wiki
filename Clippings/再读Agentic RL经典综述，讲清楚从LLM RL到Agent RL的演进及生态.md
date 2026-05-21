---
title: "再读Agentic RL经典综述，讲清楚从LLM RL到Agent RL的演进及生态"
source: "https://mp.weixin.qq.com/s/rJBNzqtsQXK-_XljgeWxOw"
author:
  - "[[欠阿贝尔两块钱]]"
published:
created: 2026-05-16
description:
tags:
  - "clippings"
---
欠阿贝尔两块钱 *2026年4月27日 22:00*

该综述去年发布，梳理了大语言模型（LLM）+ 智能体（Agent）+ 强化学习（RL）交叉领域的全景综述。文章整合了全球 500+ 项最新研究，今年4月又增加了不少新的工作。

## 一、背景

- 传统 LLM-RL（RLHF/DPO 等）把大模型当作静态、单步、被动的文本生成器， **重点优化输出是否符合偏好，用来对齐用** 。
- Agentic RL 把大模型当作动态、连续自主的决策智能体，用强化学习优化 **完整交互与决策能力**
![全文结构](https://mmbiz.qpic.cn/sz_mmbiz_png/j2RPloCW20qlPANRTM9t3w5D2ChbTGzeQesao4BVZ2P2HDF3C3uD8Q0nda7f1aex6Lgur68SWxuRXbraLlx1Wqvyy72RzYEjPyVOMoZmKNQ/640?wx_fmt=png&from=appmsg&watermark=1&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=0)

全文结构

## 二、 从 LLM RL 到 Agentic RL 范式演进

综述在理论上的最大贡献，是将大模型对齐的底层数学模型，从 **马尔可夫决策过程（MDP）** 演进至\*\*时序扩展的部分可观测马尔可夫决策过程（POMDP）。从而来说明LLM RL到Agentic RL的演进过程。

![从 LLM RL 到 Agentic RL 的范式转变。扇形设计体现了 RL 表述的向外扩展——从传统 RL（内层），到 LLM RL，再到完整的 Agentic RL（外层）。颜色编码区域表示：红色 = LLM RL 特有功能；蓝绿色 = AgenticRL 所需功能；紫色 = 现有 Agentic RL 实现。箭头向外指，表示在迈向更具智能体特性的设置时，交互广度（工具使用、网页浏览、动态环境）不断增加](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

从 LLM RL 到 Agentic RL 的范式转变。扇形设计体现了 RL 表述的向外扩展——从传统 RL（内层），到 LLM RL，再到完整的 Agentic RL（外层）。颜色编码区域表示：红色 = LLM RL 特有功能；蓝绿色 = AgenticRL 所需功能；紫色 = 现有 Agentic RL 实现。箭头向外指，表示在迈向更具智能体特性的设置时，交互广度（工具使用、网页浏览、动态环境）不断增加

### 2.1传统偏好强化学习（PBRFT / RLHF）：单步MDP范式

传统RLHF可以建模为一个 **单步马尔可夫决策过程（Single-step MDP）** ，其形式定义为：

- **状态空间** ：仅包含由用户初始提示（prompt）定义的单一静态状态 ，整个交互过程中状态不发生变化。
- **动作空间** ：模型的唯一动作是生成一段完整的文本序列。
- **转移动态** ：模型生成回应后，交互过程立即终止，时间跨度固定为 ，属于典型的单步决策问题。
- **奖励函数** ：奖励 是对整段生成文本的一次性标量评估，通常由预先训练好的奖励模型给出，仅在对话结束时提供一次反馈。
- **学习目标** ：优化目标为最大化单步期望奖励：

> PBRFT的逻辑就像做一道“一次性选择题”：给定题干（prompt）， **模型直接输出完整答案（生成文本），随后获得一个最终分数（reward），整个过程只有一步决策** 。

### 2.2智能体强化学习（Agentic RL）：长程POMDP范式

Agentic RL的场景复杂度显著提升，需建模为 **部分可观测马尔可夫决策过程（POMDP）** ，其形式定义为：

- **状态空间** 与观测模型 ：环境状态 随交互动态演化，且智能体无法直接观测完整状态，只能通过观测模型获取部分信息 ，属于典型的“部分可观测”场景。
- **动作空间** ：采用混合式动作空间，覆盖文本与工具交互两类行为：
- ：生成自然语言文本，用于推理、表达与交互；
	- ：执行结构化动作，如调用API、使用工具、与虚拟/物理环境交互。
- **转移动态** ：环境根据智能体的动作随机转移到下一状态 ，时间跨度 ，支持多步长时序交互。
- **奖励函数** ：采用分层奖励设计，既包含任务完成时的稀疏终局奖励，也包含基于中间步骤进度的稠密反馈奖励，解决长程任务的信用分配难题。
- **学习目标** ：优化目标为最大化长程折扣累积奖励，引导模型兼顾短期行为有效性与长期任务目标：

### 2.3传统 PBRFT（RLHF/DPO）和Agentic RL详细对比

| 维度 | 传统 PBRFT（RLHF/DPO） | Agentic RL |
| --- | --- | --- |
| 决策过程 | 退化单步 MDP | 时序扩展 POMDP |
| 观测 | 完全可观测 | 部分可观测 |
| 动作 | 仅文本生成 | 文本 + 工具 / 环境操作 |
| 奖励 | 单步最终奖励 | 稠密步骤奖励 + 最终奖励 |
| 优化目标 |  |  |
| 定位 | 被动生成文本 | 自主决策智能体 |

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

## 三、 主流算法体系

为实现上述 POMDP 目标的求解，当前 Agentic RL 演化出三大主流算法谱系：

### 1\. PPO 系列

- **机制** ：通过 Actor-Critic 架构进行在线策略梯度更新，是目前最通用的对齐算法（衍生如 VinePPO, LitePPO）。
- **目标函数** ：其中优势函数 。

### 2\. DPO 系列

- **机制** ：将强化学习问题转化为监督学习中的分类问题，无需训练独立的奖励模型（RM），简单高效（衍生如 SimPO, IPO, Step-DPO）。
- **目标函数** ：

### 3\. GRPO 系列

- **机制** ： **放弃了传统 PPO 中与 Actor 同等规模的 Critic（价值网络）** 。针对同一个输入 Prompt（问题 ），模型一次性采样 个不同的输出轨迹（组），通过计算这组轨迹的相对得分来更新策略。 **极大地节省了显存（少加载一个千亿参数模型），是当前大模型 RL（如 DeepSeek-R1）的绝对主流** 。
- **目标函数** ： GRPO 的目标是最大化以下目标函数
1. **组采样（Group Sampling）** ： 表示对于同一个问题 ，旧策略 生成了 个不同的回答（例如 或 ）。
	2. **重要性采样比（Ratio）** ：，用于评估新旧策略的差异。
	3. **组内相对优势（Group Advantage）** ：。不需要价值网络来预测，直接用这 个回答的真实奖励（Reward）进行标准化：\*(得分高于组内平均值的轨迹，优势为正，鼓励生成；低于平均的为负，抑制生成)\*。
	4. **PPO 截断机制（Clipping）** ： 继承自 PPO，防止单次参数更新步子迈得太大，导致模型崩溃。
	5. **KL 散度惩罚（KL Penalty）** ：。强制当前训练的模型 不要偏离初始参考模型 太远，防止模型为了刷高分而输出乱码（Reward Hacking）。
![PPO、DPO 与 GRPO 系列主流变体的对比。Clip 指将策略比值限制在 1 附近，防止其变动过大，从而保证更新稳定；KLpenalty 指对学习策略与参考策略之间的 KL 散度施加惩罚，以确保对齐](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

PPO、DPO 与 GRPO 系列主流变体的对比。Clip 指将策略比值限制在 1 附近，防止其变动过大，从而保证更新稳定；KLpenalty 指对学习策略与参考策略之间的 KL 散度施加惩罚，以确保对齐

## 四、RL 赋能的六大智能体能力

### LLM Agent–环境交互与 RL 循环

![面向智能体 LLM 的智能体–环境交互与 RL 循环。核心智能体能力驱动动作生成，环境提供反馈与奖励，这些通过基于 RL
的优化在多样化任务域中聚合（“Collab.”表示需要显式任务划分与多智能体协调的任务）](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

面向智能体 LLM 的智能体–环境交互与 RL 循环。核心智能体能力驱动动作生成，环境提供反馈与奖励，这些通过基于 RL 的优化在多样化任务域中聚合（“Collab.”表示需要显式任务划分与多智能体协调的任务）

### 1.规划（Planning）

规划是智能体为达成长期目标，对未来动作、推理步骤、工具调用序列进行预结构化与序贯决策的能力，是智能体从“被动响应”走向“主动控制”的核心标志。

#### 强化学习的核心作用

RL 将规划从 **固定提示、静态分解、无反馈** 升级为 **可学习、可自适应、可随环境优化的策略** ，解决传统方法无法适应动态环境、无法从失败中修正规划的问题。

#### 两大范式

**（1）RL 作为外部引导（External Guide）**

- 机制：不直接微调LLM参数，而是训练 **价值网络/启发式函数** ，指导MCTS等搜索算法选择高价值规划路径。

> 核心逻辑：LLM负责生成候选动作，RL负责评估与引导搜索。

- 典型工作：
- RAP：将推理视为世界模型规划，用RL价值函数指导MCTS。
	- LATS：语言智能体树搜索，融合思考、行动、反思与RL价值评估。
	- Planning without Search：离线RL训练语言价值裁判，零参数更新增强规划。
- 优势：不破坏LLM原有生成能力，即插即用。

**（2）RL 作为内部驱动（Internal Driver）**

- 机制：直接将LLM视为策略网络，通过与环境交互 **端到端微调** ，让规划能力内化为模型行为。

> 核心逻辑：规划不再是单纯的prompt，而是LLM在交互中习得的内在策略。

- 典型工作：
- VOYAGER：具身智能体中用RL终身学习规划与技能库。
	- ETO、AdaPlan：用DPO/RL优化长程任务规划。
	- Planner-R1：用过程奖励强化规划步骤，提升小模型规划能力。
- 优势：完全自主、动态适应、可长期自我改进。

#### 结论

- 传统规划：固定prompt分解、无反馈、不可学习。
- Agentic RL 规划： **价值引导+策略学习** ，实现动态、自适应、长程、鲁棒的序贯决策。

### 2.工具使用（Tool Using）

工具使用是智能体在推理过程中自主调用外部模块（检索、计算器、浏览器、代码解释器、API等）扩展能力的行为，是LLM突破知识边界的关键。

![智能体工具使用的发展](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

智能体工具使用的发展

#### 强化学习的核心作用

RL让工具使用从 **模仿、固定模式、不可泛化** 升级为 **战略级自主决策** ，实现“何时用、用什么、如何组合、如何从错误恢复”。

#### 三阶段演进

**（1）早期：ReAct 式提示范式（无RL）**

- 代表：ReAct
- 模式：Think → Act → Observe

> 局限：纯上下文学习、不可学习、无法泛化新工具。

**（2）中期：监督微调 SFT（无RL）**

- 代表：Toolformer、AgentTuning、FireAct
- 模式：学习固定工具调用格式

> 局限：静态复制、无法处理异常、不会动态决策。

**（3）高阶：RL 驱动工具集成推理 TIR（Agentic RL 核心）**

- 定义：Tool-integrated Reasoning，工具调用与认知推理深度融合。
- RL 机制：
- 优化工具调用 **时机、选择、顺序、组合、错误恢复** 。
	- 用 **过程奖励+最终奖励** 进行长程信用分配。
- 典型工作：
- ToolRL：从零直接用RL学习工具策略。
	- ReTool：长程工具链规划。
	- GiGPO、SpaRL：步级优势估计，解决信用分配难题。
	- OpenAI o3、Kimi K2：工业级TIR系统。
- 优势：自适应、鲁棒、可处理复杂多工具协同。

#### 区别

- **传统工具使用** ：模仿学习、静态格式、被动触发。
- **Agentic RL 工具使用** ： **自主策略、动态调度、长程规划、错误恢复** ，真正实现工具增强智能。

## 3.记忆（Memory）

记忆是智能体 **对历史信息、对话、知识、经验进行存储、检索、更新、遗忘与管理的能力，是长时程交互的基础** 。

![三类经典智能体Memory方案](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

三类经典智能体Memory方案

#### 强化学习的核心作用

RL让记忆从 **被动存储、固定规则、启发式检索** 升级为 **可学习、可控制、可优化的主动管理系统** 。

#### 三大技术路线

**1.RAG 风格记忆 + RL**

- 机制：RL控制 **检索时机、写入策略、摘要粒度、重排排序** 。
- 代表：Memory-R1、Prospect、Mem-α
- 能力：学习何时查、查什么、如何整合记忆。

**2.Token 级记忆 + RL**

- 显式记忆Token：MemAgent、MEM1、Memory Token
- RL决策保留/覆盖哪些自然语言Token。
- 隐式记忆Token：MemoryLLM、M+、MemGen
- 可微记忆向量，RL端到端优化读写。

**3.结构化记忆 + RL（前沿方向）**

- 形态：时序知识图谱、层级图、原子记忆单元
- 代表：Zep、G-Memory、A-MEM、Mem0
- 未来方向：RL自动控制图谱增删改查（尚未充分探索）。

#### 对比

- **传统记忆：静态存储、规则检索、无自适应。**
- **Agentic RL 记忆** ： **RL驱动全生命周期管理** ， **包括写入、检索、更新、遗忘、压缩、扩展** 。

### 4.自我改进（Self-Improving）

> 智能体通过反思、纠错、迭代、自博弈、自训练，持续提升自身策略、推理与规划的能力，是通用智能的核心标志。

#### 强化学习的核心作用

RL让自我改进从 **一次性语言反思** 升级为 **可固化、可迭代、可无限进化** 的内在能力。

#### 三层进化体系

**（1）语言自我纠正（非参数、无梯度）**

- 机制：生成→评判→改写，纯文本反馈。
- 代表：Reflexion、Self-Refine、CRITIC、Chain-of-Verification
- 局限：改进不持久、不内化到参数。

**（2）内化自我纠正（参数化 RL）**

- 机制：用DPO/GRPO/RPO将反思能力固化到模型权重。
- 代表：Reflection-DPO、KnowSelf、DuPo
- 优势：反思成为模型固有行为，跨任务泛化。

**（3）迭代自我训练（最高阶、无上限进化）**

- 机制：自创任务、自博弈、自验证、RL迭代。
- 代表：
- Absolute Zero：无人类数据自对弈。
	- R-Zero：MCTS+RL自主推演。
	- Sirius、MALT：集体自举进化。
- 优势：完全自主、脱离数据、无限进化。

#### 结论

- **传统自我改进：临时纠错、不可迁移。**
- Agentic RL 自我改进： **反思→参数固化→自博弈迭代** ， **实现真正自主智能体进化。**

### 5.推理（Reasoning）

> 推理是智能体对问题进行逻辑推断、多步演绎、验证与反思的能力，综述采用双系统理论：快思考 vs 慢思考。

#### 强化学习的核心作用

RL解决 **快思考易幻觉、慢思考效率低** 的问题，实现 **自适应思考长度** ，并激励严谨、可信、长程推理。

#### 双系统 + RL

**（1）快推理（System 1）**

- 直觉、快速、一步到位
- 缺陷：易幻觉、浅推理
- RL作用：学习置信度、拒绝不确定问题。

**（2）慢推理（System 2）**

- 多步、结构化、验证式、长思维链
- RL作用：
- 激励思考延长
	- 步骤监督
	- 过程奖励
	- 自我修正
- 代表：DeepSeek-R1、OpenAI o1/o3、GRPO、Reflexion

#### Agentic RL 推理创新

- 自适应思考：根据难度自动选择快慢思考。
- 过程奖励：解决长推理信用分配难题。
- 可验证奖励：基于执行/符号检验降低幻觉。

#### 结论

- **传统推理：固定长度、单步生成、不可控** 。
- **Agentic RL 推理** ： **快慢协同、自适应思考、过程监督、自我修正** 。

### 6.感知（Perception）

> 感知是智能体获取并理解多模态信息（图像、视频、音频、状态）的能力，从“被动看图”升级为“主动视觉认知”。

#### 强化学习的核心作用

RL让感知从 **被动特征提取** 升级为 **主动感知、交互式查询、聚焦式理解** 。

#### 三大主动感知范式

**（1）定位驱动感知**

- 机制：推理步骤绑定图像区域，反复查询、聚焦、验证。
- 代表：GRIT、Ground-R1、DeepEyes、Chain-of-Focus
- 能力：看哪里、聚焦哪里、回看哪里。

**（2）工具驱动感知**

- 机制：调用视觉工具（检测、分割、编辑、绘制）辅助认知。
- 代表：VisTA、VTool-R1、Visual-ARFT、Pixel-Reasoner
- 能力：用工具“增强眼睛”。

**（3）生成驱动感知**

- 机制：在推理中生成草图、想象图像，辅助逻辑推理。
- 代表：Visual Planning、GoT-R1、T2I-R1
- 能力：用想象力辅助感知与推理。

#### 多模态扩展

- 视觉：Vision-R1、VLM-R1、Visual-RFT
- 音频：RL优化TTS与音频问答
- 3D感知：3D空间推理与RL奖励塑形

#### 结论

- 传统感知：被动输入、一次性编码、无交互。
- Agentic RL 感知： **主动看、聚焦看、反复看、用工具看、用想象看** 。
![RL 如何在六大核心能力上赋能智能体 LLM 的概览。中央面板汇总能力分类，侧面板展示代表性 RL 机制与交互模式。](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

RL 如何在六大核心能力上赋能智能体 LLM 的概览。中央面板汇总能力分类，侧面板展示代表性 RL 机制与交互模式。

| 能力 | 传统方式（无RL） | Agentic RL 方式 | 核心升级 |
| --- | --- | --- | --- |
| 规划 | 固定Prompt分解 | 外部价值引导 + 内部策略学习 | 动态自适应、长程鲁棒 |
| 工具使用 | ReAct/SFT静态模仿 | 工具集成推理TIR、自主策略 | 战略调用、错误恢复 |
| 记忆 | 规则检索、被动存储 | RL全生命周期主动管理 | 读写优化、自适应遗忘 |
| 自我改进 | 临时语言反思 | 内化纠错 + 自博弈迭代 | 永久进化、无上限 |
| 推理 | 固定长度单步生成 | 快慢双系统 + 自适应思考 | 低幻觉、强严谨 |
| 感知 | 被动看图 | 主动定位+工具+想象 | 交互式、多步认知 |

## 五、应用领域

Agentic RL 已落地高验证性、高交互性任务：

- `search / deep research agent` ： **自主联网检索、深度报告** （OpenAI Deep Research、Search-R1）；
- `代码智能体` ：生成、调试、软件工程（SWE-Bench、DeepSWE、Qwen3-Coder）；
- `数学智能体` ：非形式推理 + 形式定理证明（DeepSeek-Prover、rStar2-Agent）；
- `GUI 智能体` ：手机 / 电脑 / 网页自动操作（WebArena、OSWorld、UI-R1）；
- `视觉智能体` ：多模态主动感知与推理；
- `具身智能体` ：机器人导航与操控（Voyager）；
- `多智能体系统` ：协作 / 博弈 / 分工（MAGRPO、MAPoRL）；
- `其他` ：文本游戏、时序预测、Text-to-SQ
![面向领域智能体的强化学习演化树](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

面向领域智能体的强化学习演化树

![基于强化学习的search agent与research agent方法汇总](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

基于强化学习的search agent与research agent方法汇总

![面向代码与软件工程智能体的强化学习方法汇总](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

面向代码与软件工程智能体的强化学习方法汇总

![面向数学推理智能体的强化学习方法汇总](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

面向数学推理智能体的强化学习方法汇总

![按训练范式和环境复杂度分类的 GUI 智能体方法汇总](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

按训练范式和环境复杂度分类的 GUI 智能体方法汇总

![基于 LLM 的多智能体系统中强化学习与演化范式汇总。“Dynamic”表示该多智能体系统是否为任务动态，即是否以不同配置（智能体数量、拓扑结构、推理深度、提示词等）处理不同任务查询。“Train”表示该方法是否对智能体的 LLM 主干进行训练](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

基于 LLM 的多智能体系统中强化学习与演化范式汇总。“Dynamic”表示该多智能体系统是否为任务动态，即是否以不同配置（智能体数量、拓扑结构、推理深度、提示词等）处理不同任务查询。“Train”表示该方法是否对智能体的 LLM 主干进行训练

![：面向智能体强化学习的环境与基准概览，按智能体能力、任务领域及模态分类。智能体能力以如下符号表示： 推理、 规划、工具使用、记忆、协作、自我改进](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

：面向智能体强化学习的环境与基准概览，按智能体能力、任务领域及模态分类。智能体能力以如下符号表示： 推理、 规划、工具使用、记忆、协作、自我改进

![按类型与关键特征分类的强化学习框架汇总](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

按类型与关键特征分类的强化学习框架汇总

## 六、 核心结论、挑战与未来方向

### 1\. 主要发现

- **Scaling 规律** ：加大 RL 训练阶段的计算量（Test-time Compute / RL Scaling Law），可系统性提升智能体能力。 **充分 RL 训练的小模型可匹敌大模型** 。
- **奖励的关键性** ：纯 RL 的后训练可能损害事实性，而将 SFT 与可验证奖励的 RL 过程相结合的结构化方法，则可缓解这种退化。 **可验证、密集 过程奖励”（Process-based rewards）如 FSPO，对智能体的每一步推理进行事实性验证，从而直接惩罚不真实的中间步骤。这类的的奖励设计是 Agentic RL 成功的关键因素** 。

### 2\. 当前核心挑战

- **可信度危机** ：RL 容易引发Reward Hacking、幻觉放大以及Sycophancy行为(**LLM在有ground truth的情况下，为迎合用户显性表达的信念而偏离事实的行为**)。
- **规模化瓶颈** ：长序列多步采样的计算成本极高；模型在强化学习过程中容易出现 **熵坍缩（Entropy Collapse)：策略（Policy）的熵值（Entropy）急剧下降，导致策略的随机性显著降低，智能体过早放弃探索，陷入局部最优**
- **环境局限** ：当前多为静态模拟器，缺乏能与智能体协同进化的动态自适应训练环境。

### 3\. 未来研究方向

1. **可信智能体** ：内嵌安全护栏、基于事实的奖励模型设计。
2. **高效训练算法** ：低算力消耗、小数据依赖、跨任务迁移的轻量级 RL 算法。
3. **元学习（Meta-Learning）** ：让智能体在 RL 过程中学会“如何学习”与“如何反思”。
4. **真实世界部署** ：建立“Human-in-the-loop”、分层编排与标准化的多智能体通信协议。
```
论文：The Landscape of Agentic Reinforcement Learning for LLMs: A Survey
链接：https://arxiv.org/pdf/2509.02547
```

Agentic · 目录

继续滑动看下一个

AIGC面面观

向上滑动看下一个