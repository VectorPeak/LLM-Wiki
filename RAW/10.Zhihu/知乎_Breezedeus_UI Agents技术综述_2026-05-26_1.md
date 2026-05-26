---
title: "知乎_Breezedeus_知乎文章搜索剪藏_2026-05-26_1"
source: "zhihu official api + tikhub"
author:
  - "Breezedeus"
published:
created: 2026-05-26
range: "1"
description: "知乎官方 API 定位，TikHub 补全文，共 1 条，本文件收录第 1 篇。"
tags:
  - "clippings"
  - "zhihu"
  - "Breezedeus"
---
## 一、UI Agents（智能体）技术综述

**更好的阅读体验请见：**

[UI Agents（智能体）技术综述 | Breezedeus.com](https://link.zhihu.com/?target=https%3A//www.breezedeus.com/article/ui-agent)

---
### 一、UI Agents技术概述
**UI Agents 技术**利用大模型技术（VLM / LLM）实现智能体对手机或电脑的自动操作，模拟人类行为完成指定任务，涵盖 Web GUI 和 Mobile GUI 等多种应用场景，甚至与 Embodied Navigation 中的 Vision Language Navigation（VLN）任务也有相似之处。

#### UI Agents的定义与示例
UI Agents 的核心在于智能体能够模拟人类操作，自动执行任务。例如，当我们下达`“微信给小明发送一条消息：‘吃了吗？’”`这样的指令时，UI Agents 会像人类一样理解任务，然后在手机或电脑上执行一系列操作，如打开微信、找到小明的聊天窗口、输入消息并发送。这一过程涉及到对UI界面的感知、理解以及精确操作，其本质是一个 **Partially Observable Markov Decision Process (POMDP)** 问题，智能体无法观察到所有的状态信息，需要根据当前可观察到的状态（如UI截图和对应的XML）做出决策，输出如`“CLICK(100, 200)”`这样的操作指令，其中“`CLICK`”为动作名称，“`(100, 200)`”为动作参数，即点击的坐标。

![image](https://pic2.zhimg.com/v2-96cd76c52765585f534a81106d52937d_1440w.jpg)

#### UI Agents面临的独特挑战
尽管 UI Agents 前景广阔，但在实际应用中面临诸多挑战。首先是序列决策问题，其收益具有延迟性，这意味着智能体在执行任务过程中，可能无法立即知晓当前操作的有效性，直到任务完成才能确定最终收益。其次，网站和应用程序的频繁更新导致在线观测结果与离线数据不一致，给智能体的学习和决策带来困难。此外，各种不可预测的干扰项，如弹出广告、登录请求以及搜索结果的随机顺序等，都会影响智能体的正常操作。技术方面，网页加载不完整或对某些网站的临时访问受限等问题也时有发生，这些都对 UI Agents 的性能和稳定性提出了更高要求。

![image](https://pic1.zhimg.com/v2-9d91869e7492f5914a16996bea7fbe3e_1440w.jpg)

### 二、UI Agents技术路线
实现 UI Agents 主要涉及**感知**（Perception）、**规划/决策**（Planning/Decision）等关键环节，技术路线多样，包括基于Closed LLM、VLM等不同方式，各有优劣。

![image](https://pic1.zhimg.com/v2-ff891211336b86bf009a3b63c31471ba_1440w.jpg)

#### 感知（Perception）技术
在 **Perception 方法**中，智能体通过截屏XML、截屏图片、OCR、Summarization、Icon Detection & Captioning 等技术，将 UI 截图转换为结构化信息，以便进行后续的规划和决策。

![image](https://pic2.zhimg.com/v2-dc68e32e0ebdfc081a3664292c4798df_1440w.jpg)

![image](https://picx.zhimg.com/v2-ac28d6a3f00c34b347ddba49ac8f222b_1440w.jpg)

#### Closed LLM (Training-free)
![image](https://pic2.zhimg.com/v2-52660714e63388cbceb1f88b5467ec91_1440w.jpg)

这种方法先利用感知技术将当前状态转换为文本，再借助 LLM 进行推理和决策。以 AutoDroid（清华）和 AWM（CMU & MIT）为代表，其优化方向主要集中在 Memory Construction & Usage、Prompt 以及Trajectory Planning 等方面。在这一过程中，感知能力至关重要，它决定了如何用文本准确表达当前状态，而LLM的推理能力则直接影响决策的准确性。

**Memory的构建与使用（以AWM为例）**

AWM 从已有路径中抽取公共的**抽象子路径（workflow）**，每个 workflow 包含 **workflow 描述**（自然语言描述功能）和**具体路径**（节点包含当前环境描述、推理说明和动作等信息）。Memory 使用时，通过向量检索得到 top-k 个结果并加入 prompt，以增强决策依据。

![image](https://pic2.zhimg.com/v2-5b904e29067542211e739a95a73209ad_1440w.jpg)

#### VLM - driven UI Agents
VLM-driven UI Agents 的 **Policy Model** 基于 VLM 实现，VLM 同时完成感知、规划和决策任务。对 VLM 的独特要求包括UI任务执行和推理能力、全局理解能力和局部细节理解能力。

![image](https://pic1.zhimg.com/v2-a7d70d241eadd328a7515698b0bbdb28_1440w.jpg)

VLM 在 UI Agents 中承担着感知、规划和决策的多重任务，对其有独特要求。它需要具备 UI 任务执行和推理能力，包括全局理解能力（如细粒度 OCR、UI 界面理解）和局部细节理解能力（如元素定位、指称能力），以应对UI操作中的各种需求。

#### Perception + Closed VLM
- **SoM (Set-of-Mark Prompting)**：Microsoft 提出的 **SoM** 利用检测模型将图像分区并添加标记，辅助 VLM 进行推理决策，如在 GPT-4V 中通过这种方式提高视觉定位能力。
- **Closed VLM代表性工作**：包括 MM-Navigator（Microsoft）、AppAgent（Tencent）、Mobile-Agent-v2（Alibaba）、OmniParser（Microsoft）等。以 OmniParser 为例，它融合多个感知模块结果（如微调的可交互图标检测模型、图标描述模型和 OCR 模块）后输入到 GPT-4V 中，生成类似 DOM 的 UI 界面结构化表示形式，提升对 UI 的理解和操作能力。

![image](https://pic3.zhimg.com/v2-cd23341806679cd5d31ed4ebf7e508d6_1440w.jpg)

![image](https://pic4.zhimg.com/v2-449161fa89268e29de440b274b12c6d9_1440w.jpg)

#### Open VLM (Training-based)
Open VLM技术路线中，VLM通过训练数据精调，不改变其架构。代表性工作包括 CogAgent、Ferret-UI 和 SeeClick，它们各自采用了不同的技术和方法来提升VLM的效果。

![image](https://pica.zhimg.com/v2-4b33e267ca1c0a01fa58d75cb0a18a18_1440w.jpg)

**针对GUI任务设计特有VLM结构**：

- **CogAgent（Zhipu）**：在 CogVLM 基础上新增小型高分辨率图像编码器（0.3B参数），支持超高分辨率图像输入，降低处理高分辨率图像的计算成本，增强与 GUI 相关的问答和 OCR 任务能力。

![image](https://pic1.zhimg.com/v2-0d7d8901480e56799628a8a9ef1199fe_1440w.jpg)

- **Ferret-UI（Apple）**：基于 Ferret VLM 训练，通过特定的 **anyRes** 方法（根据屏幕纵横比切分原始图片为子图并单独编码）执行精确指称和定位任务，其训练涉及多种任务，如指称、定位、问答、Summarization和功能判断等。

![image](https://pic1.zhimg.com/v2-3c6ff7fae2d513988ba8ae961efa99da_1440w.jpg)

**使用GUI任务数据精调通用VLM**：

- **SeeClick（Shanghai AI Lab）**：分两阶段训练，预训练阶段利用GUI grounding基础预训练策略增强通用VLM（Qwen - VL）的grounding能力，包括预测坐标、基于坐标或边界框预测文本、UI总结和通用视觉语言指令跟随等任务；微调阶段将指令、当前界面截图和历史动作作为输入，预测下一步操作。

![image](https://pica.zhimg.com/v2-dfba70c362caa56d6cb2a3ffe8376372_1440w.jpg)

![image](https://pica.zhimg.com/v2-a07f0411012b7d4422f8330d2836b77c_1440w.jpg)

- **MobileVLM（XiaoMi）**：基于Qwen - VL - 9B利用UI数据进一步训练，构建了包含大量UI截图、XML和动作的Mobile3M数据集，通过该数据集开展元素定位、动作预测、元素列表生成和动作空间生成等任务，并采用三阶段训练（难度渐进式增加）提升模型对单个UI页面内部、两个页面之间关系以及端到端任务完成能力。

#### Pipeline: Planning + Precise Grounding
此方法将规划和精确定位分离，使用 VLM 进行规划，输出动作的文本描述，再用其他模型精确定位动作信息（如坐标、输入文本等）。代表性工作如 ClickAgent（Samsung），其决策模块使用InternVL2.0-76B 进行推理、动作规划和反思，UI Location Model 对“`CLICK`”动作使用 TinyClick 产生精确点击坐标；LiMAC（Huawei）由 AcT（预测动作类型和参数）和 VLM（生成 text 字符串）组成 pipeline 执行 UI 任务；AutoGLM（Zhipu）基于“**基础智能体解耦合中间界面**”和“**自进化在线课程强化学习框架**”，将任务规划与动作执行解耦，规划器给出动作文本描述，执行器给出具体参数。

![image](https://pica.zhimg.com/v2-0a14b8bd4238d47a2f94f4aef17fd192_1440w.jpg)

![image](https://pic4.zhimg.com/v2-400186b859f7e8f1eac7c300a0e8db97_1440w.jpg)

![image](https://pic3.zhimg.com/v2-5776fabd471aa96c18b8f3852e2d8ee4_1440w.jpg)

![image](https://pica.zhimg.com/v2-4b9f356544b4eb5c06e219492232f6e6_1440w.jpg)

### 三、UI Agents 的高级优化技术
为了进一步提升 UI Agents 的性能，研究人员探索了多种高级优化技术，从不同方面改进模型。

这些优化技术涵盖多个方面，包括增强 Memory/Knowledge，使用更好的 Base VLM，获取更多更好的数据（如通过搜索方法如 MCTS 进行数据探索和利用），改进训练方法（如确定训练任务和顺序，采用 RL（DPO）提升推理和规划能力）以及优化推理方法（如 CoT、ReAct、多智能体协作、树搜索等）。

![image](https://pic4.zhimg.com/v2-9c2cb1a9ca0101b267a02e29a2956301_1440w.jpg)

#### 代表性工作
**Agent Q（MultiOn & Stanford）**

利用 MCTS + Step-DPO + PlanReAct 训练 LLM/VLM 模型。训练时，MCTS 自动探索和执行动作获取正负样本数据，Selection 阶段使用过程奖励模型预测节点潜在收益，Expansion 阶段基于 Critic Model 选择 top-K 动作扩展，Simulation 阶段用 GPT-4V 判断任务完成情况；然后使用 Step-DPO 精调模型以提升推理和规划能力。

![image](https://pic2.zhimg.com/v2-f9ebd1855f76da959afcee2916d3dc0f_1440w.jpg)

#### Inference-time Tree Search（CMU）
在推理时采用 best-first 树搜索提升效果。基于 LLM/VLM 的 Policy 函数选择最优 top-b 个 actions，Value 函数（使用 GPT-4o 并采用 self-consistency 机制取20次调用平均得分）判断当前状态期望收益，树搜索优先探索Value值大的节点。

![image](https://pic1.zhimg.com/v2-6e932ca32e6d770460124c8b000c4e1e_1440w.jpg)

#### Mobile-Agent-v2（Alibaba）
引入多智能体（规划、决策、反思智能体）和记忆单元协同工作。记忆单元存储任务相关焦点内容并随任务更新；规划智能体生成任务进度辅助决策；决策智能体根据任务进度、屏幕状态和反思结果生成操作并更新记忆单元；反思智能体观察操作前后屏幕状态，判断操作是否符合预期，若错误则回退页面，若无效则维持状态。

![image](https://pic1.zhimg.com/v2-fb1b9a15e11dd69b786e067190eb521e_1440w.jpg)

### 四、UI Agents的评测方法
准确评测 UI Agents 的性能对于其发展至关重要，目前主要采用人工评测和自动评测两种方式，同时也有专门的测试平台。

#### 评测方式与指标
- **人工评测**：精度高，但耗时且成本高。
- **自动评测**：速度快、成本较低，但精度相对不高。
- **评测指标**：
- **Step-wise**：包括动作准确率（Act.Acc，所有动作成功率平均分，点击准确率反映定位能力，类型匹配率反映动作名称准确率）。
- **Episode-wise/Trajectory-wise**：涵盖任务成功率和任务完成效率（完成任务平均步数）。
- **Path-wise**：包含路径匹配度、路径节点最高收益值（从节点到达任务完成的概率）和Essential States（任务完成必要状态或关键节点）。
- **Testbed for Task Automation**：为UI任务自动化提供了专门的测试环境，有助于更全面准确地评估UI Agents的性能。

![image](https://pic2.zhimg.com/v2-a3ff6c3ca495c88bd63369876c049f8d_1440w.jpg)

### 五、UI Agents技术的回顾与总结
综合来看，不同 UI Agents 技术路线在效果、资源需求和风险等方面存在差异。

- **Closed LLM**：公开工作中的效果一般（⭐⭐），算力和数据需求很低，但后续效果优化难度大，推理耗时一般，隐私安全低，达成效果的风险较高。
- **Closed VLM**：效果相对较好（⭐⭐⭐），算力需求较低，数据需求低，后续优化较难，推理慢，隐私安全低，风险一般。
- **新架构VLM**：效果上限高（⭐⭐⭐⭐），但算力和数据需求极高（百卡量级和百M量级），优化有点难，推理耗时一般，隐私安全高，工作量大导致达成效果的风险较高。
- **通用VLM微调**：效果较好（⭐⭐⭐⭐），算力和数据需求一般（8～16卡量级和M量级），后续优化难度一般，推理耗时一般，隐私安全高，风险一般。

![image](https://pic1.zhimg.com/v2-06ff48dd96f005a213ea51dfed5cc5a0_1440w.jpg)

在选择UI Agents技术路线时，需要综合考虑效果上限、训练资源需求和风险、服务部署风险等因素。例如，资源有限的情况下，Closed LLM 或 Closed VLM 可能是较合适的选择；而对于追求高性能且有足够资源的场景，新架构 VLM 或通用 VLM 微调可能更具潜力，但也要权衡其带来的风险。

### 六、UI Agents技术的未来展望
展望未来，UI Agents技术在两个核心能力上有望持续发展。

- **UI界面理解能力**：进一步增强UI相关问答能力，使智能体能更深入理解UI界面的各种元素和功能。
- **UI任务规划和执行能力**：优化规划和推理算法，更精准地规划下一步操作，提高任务执行的成功率和效率。

**技术发展方向：**

- **Memory/Knowledge Enhanced**：不断改进记忆和知识增强技术，让智能体能够更好地利用历史经验和知识进行决策。
- **Better Base VLM**：提升基础VLM的性能，包括元素定位、指称和细粒度OCR能力。例如，通过改进图像分区方法（sub - images / patches）、添加额外模块处理高分辨率图像或采用动态分辨率技术，适应不同UI场景的需求。
- **More and Better Data**：探索更多数据获取和利用方式，如利用搜索技术（如MCTS）挖掘更多有效数据。
- **Better Training Methods**：优化训练方法，确定更合适的训练任务和顺序，采用强化学习（如DPO）提升推理和规划能力。
- **Better Inferencing Methods**：持续改进推理方法，如通过CoT、ReAct实现更好的推理和规划，利用多智能体协作（规划、决策、反思智能体）以及树搜索技术提升性能。

![image](https://picx.zhimg.com/v2-2c2c7352fd74a8d04e2c7cb9ccfd92a7_1440w.jpg)

UI Agents 技术作为一项具有巨大潜力的技术，虽然目前仍面临诸多挑战，但随着技术的不断发展和优化，有望在未来为我们带来更加智能、高效的人机交互体验，广泛应用于智能客服、自动化测试、智能办公等多个领域，推动数字化进程不断向前发展。

#### 分享视频
- **Youtube**: [https://youtu.be/YAhXGjV25zU](https://link.zhihu.com/?target=https%3A//youtu.be/YAhXGjV25zU)
- **Bilibili**: [https://www.bilibili.com/video/BV1CtDWYzE9b](https://link.zhihu.com/?target=https%3A//www.bilibili.com/video/BV1CtDWYzE9b)

#### [AI Agents 知识星球](https://link.zhihu.com/?target=https%3A//t.zsxq.com/1uB5s)
UI Agents 技术发展迅猛，想紧跟 **UI agents 技术前沿**？我们的[知识星球](https://link.zhihu.com/?target=https%3A//t.zsxq.com/1uB5s)每周以视频方式解读最新论文，为你开启技术新视野，快来加入吧！本文完整 slides 也可在星球中下载查看。

[https://t.zsxq.com/1uB5s​t.zsxq.com/1uB5s](https://link.zhihu.com/?target=https%3A//t.zsxq.com/1uB5s)

**欢迎转载，转载请注明出处：[UI Agents（智能体）技术综述 | Breezedeus.com](https://link.zhihu.com/?target=https%3A//www.breezedeus.com/article/ui-agent)。**
