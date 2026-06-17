---
title: "微信_波哥_公众号文章剪藏_2026-05-27_1-2"
source: "/api/v1/wechat_mp/web/fetch_mp_article_detail_html"
author:
  - "波哥"
published: "2026-05-03"
created: 2026-05-27
description: "TikHub 命中的微信公众号文章候选，共 2 条，本文档收录 2 条"
tags:
  - "clippings"
  - "wechat"
  - "波哥"
---

## 0x01. 为什么用 GRPO 训练 Reward Model?——从数学推理到偏好建模的范式迁移

> 发布日期：2026-05-03  
> 原文链接：[为什么用 GRPO 训练 Reward Model?——从数学推理到偏好建模的范式迁移](https://mp.weixin.qq.com/s/N7lNtBgl8dDRaMDJqByYAA)

当面试官问"GRPO 不是用来做数学题的吗?为什么你们拿它训 RM?"——这个问题背后,是 RLHF 范式正在发生的一次深层变革。

### 1. 问题的起点:一个看似矛盾的选择
 GRPO(Group Relative Policy Optimization)最早在 DeepSeekMath 中被提出,并在 DeepSeek-R1 的训练中大放异彩。它的标志性应用场景是 **带可验证奖励的数学/代码推理任务** ——答案对就是 1,答案错就是 0,规则清晰、信号干净。

 那么一个自然的疑问就出现了:

 **Reward Model 的训练,本质上是一个偏好建模问题(给定 prompt 和两个 response,判断哪个更好)。这听起来更像是一个分类/回归问题,为什么要用一个为"数学推理"设计的** **RL** **算法去训练它?** 要回答这个问题,我们需要先打破两个误解:

 **误解一**:GRPO 是"数学算法"。其实 GRPO 只是 PPO 的一个变体,它的核心创新与数学无关。

 **误解二**:RM 是"打分器"。现代 RM 早已不是一个吐 scalar 的小模型,而是一个会"思考"的 Generative Reward Model(GenRM)。

 把这两个误解同时拆掉,答案就显而易见了: **当** **RM** **从"判别式打分器"演化为"生成式判官(LLM-as-a-Judge)",它训练自己的过程就和训练一个推理模型本质同构——而 GRPO 正是当前训练推理模型的最优解之一。** 下面我们一层一层剥开来看。
![img](https://mmbiz.qpic.cn/mmbiz_png/kSX2Q9RM8CSnPEWcNQNLibiaDGrFAYZqWv0ILvU97ibgQviapXx4IlYCTAE3Wb9GBHiaggAVaA8Z7Y0LfnHs1eYp9U50JfHOqQPRc4DYrX7mfU6E/640?wx_fmt=png&from=appmsg)
### 2. 回到第一性原理:GRPO 到底在做什么

#### 2.1 PPO 的痛点
 经典的 RLHF 用 PPO,它的目标函数(简化版)是:

 其中 advantage

 由一个 **独立训练的 value network** (critic)估计:
![img](https://mmbiz.qpic.cn/mmbiz_png/kSX2Q9RM8CRCUia4JMSpceS8f31MS6Jcq6jn3iawIAahjIfeh47ptUoXhric8gXqKzgzwTjwcycpD8bRvj8aOtBCRcGhodrIoQ0lrG3Vk2joU0/640?wx_fmt=png&from=appmsg)
 PPO 的麻烦在于:

 需要额外维护一个和 policy 同等规模的 critic,显存翻倍

 Critic 的训练本身不稳定,误差会传到 advantage 估计

 对 reward 噪声极其敏感

#### 2.2 GRPO 的核心改动
 GRPO 的做法非常朴素粗暴: **不要 critic,用一组样本的相对得分代替 value baseline**。

 对每个 prompt,采样一组

 个回答,每个回答打个分,然后:

 就这么简单。Advantage 不是从 value network 学出来的,而是 ** 组内****归一化 ** 得出的相对优势。比组内平均好的,advantage 为正;比平均差的,为负。

 这个改动看似只是"省了一个 critic",但它带来了三个深刻的性质,而 **这三个性质恰恰是把 GRPO 用到** **RM** **训练上的根本原因**:

 **绝对 reward 的尺度无关性**:只要组内相对顺序对,advantage 就有意义。这意味着 reward 可以是嘈杂的、未校准的、甚至是非数值的(只要能排序)。

 **对稀疏 reward 友好**:即使大部分 reward 是 0,只要组内有差异,梯度就能流动。

 **天然适合"过程对、结果对"都重要的任务**:因为同一个 prompt 下采多条轨迹,可以暴露出"思路不同但都正确"或"思路相似但答案错误"的对比。

### 3. Reward Model 的进化:从 Scalar Head 到 Generative Judge
![img](https://mmbiz.qpic.cn/sz_mmbiz_png/kSX2Q9RM8CQuoAiaBTYV0PxFicab8sb0TxDnH9fC8icib33lwQaKjBuiafnxIDzbHibq24IJN1ibprAtrfep3aWAicor4LFB8pa4HSl4oIhibAicn8m8Q/640?wx_fmt=png&from=appmsg)
#### 3.1 传统 RM 的局限
 传统 RM(Bradley-Terry RM)的训练目标是:
![img](https://mmbiz.qpic.cn/sz_mmbiz_png/kSX2Q9RM8CT2DLveic2snOUicf6rhvElaic2afnNpuGBcPcPuUfg5pOIQMertCHxWMib4UscaNLu0kHvWMjYBFPdDr2PKG9Kno3oU34icQUpiccHo/640?wx_fmt=png&from=appmsg)
 模型在 LLM 顶上加一个 scalar head,输出一个标量分数。

 但这种 RM 有几个臭名昭著的问题:

 **校准差**:同一个分数在不同 prompt 下含义不同

 **不可解释**:给了 6.3 分,问它为啥?它说不出来

 **泛化弱**:换一个领域,scalar head 的判断就崩了

 **没法 scale test-time compute**:LLM 思考越久越聪明,但 scalar RM 只能 forward 一次

#### 3.2 Generative Reward Model 的兴起
 新一代 RM 的思路完全不同—— **让 RM 像一个真正的判官那样,先思考、再下结论**。

 具体形式有两种:

 **Pointwise** **GenRM**:
```text
Input: <prompt> <response>
Output: <reasoning chain> ... 综上,我给这个回答打 8 分。
```
 **Pairwise GenRM**:
```text
Input: <prompt> <response A> <response B>
Output: <分析 A> <分析 B> <对比> ... 因此 Response A 更好。
```
 像 RM-R1、J1、Think-J、EvalPlanner 这些 2025 年的工作,本质上都是把 RM 训练成一个 **专门用于评判的 reasoner**。RM-R1 在 RewardBench 上甚至能用 7B 模型超过 GPT-4o。

 **关键的认知转变**:RM 不再是"打分器",它是一个 **专门做评估推理的** **LLM**。它要思考评判标准、对比候选答案、给出有理有据的判断。

### 4. 范式同构:为什么 GRPO 是训练 GenRM 的最优选
 到这里,核心论点终于可以亮出来了。

 如果 GenRM 的本质是"让 LLM 学会更准确地做评判推理",那么训练它的过程和训练一个数学推理模型在结构上完全同构:

| 维度 | 数学推理模型 | Generative RM |
| :--- | :--- | :--- |
| 输入 | 数学题 | prompt + 候选回答 |
| 中间过程 | 解题思维链 | 评判思维链 |
| 最终输出 | 答案 | 偏好判断 / 分数 |
| Reward 信号 | 答案对不对(规则可验证) | 判断是否符合人类偏好(数据集标注) |
| 难点 | 思维链能不能引导出对的答案 | 评判推理能不能得出对的偏好 |

 最右一列每一行,都可以从最左列对应位置"翻译"过来。这就是为什么 DeepSeek-R1 那套 GRPO 训练范式可以 **几乎不加改动地** 搬到 RM 训练上来。

 更具体地说,GRPO 在 GenRM 训练中带来了四个无法替代的优势:

#### 4.1 把"偏好对"天然转换为可验证 reward
 GenRM 训练数据通常长这样: (prompt, response_A, response_B, label),其中 label 是人类标注的偏好。

 把它喂给 GenRM,让 GenRM 输出"我认为 A 更好/B 更好",然后 **判断 GenRM 的最终结论是否和 label 一致** ——一致 reward = 1,不一致 reward = 0。

 这就把一个看似主观的偏好建模问题, **转化为了和数学题一模一样的可验证 reward 任务**。GRPO 在这种场景下天然适配,这也是为什么 J1、RM-R1 等工作不约而同选择了 GRPO。

#### 4.2 组内对比正好契合 RM 训练数据结构
 回想 GRPO 的采样:对一个 prompt 采 G 条回答。

 而 RM 的训练数据本来就是"对同一个 prompt 的多个回答做对比"。两者的数据组织方式 **完全咬合** ——同一组 prompt 下 GenRM 生成多条不同的"评判推理轨迹",有的判对了(reward=1),有的判错了(reward=0),GRPO 用组内 advantage 自动学到"什么样的评判思维链更可能给出正确判断"。

 如果用 PPO,你需要再训练一个 critic 来估计 GenRM 在每个评判 token 的 value——这既荒谬又低效。

#### 4.3 缓解 RM 训练中的尺度问题
 传统 BT-RM 训练有个老问题:模型容易学到"打高分都打高,打低分都打低"的偷懒模式。GRPO 的组内归一化天然消除了 reward 的绝对尺度, **只保留相对顺序信号**,逼着模型学习真正的判别能力,而不是 reward 的均值。

#### 4.4 让 RM 在 test-time 也能 scale
 这是最被低估的一点。

 传统 scalar RM 推理时一次 forward 完事,test-time compute 没法 scale。但 GRPO 训练出来的 GenRM 可以:

 同一 prompt 采多条评判推理,投票选最一致的判断(self-consistency)

 用更长的思维链(longer CoT)拿到更准的判断

 在线生成"评判 rubric"再做评估

 这意味着 GenRM 继承了 LLM 推理模型的所有 test-time scaling 红利,而这正是 GRPO 训练范式的副产物。

### 5. 一个具体的训练流程
 把上面的理论落地,一个典型的"用 GRPO 训 GenRM"的 pipeline 是这样:

 **阶段 1:冷启动** **SFT** 用一批高质量的"评判思维链"数据(可以是从 GPT-4 蒸馏的,或人工写的)做 SFT,让模型先学会"评判应该长什么样"。这一步对应 R1 的 cold-start。

 **阶段 2:GRPO 训练** 
```text
For each step:
  1. 从偏好数据中采一个 batch: (prompt, response_A, response_B, label)
  2. 对每个样本,让当前 GenRM 采样 G 条评判推理(temperature > 0)
  3. 解析每条推理的最终结论,与 label 对比,计算 reward ∈ {0, 1}
  4. 组内归一化得到 advantage
  5. GRPO 目标函数更新参数
  6.(可选)加格式 reward:输出格式不合规则扣分
```
 **阶段 3(可选):reward shaping** 加入辅助 reward,比如:

 一致性 reward:多次采样结论一致的奖励

 校准 reward:对置信度的校准

 长度惩罚:防止 CoT 过长

 ms-swift 框架在 2025 年 5 月已经原生支持这套流程,可以直接用 --rlhf_type grpo --reward_model_plugin genrm 跑起来。

### 6. 几个值得警惕的坑
 理论虽美,工程实践有自己的现实主义。把 GRPO 用在 RM 训练上,以下几个坑必须留意:

 **坑 1:Reward Hacking 在元层面的复发** 讽刺的是,你在用 GenRM 防 policy 的 reward hacking,但 GenRM 自己也会 hack 它的训练 reward。比如学会"无脑判 A 更好,因为训练集里 A 略多"。Cooper 等工作通过 co-optimize policy 和 RM 缓解这个问题。

 **坑 2:Group Size 的两难** G 太小,advantage 估计噪声大;G 太大,显存吃不消、采样慢。一般 G ∈ [4, 16],但对 GenRM 评判任务,因为 reward 二值化, **实践经验是 G 至少要 8** 才能保证一组内既有正例也有负例(否则 advantage 全是 0,梯度消失)。

 **坑 3:KL 惩罚的双刃剑** GRPO 默认带 KL 惩罚把模型拉回 reference。但 GenRM 训练时,过强的 KL 会限制评判推理的探索空间,让模型不敢生成长 CoT;过弱又会忘掉语言建模能力。需要细调。

 **坑 4:格式崩坏** GenRM 必须在结尾输出可解析的判断(如 [[A]] 或 Answer: 8)。训练初期模型容易"忘了画句号",reward 解析失败。一定要加 **格式 reward 兜底**。

### 7. 更深的一层:这反映了什么趋势?
 把视角拉远,GRPO 训 RM 这件事不是一个孤立的 trick,它是 2024-2025 年 LLM 领域两个深层趋势的交汇:

 **趋势一:一切皆为推理(Everything is Reasoning)** 从 OpenAI o1、DeepSeek-R1 开始,业界发现"在输出前先思考"几乎可以提升任何任务的表现。RM 评判、Agent 规划、代码 review、数学解题——只要任务本身有"该怎么做才对"的判断,加上 CoT 都会变好。RM 当然也不例外。

 **趋势二:RL算法的统一** PPO、DPO、GRPO、Reinforce++ 等算法看起来五花八门,但 2025 年大家逐渐意识到: **只要你的任务能被写成"采样多个候选 → 给出可验证 reward → 用 advantage 更新 policy",GRPO 几乎都能用,而且通常是最简单的那个**。这种"用一把锤子敲所有钉子"的能力,正是 GRPO 攻占 RM 训练的根本原因。

 把这两个趋势叠加,你会发现:

 **训练** **RM** **和训练数学推理模型,在 2026 年的视角下,根本就是同一件事。** 它们的输入不同、reward 来源不同,但目标都是"让 LLM 学会输出某种'对'的推理链"。GRPO 是为这个目标量身定做的算法,所以它能跨任务通用,毫不奇怪。

### 8. 结语
 回到开头那个问题:"GRPO 不是用来做数学题的吗,为什么你们拿它训 RM?"

 完整的答案应该是:

 GRPO 从来就不是"数学算法",它是一个 **为可验证 reward + 推理生成** 设计的通用 RL 框架。当 RM 从 scalar head 演化为 Generative Reward Model,它的训练目标恰好满足 GRPO 的两个前提:可验证(判断对/错)+ 推理生成(评判思维链)。所以这不是"借用",而是 **结构** **同构** **带来的必然选择**。

 更进一步,这件事提醒我们一个更朴素的道理:

 **当算法和任务的数学结构对得上时,效果就是好。当对不上时,加再多技巧也是缝补。** ——这或许是 RLHF 这一波折腾给我们留下的最有价值的一条经验。

#### 参考资料
 DeepSeekMath / DeepSeek-R1: GRPO 原始论文

 Generative Reward Models (Mahan et al., 2024): GenRM 的奠基工作

 RM-R1 (2025): Reward Modeling as Reasoning,首次系统用 RL 训练推理型 RM

 J1 (Meta, 2025): Incentivizing Thinking in LLM-as-a-Judge via RL

 Think-J (2025): GRPO 在 RM 训练上的对比实验,显示其优于 PPO/DPO/Reinforce++

 Cooper (2025): Co-Optimizing Policy and Reward Models

 ms-swift 框架文档:GRPO + GenRMPlugin 的开源实现
![图片](https://mmbiz.qpic.cn/sz_mmbiz_png/kSX2Q9RM8CTpfpHHsCWCx05L3rjn5EqykKRibwib6U5S9MeC6fF4n8KoEV8U3XxHKDCQqB443qdI43C5VPyKvMYVaCNXWaFpP3Ga2ooyJ97do/640?wx_fmt=png&from=appmsg&wxfrom=5&wx_lazy=1&tp=webp#imgIndex=0)

## 0x02. 【面试经验复盘】GRPO 中的 Reward Hacking：问题剖析与解决方案

> 发布日期：2026-04-13  
> 原文链接：[【面试经验复盘】GRPO 中的 Reward Hacking：问题剖析与解决方案](https://mp.weixin.qq.com/s/vUoaNZE017H_EgP-ppZmqg)

GRPO 中的 Reward Hacking最近面试被问的很多。

 本文将系统梳理 GRPO 训练中 reward hacking 的典型表现、根本成因，以及目前已被验证有效的缓解策略。

### 什么是 Reward Hacking？
 Reward hacking 是指模型通过利用奖励函数中的漏洞或偏差来获取高分，而非真正完成预期任务。这一现象与古德哈特定律(Goodhart's Law)高度相关： **当一个度量指标变成优化目标时，它就不再是一个好的度量指标。** 在 LLM 的语境下，reward hacking 有几种常见的表现形式：

 **长度膨胀(Length Hacking)**：模型生成冗长的回答来获取更高奖励分数，但内容并无实质性增益。这是实践中最常见的 reward hacking 模式。

 **谄媚倾向(Sycophancy)**：模型倾向于迎合用户的观点，即使用户的陈述是错误的。

 **格式投机(Format Gaming)**：模型过度堆砌 Markdown 格式、列表和术语来伪装高质量输出。

 **捷径利用(Shortcut Exploitation)**：模型找到与高奖励虚假相关的模式并加以利用，而非学习真正的问题求解能力。

### GRPO 特有的 Reward Hacking 机制
 GRPO 的优势计算方式使其在某些场景下对 reward hacking 特别脆弱。理解其内在机制是解决问题的前提。

#### Z-Score 归一化导致的崩溃
 GRPO 的核心思路是对同一 prompt 的

 个候选回答计算奖励的 z-score 作为优势值。问题在于，当所有候选回答的奖励趋于一致时，标准差接近零，优势值也归零，梯度随之消失。

 一个经典的案例来自 Ishan Mukherjee 的实验：使用 HuggingFace 的 GRPOTrainer 在 Qwen2.5-1.5B-Instruct 上训练 Reddit 帖子的 20 字符摘要。奖励函数本意是鼓励生成长度接近 20 字符的文本，但模型迅速找到了"捷径"——将所有候选回答都填充到 256 token 的上限(全是随机数字)，使得每个回答的奖励完全相同、z-score 为零。训练在不到 0.01 个 epoch 后就发生了彻底崩溃。

#### 多目标场景下的偏科现象
 当 GRPO 需要同时优化多个奖励函数时(例如翻译准确性和可读性)，由于不同奖励的量级和方差差异，模型往往会"偏科"——过度优化方差较大的那个目标，而牺牲其他目标。Ichihara 等人在机器翻译实验中观察到，GRPO 在 En-Ja 翻译任务中大幅提升了日文可读性分数，但翻译准确性(BLEURT 分数)反而显著下降，导致整体质量评估(LLM-as-a-Judge)中表现最差。

#### 熵坍缩(Entropy Collapse)
 GRPO 训练过程中策略的熵会快速下降，导致模型对每个 prompt 生成几乎相同的回答。这本质上是探索与利用(exploration vs. exploitation)的失衡——模型过早收敛到一个局部最优，丧失了发现更好策略的能力。DAPO 的作者指出，这一问题部分源于 GRPO 中 clipping 机制对探索的限制。

#### 梯度消失问题
 当某些 prompt 的所有候选回答都获得满分(准确率为 1)时，组内优势全部为零，产生零梯度。这些"已经解决"的样本无法对训练产生贡献，实际上浪费了计算资源并拖慢了学习进程。

### 解决方案

#### 1. KL 散度惩罚
 在 GRPO 目标函数中加入对参考模型(通常是初始 SFT 模型)的 KL 散度惩罚项，是防止模型走向极端最基本的手段。通过 beta 系数控制惩罚强度，可以约束新策略不要偏离参考策略太远。

 但正如前文提到的实验所示，如果 beta 设置得太小(如 0.001)，模型仍然可能在 KL 惩罚生效之前就已经崩溃。因此 beta 的调参至关重要，通常需要根据任务难度和模型规模进行实验。

#### 2. 复合奖励函数与惩罚项设计
 单一维度的奖励函数极易被利用。一个健壮的奖励体系通常包括：

 **主任务奖励**：衡量任务完成度(如正确性)。

 **长度惩罚**：对超出合理范围的回答施加显式惩罚，防止长度膨胀。DeepLearning.AI 的 GRPO 课程展示了一个有说服力的例子：在摘要生成任务中，如果仅用问答测验分数作为奖励，模型会发现直接复述原文即可获得满分，从而违背了"生成简洁摘要"的初衷。引入长度惩罚后，过长的回答即使测验分数高也会被降权。

 **格式奖励**：用较小权重奖励规范的输出格式(如正确使用 XML 标签)。

 **重复惩罚**：检测并惩罚输出中的重复片段。

 关键原则是 **量级平衡** ——确保各奖励分量的数值范围相互协调，避免某个分量主导整个优势计算。例如：
```text
def balanced_reward(completions, **kwargs):
    primary = calculate_correctness()      # 量级 ~1.0
    format_bonus = check_format() * 0.2    # 量级 ~0.2
    length_penalty = penalize_length() * 0.3
    return primary + format_bonus - length_penalty
```
#### 3. MO-GRPO：多目标场景的自动均衡
 针对多目标 GRPO 的偏科问题，Ichihara 等人提出了 MO-GRPO(Multi-Objective GRPO)。其核心思路非常简洁： **按各奖励函数值的方差对其进行归一化加权**，从而确保每个目标函数对损失函数的贡献大致均等。

 MO-GRPO 的优势在于：

 自动消除了不同奖励函数之间的量级差异，无需手动调参。

 在保持偏好排序不变的前提下实现了均衡优化。

 在机器翻译(WMT En-Ja、En-Zh)、指令遵循、模拟控制等四个领域的实验中，MO-GRPO 均优于原始 GRPO，实现了多个目标的稳定、均衡提升。

#### 4. BNPO：Beta 分布归一化
 Xiao 等人提出的 BNPO(Beta Normalization Policy Optimization)使用 Beta 分布对奖励进行自适应归一化，以提升训练稳定性和精度。相比 GRPO 的 z-score 归一化，Beta 分布归一化能更灵活地适应不同分布形态的奖励信号，在推理任务上表现优于 REINFORCE 和标准 GRPO。

#### 5. DAPO 的多管齐下策略
 DAPO(Decoupled Alignment and Policy Optimization)针对 GRPO 的多个痛点提出了一套系统性的改进：

 **解耦** **Clipping**：使用不同的上下限 clip 阈值(如 clip_high=0.28，clip_low=0.2)，缓解因上限 clipping 过严导致的探索受限。

 **过采样与过滤**：对准确率为 0 或 1 的样本进行过滤，避免梯度消失。通过过采样生成更多候选回答，然后保留那些具有信息量的样本参与训练。

 **仅基于结果的可验证奖励**：移除过程奖励模型(PRM)，仅使用最终结果的正确性作为奖励信号，从而减少奖励信号被利用的攻击面。

 **软长度惩罚**：设置一个缓存长度阈值(如 4096 token)，对超过该阈值的回答施加软惩罚，而非硬截断。

#### 6. 可验证奖励(Verifiable Rewards)
 相比于从人类偏好数据中训练出的奖励模型，可验证奖励(如数学题的标准答案匹配、代码的单元测试通过率)被认为更不容易被利用。DeepSeek-R1 的成功很大程度上得益于在数学和编程领域使用了这类明确、客观的奖励信号。

 但可验证奖励也并非万能。在低正则化条件下，模型仍然可能发生 reward hacking。例如在代码任务中，模型可能学会修改测试用例而非改进代码来通过测试。因此，可验证奖励的设计同样需要仔细考虑潜在的利用路径。

#### 7. LLM-as-a-Judge 补充评估
 使用另一个强大的 LLM 作为评判者，可以捕获规则型奖励无法覆盖的语义层面问题。例如，为回答的连贯性、事实准确性和信息含量提供评分。这种方法可以作为规则奖励的补充，帮助检测内容质量的退化。

 不过需要注意的是，LLM Judge 本身也可能引入偏差(如偏好更长、更华丽的回答)，因此仍需与其他信号组合使用。

#### 8. 训练工程层面的最佳实践
 除算法改进外，以下工程实践也对缓解 reward hacking 至关重要：

 **使用更大的基座模型**：更大的模型拥有更强的指令遵循能力，不易退化为无意义输出。

 **精心设计 System Prompt**：清晰的系统提示可以约束模型的输出空间。

 **合理设置** **max_completion_length**：避免过大的生成长度上限给模型提供"注水"的空间。

 **监控训练曲线**：持续关注 reward 、 reward_std 、 kl 和 entropy 等指标。当 reward_std 趋近于零或 entropy 急剧下降时，往往意味着 reward hacking 或熵坍缩正在发生。

 **渐进式训练**：先在较简单的任务上训练，再逐步增加难度，让模型建立稳健的基础能力。

### 总结
 Reward hacking 并非 GRPO 独有的问题，但 GRPO 的 z-score 优势计算方式、对奖励函数质量的高度依赖、以及在多目标场景下的量级敏感性，使其在实践中尤其容易触发各类奖励破解行为。

 好消息是，社区已经发展出一系列有效的应对策略，从简单的 KL 惩罚和复合奖励设计，到 MO-GRPO 的自动均衡归一化、DAPO 的系统性改进，再到可验证奖励与 LLM Judge 的组合使用。没有一种方法是银弹， **真正有效的方案通常是多种策略的组合** ——精心设计奖励函数、合理设置训练超参数、持续监控训练动态，并在发现异常时及时干预。

 随着 RL for LLM 领域的快速发展，我们有理由期待更多从根本上缓解 reward hacking 的算法创新。但在此之前，深入理解问题的本质并善用现有工具，仍然是每个 GRPO 实践者的必修课。

