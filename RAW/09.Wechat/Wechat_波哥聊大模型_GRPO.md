---
title: "为什么用 GRPO 训练 Reward Model?——从数学推理到偏好建模的范式迁移"
source: "https://mp.weixin.qq.com/s/N7lNtBgl8dDRaMDJqByYAA"
author:
  - "波哥聊大模型"
published:
created: 2026-05-07
description: "最近很多训练营的同学发现，面试官经常问\x26quot;GRPO 不是用来做数学题的吗?为什么你们拿它训 RM?\x26quot;。"
tags:
  - "clippings"
---
波哥 *2026年5月3日 21:24*

**我是** **波哥** **，专注于大模型/推荐系统，持续分享AI算法岗面试岗知识干货、实战项目、面试经验。**

**【大模型LLM训练营】、【大模型算法冲刺营】持续进行中，详细内容： **[大模型1v1第5期已经开始直播了！](https://mp.weixin.qq.com/s?__biz=MzkzOTg2ODE2Ng==&mid=2247489219&idx=2&sn=0ba5ddca04a7fced65bd7c97e05a394f&scene=21#wechat_redirect)****

****详情**** **了解可+v** **：** **Burger\_AI**

---

> 当面试官问"GRPO 不是用来做数学题的吗?为什么你们拿它训 RM?"——这个问题背后,是 RLHF 范式正在发生的一次深层变革。

## 一、问题的起点:一个看似矛盾的选择

GRPO(Group Relative Policy Optimization)最早在 DeepSeekMath 中被提出,并在 DeepSeek-R1 的训练中大放异彩。它的标志性应用场景是 **带可验证奖励的数学/代码推理任务** ——答案对就是 1,答案错就是 0,规则清晰、信号干净。

那么一个自然的疑问就出现了:

**Reward Model 的训练,本质上是一个偏好建模问题(给定 prompt 和两个 response,判断哪个更好)。这听起来更像是一个分类/回归问题,为什么要用一个为"数学推理"设计的** **RL** **算法去训练它?**

要回答这个问题,我们需要先打破两个误解:

1. **误解一**:GRPO 是"数学算法"。其实 GRPO 只是 PPO 的一个变体,它的核心创新与数学无关。
2. **误解二**:RM 是"打分器"。现代 RM 早已不是一个吐 scalar 的小模型,而是一个会"思考"的 Generative Reward Model(GenRM)。

把这两个误解同时拆掉,答案就显而易见了:**当** **RM** **从"判别式打分器"演化为"生成式判官(LLM-as-a-Judge)",它训练自己的过程就和训练一个推理模型本质同构——而 GRPO 正是当前训练推理模型的最优解之一。**

下面我们一层一层剥开来看。

![img](https://mmbiz.qpic.cn/mmbiz_png/kSX2Q9RM8CSnPEWcNQNLibiaDGrFAYZqWv0ILvU97ibgQviapXx4IlYCTAE3Wb9GBHiaggAVaA8Z7Y0LfnHs1eYp9U50JfHOqQPRc4DYrX7mfU6E/640?wx_fmt=png&from=appmsg&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=0)

## 二、回到第一性原理:GRPO 到底在做什么

### 2.1 PPO 的痛点

经典的 RLHF 用 PPO,它的目标函数(简化版)是:

其中 advantage

由一个 **独立训练的 value network** (critic)估计:![img](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

PPO 的麻烦在于:

- 需要额外维护一个和 policy 同等规模的 critic,显存翻倍
- Critic 的训练本身不稳定,误差会传到 advantage 估计
- 对 reward 噪声极其敏感

### 2.2 GRPO 的核心改动

GRPO 的做法非常朴素粗暴:**不要 critic,用一组样本的相对得分代替 value baseline** 。

对每个 prompt

,采样一组 个回答,每个回答打个分,然后:

就这么简单。Advantage 不是从 value network 学出来的,而是 **组内\*\*\*\*归一化** 得出的相对优势。比组内平均好的,advantage 为正;比平均差的,为负。

这个改动看似只是"省了一个 critic",但它带来了三个深刻的性质,而 **这三个性质恰恰是把 GRPO 用到** **RM** **训练上的根本原因**:

1. **绝对 reward 的尺度无关性**:只要组内相对顺序对,advantage 就有意义。这意味着 reward 可以是嘈杂的、未校准的、甚至是非数值的(只要能排序)。
2. **对稀疏 reward 友好**:即使大部分 reward 是 0,只要组内有差异,梯度就能流动。
3. **天然适合"过程对、结果对"都重要的任务**:因为同一个 prompt 下采多条轨迹,可以暴露出"思路不同但都正确"或"思路相似但答案错误"的对比。

## 三、Reward Model 的进化:从 Scalar Head 到 Generative Judge

![img](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

### 3.1 传统 RM 的局限

传统 RM(Bradley-Terry RM)的训练目标是:

![img](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

模型在 LLM 顶上加一个 scalar head,输出一个标量分数。

但这种 RM 有几个臭名昭著的问题:

- **校准差**:同一个分数在不同 prompt 下含义不同
- **不可解释**:给了 6.3 分,问它为啥?它说不出来
- **泛化弱**:换一个领域,scalar head 的判断就崩了
- **没法 scale test-time compute**:LLM 思考越久越聪明,但 scalar RM 只能 forward 一次

### 3.2 Generative Reward Model 的兴起

新一代 RM 的思路完全不同—— **让 RM 像一个真正的判官那样,先思考、再下结论** 。

具体形式有两种:

**Pointwise** **GenRM**:

```
Input: <prompt> <response>
Output: <reasoning chain> ... 综上,我给这个回答打 8 分。
```

**Pairwise GenRM**:

```
Input: <prompt> <response A> <response B>
Output: <分析 A> <分析 B> <对比> ... 因此 Response A 更好。
```

像 RM-R1、J1、Think-J、EvalPlanner 这些 2025 年的工作,本质上都是把 RM 训练成一个 **专门用于评判的 reasoner** 。RM-R1 在 RewardBench 上甚至能用 7B 模型超过 GPT-4o。

**关键的认知转变**:RM 不再是"打分器",它是一个 **专门做评估推理的** **LLM** 。它要思考评判标准、对比候选答案、给出有理有据的判断。

## 四、范式同构:为什么 GRPO 是训练 GenRM 的最优选

到这里,核心论点终于可以亮出来了。

如果 GenRM 的本质是"让 LLM 学会更准确地做评判推理",那么训练它的过程和训练一个数学推理模型在结构上完全同构:

| 维度 | 数学推理模型 | Generative RM |
| --- | --- | --- |
| 输入 | 数学题 | prompt + 候选回答 |
| 中间过程 | 解题思维链 | 评判思维链 |
| 最终输出 | 答案 | 偏好判断 / 分数 |
| Reward 信号 | 答案对不对(规则可验证) | 判断是否符合人类偏好(数据集标注) |
| 难点 | 思维链能不能引导出对的答案 | 评判推理能不能得出对的偏好 |

最右一列每一行,都可以从最左列对应位置"翻译"过来。这就是为什么 DeepSeek-R1 那套 GRPO 训练范式可以 **几乎不加改动地** 搬到 RM 训练上来。

更具体地说,GRPO 在 GenRM 训练中带来了四个无法替代的优势:

### 4.1 把"偏好对"天然转换为可验证 reward

GenRM 训练数据通常长这样:`(prompt, response_A, response_B, label)`,其中 label 是人类标注的偏好。

把它喂给 GenRM,让 GenRM 输出"我认为 A 更好/B 更好",然后 **判断 GenRM 的最终结论是否和 label 一致** ——一致 reward = 1,不一致 reward = 0。

这就把一个看似主观的偏好建模问题,**转化为了和数学题一模一样的可验证 reward 任务** 。GRPO 在这种场景下天然适配,这也是为什么 J1、RM-R1 等工作不约而同选择了 GRPO。

### 4.2 组内对比正好契合 RM 训练数据结构

回想 GRPO 的采样:对一个 prompt 采 G 条回答。

而 RM 的训练数据本来就是"对同一个 prompt 的多个回答做对比"。两者的数据组织方式 **完全咬合** ——同一组 prompt 下 GenRM 生成多条不同的"评判推理轨迹",有的判对了(reward=1),有的判错了(reward=0),GRPO 用组内 advantage 自动学到"什么样的评判思维链更可能给出正确判断"。

如果用 PPO,你需要再训练一个 critic 来估计 GenRM 在每个评判 token 的 value——这既荒谬又低效。

### 4.3 缓解 RM 训练中的尺度问题

传统 BT-RM 训练有个老问题:模型容易学到"打高分都打高,打低分都打低"的偷懒模式。GRPO 的组内归一化天然消除了 reward 的绝对尺度,**只保留相对顺序信号**,逼着模型学习真正的判别能力,而不是 reward 的均值。

### 4.4 让 RM 在 test-time 也能 scale

这是最被低估的一点。

传统 scalar RM 推理时一次 forward 完事,test-time compute 没法 scale。但 GRPO 训练出来的 GenRM 可以:

- 同一 prompt 采多条评判推理,投票选最一致的判断(self-consistency)
- 用更长的思维链(longer CoT)拿到更准的判断
- 在线生成"评判 rubric"再做评估

这意味着 GenRM 继承了 LLM 推理模型的所有 test-time scaling 红利,而这正是 GRPO 训练范式的副产物。

## 五、一个具体的训练流程

把上面的理论落地,一个典型的"用 GRPO 训 GenRM"的 pipeline 是这样:

**阶段 1:冷启动** **SFT** 用一批高质量的"评判思维链"数据(可以是从 GPT-4 蒸馏的,或人工写的)做 SFT,让模型先学会"评判应该长什么样"。这一步对应 R1 的 cold-start。

**阶段 2:GRPO 训练**

```
For each step:
  1. 从偏好数据中采一个 batch: (prompt, response_A, response_B, label)
  2. 对每个样本,让当前 GenRM 采样 G 条评判推理(temperature > 0)
  3. 解析每条推理的最终结论,与 label 对比,计算 reward ∈ {0, 1}
  4. 组内归一化得到 advantage
  5. GRPO 目标函数更新参数
  6.(可选)加格式 reward:输出格式不合规则扣分
```

**阶段 3(可选):reward shaping** 加入辅助 reward,比如:

- 一致性 reward:多次采样结论一致的奖励
- 校准 reward:对置信度的校准
- 长度惩罚:防止 CoT 过长

ms-swift 框架在 2025 年 5 月已经原生支持这套流程,可以直接用 `--rlhf_type grpo --reward_model_plugin genrm` 跑起来。

## 六、几个值得警惕的坑

理论虽美,工程实践有自己的现实主义。把 GRPO 用在 RM 训练上,以下几个坑必须留意:

**坑 1:Reward Hacking 在元层面的复发**

讽刺的是,你在用 GenRM 防 policy 的 reward hacking,但 GenRM 自己也会 hack 它的训练 reward。比如学会"无脑判 A 更好,因为训练集里 A 略多"。Cooper 等工作通过 co-optimize policy 和 RM 缓解这个问题。

**坑 2:Group Size 的两难**

G 太小,advantage 估计噪声大;G 太大,显存吃不消、采样慢。一般 G ∈ \[4, 16\],但对 GenRM 评判任务,因为 reward 二值化,**实践经验是 G 至少要 8** 才能保证一组内既有正例也有负例(否则 advantage 全是 0,梯度消失)。

**坑 3:KL 惩罚的双刃剑**

GRPO 默认带 KL 惩罚把模型拉回 reference。但 GenRM 训练时,过强的 KL 会限制评判推理的探索空间,让模型不敢生成长 CoT;过弱又会忘掉语言建模能力。需要细调

。

**坑 4:格式崩坏**

GenRM 必须在结尾输出可解析的判断(如 `[[A]]` 或 `Answer: 8`)。训练初期模型容易"忘了画句号",reward 解析失败。一定要加 **格式 reward 兜底** 。

## 七、更深的一层:这反映了什么趋势?

把视角拉远,GRPO 训 RM 这件事不是一个孤立的 trick,它是 2024-2025 年 LLM 领域两个深层趋势的交汇:

**趋势一:一切皆为推理(Everything is Reasoning)**

从 OpenAI o1、DeepSeek-R1 开始,业界发现"在输出前先思考"几乎可以提升任何任务的表现。RM 评判、Agent 规划、代码 review、数学解题——只要任务本身有"该怎么做才对"的判断,加上 CoT 都会变好。RM 当然也不例外。

**趋势二:RL算法的统一**

PPO、DPO、GRPO、Reinforce++ 等算法看起来五花八门,但 2025 年大家逐渐意识到:**只要你的任务能被写成"采样多个候选 → 给出可验证 reward → 用 advantage 更新 policy",GRPO 几乎都能用,而且通常是最简单的那个** 。这种"用一把锤子敲所有钉子"的能力,正是 GRPO 攻占 RM 训练的根本原因。

把这两个趋势叠加,你会发现:

> **训练** **RM** **和训练数学推理模型,在 2026 年的视角下,根本就是同一件事。**

它们的输入不同、reward 来源不同,但目标都是"让 LLM 学会输出某种'对'的推理链"。GRPO 是为这个目标量身定做的算法,所以它能跨任务通用,毫不奇怪。

## 八、结语

回到开头那个问题:"GRPO 不是用来做数学题的吗,为什么你们拿它训 RM?"

完整的答案应该是:

> GRPO 从来就不是"数学算法",它是一个 **为可验证 reward + 推理生成** 设计的通用 RL 框架。当 RM 从 scalar head 演化为 Generative Reward Model,它的训练目标恰好满足 GRPO 的两个前提:可验证(判断对/错)+ 推理生成(评判思维链)。所以这不是"借用",而是 **结构 ****同构**** 带来的必然选择** 。

更进一步,这件事提醒我们一个更朴素的道理:

**当算法和任务的数学结构对得上时,效果就是好。当对不上时,加再多技巧也是缝补。** ——这或许是 RLHF 这一波折腾给我们留下的最有价值的一条经验。

### 参考资料

- DeepSeekMath / DeepSeek-R1: GRPO 原始论文
- Generative Reward Models (Mahan et al., 2024): GenRM 的奠基工作
- RM-R1 (2025): Reward Modeling as Reasoning,首次系统用 RL 训练推理型 RM
- J1 (Meta, 2025): Incentivizing Thinking in LLM-as-a-Judge via RL
- Think-J (2025): GRPO 在 RM 训练上的对比实验,显示其优于 PPO/DPO/Reinforce++
- Cooper (2025): Co-Optimizing Policy and Reward Models
- ms-swift 框架文档:GRPO + GenRMPlugin 的开源实现

---
