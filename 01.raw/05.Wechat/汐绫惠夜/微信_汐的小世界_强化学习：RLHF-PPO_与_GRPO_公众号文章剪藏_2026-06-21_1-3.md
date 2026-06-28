---
title: "微信_汐的小世界_强化学习：RLHF-PPO 与 GRPO_公众号文章剪藏_2026-06-21_1-3"
source: "/api/v1/wechat_mp/web/fetch_mp_article_detail_json"
author:
  - "汐的小世界"
published: "2026-06-21"
created: 2026-06-21
description: "TikHub 命中的微信公众号文章候选，共 3 条，本文档收录 3 条"
tags:
  - "clippings"
  - "wechat"
  - "汐的小世界"
---

## 0x01. 十五：强化学习：RLHF-PPO 与 GRPO
> 发布日期：2026-06-21  
> 原文链接：[十五：强化学习：RLHF-PPO 与 GRPO](https://mp.weixin.qq.com/s/okp_rDtBYXl75L7Hp4qYmQ)

### 1. 学习定位
第十四天学习了传统 PPO。第十五天把 PPO 放到大语言模型 RLHF 中，重点掌握 RLHF-PPO 的完整数据流、损失结构、KL 约束、value head、reward model，以及 GRPO 与 PPO 的差异。

本日知识链路：

RLHF-PPO 和 GRPO 都是面试高频内容。面试中通常会追问：为什么需要 reference model，KL penalty 怎么算，reward model 只给序列奖励时如何分配到 token，value head 的作用是什么，PPO ratio 在 LLM 中对应什么，以及 GRPO 为什么能省掉 critic。

### 2. RLHF-PPO 的组件
典型 RLHF-PPO 包含四类模型或模块：

训练数据通常是 prompt 集合。policy 对每个 prompt 生成 response，reward model 对完整 response 打分，PPO 根据 reward 和 KL 惩罚更新 policy。

### 3. RLHF-PPO 数据流
完整流程：

在 LLM 中，一条 response 是 token-level trajectory：

### 4. RLHF 中的奖励结构
Reward model 通常对完整回答给一个标量：

但PPO 需要 token-level reward/advantage。常见做法是：
(1)基础定义

t：生成的第t个token(逐token时间步)

KL_t：当前策略模型pi_theta与参考模型ref在第t个 token 上的 KL 散度

β：KL惩罚系数(超参数，控制探索幅度)
(2)逐token奖励计算

1、如果不是最后一个token，只给KL惩罚奖励(负奖励，约束模型不要乱更新)

2、如果是最后一个token，给KL惩罚+完整的RM标量分数(把整段回答的质量奖励，全部加在最后一步)：

其中 KL 惩罚让 policy 不要偏离 reference model 太远。

序列级的总奖励就是把所有token的奖励求和：

总目标直觉：

最大化「回答质量分数」 - 「偏离原模型的惩罚」

补充：优势函数(Advantage)为什么也是逐 Token？

PPO 核心用优势函数A_t 更新策略，而不是原始奖励：

因为我们已经把奖励拆成了逐 Token，优势函数自然也是逐 Token，完美适配 PPO 的更新逻辑。

这意味着，最后一个 token 的巨大奖励(蕴含在A_last中)，会按比例衰减，一步步倒推回溯给倒数第二个、倒数第三个……直到第一个 token。

### 5. KL Penalty
标准的KL散度定义是对整个词表进行求和：

但是LLM词表巨大(几万～十几万)，逐轮求和计算量爆炸，根本没法训练。

LLM RLHF 中常用 sampled token 上的 KL 采样近似，直接用模型实际生成的那个 token来近似整段 KL 散度：

beta控制约束强度：

太小：模型可能偏离 reference，出现 reward hacking 或语言质量下降。
太大：模型几乎不敢改变，reward 难以上升。
工程中也会动态调节 KL 系数，让实际 KL 接近目标范围。

### 6. PPO Ratio 在 LLM 中的含义
对每个生成 token：

PPO token-level policy loss：

只对 response token 计算 loss，不对 prompt token 计算 RL loss。因此必须使用 response mask。

### 7. Value Head 与 Advantage
RLHF-PPO 通常在语言模型上加 value head：

Value head 的作用：

估计每个生成位置的未来回报。
作为 baseline 降低策略梯度方差。
用于计算 advantage 和 return。
常见 advantage 估计：

在 LLM 中，episode 是一个 response 序列，终止 token 后不再 bootstrap。

### 8. RLHF-PPO 的总损失
常见总损失：

policy loss：

value loss：

有些实现使用 value clipping，减少 critic 变化过大。

注意：KL penalty 通常进入 reward，而不是直接作为 policy loss 的单独项；也有实现把 KL 当作额外 loss 或监控指标。

### 9. Mask 与 Padding
LLM batch 中 response 长度不同，需要 padding。训练时必须区分：

常见 mask：

attention mask：控制模型注意力和有效 token。
response mask：只选中回答部分。
loss mask：排除 padding 和无效位置。
mask 错误会导致 prompt token 被错误优化，或 padding token 影响 KL/value/loss。

### 10. RLHF-PPO 的工程风险
常见风险：

- reward hacking：模型利用 reward model 漏洞。
- KL collapse：KL 太小导致学习停滞，或 KL 太大导致语言质量崩坏。
- length bias：reward model 偏好长答案或短答案。
value head 不准：advantage 噪声大。
padding/mask 错误：loss 计算污染。
- old logp 与 new logp 不匹配：ratio 错误。
reward scale 不稳定：PPO 更新震荡。
response 采样策略变化：数据分布快速漂移。
### 11. RLHF-PPO 与传统 PPO 的差异
传统 PPO：

RLHF-PPO：

核心 PPO ratio/clip 仍然存在，但训练对象和奖励结构更复杂。

### 12. GRPO 的动机
GRPO(Group Relative Policy Optimization)是大模型 RL 中常见的 PPO 变体。它的核心动机是减少 PPO 中 value model/critic 的成本和不稳定性。

PPO 需要：

GRPO 通常不训练额外 critic，而是对同一个 prompt 采样一组回答，用组内 reward 的相对归一化构造 advantage。

### 13. GRPO 的组内相对优势
对同一个 prompt，采样G个回答：

组内归一化 advantage：

这样不需要训练 value head 来估计 baseline。

### 14. GRPO 的目标函数
GRPO 仍然使用类似 PPO 的 ratio clipping：

目标可理解为：

简化写法：

其中A_i对同一回答的 token 共享，或按实现分配到 response token 上。

### 15. GRPO 与 PPO 的核心差异
| 维度 | RLHF-PPO | GRPO |
| --- | --- | --- |
| Baseline 来源 | 离线训练 Value Head 预测状态价值 V(s_t) | 同 prompt 一组采样答案的奖励均值 |
| Advantage 计算 | 单序列逐 token TD+GAE 时序平滑，A_t 逐位置不同 | 整段回答共用同一个标准化优势，同答所有 token 共享 A |
| 模型组件 | Policy + Ref + RM + Value(Critic) 四套 | Policy + Ref + RM，无 Critic/Value Head |
| 训练成本 | 额外优化 Value Loss、调试 value_coef，参数量和计算量大 | 省去 Critic 反向传播，显存、迭代开销更低 |
| 优势适用逻辑 | 依赖单条序列时序回报，不需要同 prompt 多采样 | 强制单 prompt 采样 G>=2 条回答，依托组间相对排序 |
| 主要风险 | Critic 拟合偏差、价值震荡、value loss 难调 | 每组样本过少时 std 趋近 0、归一化爆炸；组内奖励全同导致 A 全部为 0 无法更新 |
| 奖励形式 | 支持逐 token 奖励 + 末尾序列打分结合 | 仅使用全句序列级标量奖励，不拆分 token reward |

GRPO 是保留 PPO 的 ratio/clip/KL 思想，用组内相对 reward 替代 critic advantage。

### 16. GRPO 与 DeepSeek-R1
DeepSeek 系列工作中，GRPO 被用于大模型数学推理和推理能力强化。其关键思想是：对同一个问题采样多条解答，根据规则奖励或模型奖励得到组内相对信号，优化模型生成更高质量推理轨迹。

在推理任务中，奖励可来自：

答案是否正确。
格式是否满足要求。
推理过程是否符合规则。
代码或数学验证结果。
GRPO 适合这类场景，是因为同一题目可以采样多个候选解，候选之间可比较，且不一定需要单独训练 value model。

### 17. KL 散度估计
常见 KL 相关量：

真实前向 KL：

在采样 token 上可以估计：

一些实现会使用更稳定的非负近似或二阶近似，例如基于 log ratio 的近似 KL。无论形式如何，工程目的都是监控或惩罚 policy 偏离 reference。

需要注意：不同代码库对 KL 的方向、符号和估计形式可能不同，读代码时必须确认 log ratio 的定义。

### 18. RLHF-PPO 与 GRPO 的选型
RLHF-PPO 适合：

- 需要精细 token-level value 估计。
奖励结构复杂。
有成熟 PPO/TRL 基础设施。
GRPO 适合：

同一 prompt 可生成多个候选。
reward 可直接比较候选优劣。
希望省掉 critic/value model。
数学、代码、推理等可验证任务。
GRPO 的代价是每个 prompt 需要多样本生成，组大小会增加采样成本。

### 19. 常见误区
误区一：RLHF-PPO 中 KL 只是监控指标。 KL 通常进入 reward 或 loss，直接影响优化目标。

误区二：value head 输出的是 reward model 分数。 value head 预测未来回报，reward model 给完整回答打偏好分。

误区三：GRPO 完全不需要 baseline。 GRPO 使用组内均值和标准差构造相对 baseline，只是不训练 critic。

误区四：GRPO 只适用于 DeepSeek。 GRPO 是一种算法思想，适用于能对同 prompt 多候选打分的 LLM RL 场景。

误区五：KL 方向无所谓。 不同 KL 方向会影响优化行为。工程实现必须确认符号和采样分布。

### 20. 核心总结
第十五天需要掌握的最小闭环：

### 21. 参考资料
- 知乎：DeepSeek R1 用到的 GRPO 详解：https://zhuanlan.zhihu.com/p/15922703850
- 知乎：KL 散度估计：https://zhuanlan.zhihu.com/p/25208314999
- DeepSeekMath: Pushing the Limits of Mathematical Reasoning in Open Language Models：https://arxiv.org/abs/2402.03300
- DeepSeek-R1: Incentivizing Reasoning Capability in LLMs via Reinforcement Learning：https://arxiv.org/abs/2501.12948
- PPO 原论文：https://arxiv.org/abs/1707.06347
- Deep Reinforcement Learning from Human Preferences：https://arxiv.org/abs/1706.03741
- Training language models to follow instructions with human feedback：https://arxiv.org/abs/2203.02155
- Hugging Face TRL PPOTrainer 文档：https://huggingface.co/docs/trl/

## 0x02. 十五：强化学习：RLHF-PPO 与 GRPO自测题
> 发布日期：2026-06-05  
> 原文链接：[十五：强化学习：RLHF-PPO 与 GRPO自测题](https://mp.weixin.qq.com/s/qjqYgIT9N8xLcnz48LlaqA)

### 覆盖范围
 RLHF-PPO 的组件和数据流

 policy/reference/reward/value head 的作用

 token-level PPO ratio、KL penalty、reward shaping

 value head、advantage、mask、padding

 RLHF-PPO 工程风险与排错

 GRPO 的组内相对优势、目标函数和适用场景

 GRPO 与 PPO/RLHF-PPO 的系统对比

### 一、RLHF-PPO 总体框架
 RLHF-PPO 中通常包含哪些模型或模块？

 Policy model 在 RLHF-PPO 中负责什么？

 Reference model 在 RLHF-PPO 中负责什么？

 Reward model 在 RLHF-PPO 中负责什么？

 Value head 在 RLHF-PPO 中负责什么？

 RLHF-PPO 为什么通常从 SFT 模型初始化？

 请描述 RLHF-PPO 从 prompt 到参数更新的完整数据流。

 RLHF-PPO 和传统 PPO 的最大场景差异是什么？

### 二、奖励、KL 与 Token-level PPO
 RLHF 中 reward model 通常对什么内容打分？

 如果 reward model 只输出 sequence-level score，如何用于 token-level PPO？

 RLHF-PPO 的总奖励直觉上可以写成什么目标？

 KL penalty 为什么重要？

 sampled token 上的 KL 近似通常如何计算？

 KL 系数 beta 太大或太小分别会怎样？

 PPO ratio 在 LLM token 级别如何定义？

 为什么必须保存 old log probability？

 请写出 RLHF-PPO 的 token-level clipped policy objective。

 为什么 PPO loss 通常只计算 response tokens？

### 三、Value、Advantage 与 Mask
 Value head 的输入和输出分别是什么？

 Value head 和 reward model 有什么区别？

 RLHF-PPO 中 advantage 可以如何计算？

 GAE 在 LLM response 序列中如何处理终止位置？

 Response mask 为什么重要？

 Padding token 如果参与 loss 会造成什么问题？

 Prompt token 如果参与 policy loss 会造成什么问题？

 Attention mask、response mask、loss mask 分别有什么作用？

 为什么 advantage normalization 在 RLHF-PPO 中常见？

 Value clipping 在 RLHF-PPO 中解决什么问题？

### 四、RLHF-PPO 工程风险
 什么是 reward hacking？在 RLHF-PPO 中如何出现？

 什么是 length bias？为什么 reward model 可能引入它？

 KL 过大通常说明什么？

 KL 过小但 reward 不升可能说明什么？

 如果 ratio 大量超出 clip range，可能是什么问题？

 如果 value loss 很大，应该排查什么？

 old logp 和 new logp 不匹配会导致什么后果？

 为什么 RLHF-PPO 的 batch 构造比传统 PPO 更复杂？

 RLHF-PPO 中生成温度会影响什么？

 为什么 RLHF-PPO 需要独立评估而不能只看 reward model 分数？

### 五、GRPO 基础
 GRPO 的全称是什么？

 GRPO 想解决 RLHF-PPO 中的什么问题？

 GRPO 为什么可以不训练 value model 或 critic？

 GRPO 对同一个 prompt 通常会采样什么？

 请写出 GRPO 组内相对 advantage 的常见形式。

 GRPO 中组内均值起什么作用？

 GRPO 中组内标准差归一化起什么作用？

 如果同一组回答 reward 方差接近 0，会有什么问题？

 GRPO 是否仍然使用 PPO-style ratio clipping？

 GRPO 是否仍然需要 KL 正则？为什么？

### 六、GRPO 与 PPO 对比
 RLHF-PPO 和 GRPO 在 baseline 上有什么区别？

 RLHF-PPO 和 GRPO 在模型组件上有什么区别？

 RLHF-PPO 和 GRPO 在显存和计算成本上有什么差异？

 GRPO 的 group size 会影响什么？

 GRPO 为什么适合数学推理或代码任务？

 GRPO 相比 PPO 的主要风险是什么？

 GRPO 和 REINFORCE with baseline 有什么联系？

 GRPO 中同一个回答的 advantage 是否一定逐 token 不同？

### 七、DeepSeek-R1 与 KL 估计
 DeepSeek-R1/DeepSeekMath 场景中，GRPO 的奖励可以来自哪些信号？

 为什么可验证任务特别适合 GRPO？

 什么是 KL(pi || ref) 的基本定义？

 在 sampled action 上估计 KL 时， logp_policy - logp_ref 表示什么？

 为什么不同代码库的 KL 符号和方向必须仔细检查？

 KL penalty 和 PPO clipping 分别限制什么？

 GRPO 中如果 KL 系数太小，会有什么风险？

 GRPO 中如果 KL 系数太大，会有什么风险？

### 八、综合设计与面试追问
 请画出或描述 RLHF-PPO 的完整训练流程图。

 请画出或描述 GRPO 的完整训练流程图。

 如果要把 RLHF-PPO 改成 GRPO，需要删除和新增哪些步骤？

 如果 reward model 偏好长答案，PPO 和 GRPO 分别可能学到什么坏行为？

 在大模型 RL 中，为什么“奖励上升”不一定代表真实能力上升？

 请完整比较 SFT、DPO、RLHF-PPO、GRPO 的数据形式、训练目标、优缺点和适用场景。

## 0x03. 十五：强化学习：RLHF-PPO 与 GRPO自测题答案
> 发布日期：2026-06-21  
> 原文链接：[十五：强化学习：RLHF-PPO 与 GRPO自测题答案](https://mp.weixin.qq.com/s/he6T-UNuXfWURNR7Y601GA)

参考资料

- 知乎：DeepSeek R1 用到的 GRPO 详解：https://zhuanlan.zhihu.com/p/15922703850
- 知乎：KL 散度估计：https://zhuanlan.zhihu.com/p/25208314999
- DeepSeekMath: Pushing the Limits of Mathematical Reasoning in Open Language Models：https://arxiv.org/abs/2402.03300
- DeepSeek-R1: Incentivizing Reasoning Capability in LLMs via Reinforcement Learning：https://arxiv.org/abs/2501.12948
- PPO 原论文：https://arxiv.org/abs/1707.06347
- Deep Reinforcement Learning from Human Preferences：https://arxiv.org/abs/1706.03741
- Training language models to follow instructions with human feedback：https://arxiv.org/abs/2203.02155
- Hugging Face TRL PPOTrainer 文档：https://huggingface.co/docs/trl/
评分标准

- 合格：能说清 RLHF-PPO 的四个核心组件、KL penalty、PPO ratio、GRPO 组内 advantage。
- 良好：能解释 value head、reward shaping、mask、padding、GRPO 去 critic 的动机和 PPO/GRPO 差异。
- 优秀：能从 DeepSeek-R1/可验证奖励、KL 估计、reward hacking、length bias 和算法选型角度完整回答。
### 一、RLHF-PPO 总体框架
#### 1. RLHF-PPO 中通常包含哪些模型或模块？
通常包含 policy model、reference model、reward model、value head/critic。policy 被训练，reference 和 reward model 多数冻结，value head 随 policy 训练。

#### 2. Policy model 在 RLHF-PPO 中负责什么？
Policy model 是待优化的语言模型，负责根据 prompt 生成 response，并输出每个 token 的 log probability。

#### 3. Reference model 在 RLHF-PPO 中负责什么？
Reference model 通常是冻结 SFT 模型，用来计算 KL 约束，防止 policy 偏离原有语言能力和安全行为太远。

#### 4. Reward model 在 RLHF-PPO 中负责什么？
Reward model 对 prompt + response 输出标量偏好分数，作为 RL 优化的主要奖励信号。

#### 5. Value head 在 RLHF-PPO 中负责什么？
Value head 估计每个 token 位置的未来回报，作为 baseline 计算 advantage，降低策略梯度方差。

#### 6. RLHF-PPO 为什么通常从 SFT 模型初始化？
SFT 模型已经具备基本指令遵循和语言能力，能减少 RL 搜索难度，避免从随机策略开始探索巨大 token 空间。

#### 7. 请描述 RLHF-PPO 从 prompt 到参数更新的完整数据流。
采样 prompt；policy 生成 response 并保存 old logp；reference 计算 ref logp；reward model 打分；计算 KL penalty 和 token reward；value head 预测 values；计算 advantage/returns；用 PPO clipped loss 更新 policy 和 value head。

#### 8. RLHF-PPO 和传统 PPO 的最大场景差异是什么？
RLHF-PPO 的 action 是 token，reward 多为完整序列偏好分数，还需要 reference KL、mask、padding 和大模型生成成本；传统 PPO 通常面对较小动作空间和环境奖励。

### 二、奖励、KL 与 Token-level PPO
#### 9. RLHF 中 reward model 通常对什么内容打分？
通常对完整的 prompt + response 打一个标量分数，表示人类偏好、帮助性、安全性或任务质量。

#### 10. 如果 reward model 只输出 sequence-level score，如何用于 token-level PPO？
常见做法是把 KL penalty 分配到每个 token，把 reward model score 加到最后一个有效 response token 上，形成 token-level rewards。

#### 11. RLHF-PPO 的总奖励直觉上可以写成什么目标？
最大化“回答质量分数”减去“偏离 reference model 的 KL 惩罚”：
```text
reward = reward_model_score - beta * KL(policy || reference)
```

#### 12. KL penalty 为什么重要？
它限制 policy 偏离 reference model，防止模型为了高 reward 牺牲语言质量、安全性和泛化能力。

#### 13. sampled token 上的 KL 近似通常如何计算？
常见估计：
```text
KL_t ≈ logp_policy(y_t | x, y_<t) - logp_ref(y_t | x, y_<t)
```

在 policy 采样的 token 上平均。

#### 14. KL 系数beta太大或太小分别会怎样？
太大导致策略几乎不能偏离 reference，学习弱。太小导致偏离过大、reward hacking、语言质量下降。

#### 15. PPO ratio 在 LLM token 级别如何定义？
```text
r_t(theta) = exp(logp_new(y_t) - logp_old(y_t))
```
其中 logp 对应同一个 response token。

#### 16. 为什么必须保存 old log probability？
PPO ratio 要比较新策略和采样时旧策略对同一 token 的概率。更新后无法重新得到旧策略概率，必须在 rollout 时保存。

#### 17. 请写出 RLHF-PPO 的 token-level clipped policy objective。
```text
L_clip = E_t[min(r_t A_t, clip(r_t, 1-epsilon, 1+epsilon) A_t)]
```
实际 loss 通常取负号最小化。

#### 18. 为什么 PPO loss 通常只计算 response tokens？
Prompt token 不是 policy 在当前 rollout 中生成的动作，不应被 RL loss 优化。只应对模型生成的 response token 计算 action loss。

### 三、Value、Advantage 与 Mask
#### 19. Value head 的输入和输出分别是什么？
输入通常是语言模型每个 token 的 hidden state，输出每个位置的标量 value。

#### 20. Value head 和 reward model 有什么区别？
Reward model 给完整回答打偏好分。Value head 预测当前 token 位置之后的未来回报，是 policy 训练时的 critic。

#### 21. RLHF-PPO 中 advantage 可以如何计算？
可以用 GAE：
```text
A_t = delta_t + gamma lambda delta_{t+1} + (gamma lambda)^2 delta_{t+2} + ...
```

#### 22. GAE 在 LLM response 序列中如何处理终止位置？
最后有效 token 之后不再 bootstrap，终止后的V_{t+1}置 0，并用 mask 排除 padding。

#### 23. Response mask 为什么重要？
它保证 policy/value/KL loss 只作用在生成回答部分，避免 prompt 和 padding 污染训练。

#### 24. Padding token 如果参与 loss 会造成什么问题？
模型会在无意义位置学习，KL、value 和 advantage 统计被污染，loss 尺度也会随 padding 长度变化。

#### 25. Prompt token 如果参与 policy loss 会造成什么问题？
会错误地把用户输入当成模型动作，优化模型去“生成 prompt”，导致梯度含义错误。

#### 26. Attention mask、response mask、loss mask 分别有什么作用？
attention mask 控制模型可见有效 token；response mask 标识回答部分；loss mask 决定哪些位置参与 RL loss，通常排除 prompt 和 padding。

#### 27. 为什么 advantage normalization 在 RLHF-PPO 中常见？
它稳定 advantage 尺度，减少 reward model 分数尺度变化对 PPO 更新强度的影响。

#### 28. Value clipping 在 RLHF-PPO 中解决什么问题？
限制 value head 单次更新幅度，防止 critic 剧烈变化导致 advantage/return 训练不稳定。

### 四、RLHF-PPO 工程风险
#### 29. 什么是 reward hacking？在 RLHF-PPO 中如何出现？
模型利用 reward model 漏洞获得高分，但输出不真正有帮助。例如生成冗长、套话、过度自信或格式投机内容。

#### 30. 什么是 length bias？为什么 reward model 可能引入它？
Length bias 是 reward model 系统性偏好更长或更短回答。偏好数据或模型特征如果把长度和质量混淆，就会引入该偏差。

#### 31. KL 过大通常说明什么？
policy 偏离 reference 太远，可能语言质量下降、过优化 reward、训练不稳定。应增大 beta、降低学习率或减小 PPO 更新。

#### 32. KL 过小但 reward 不升可能说明什么？
约束过强、beta 太大、学习率太低、advantage 太小或 reward 信号质量差，导致 policy 几乎没有有效更新。

#### 33. 如果 ratio 大量超出 clip range，可能是什么问题？
学习率过大、epoch 过多、old logp 不匹配、advantage 尺度过大或 batch 数据过旧。

#### 34. 如果 value loss 很大，应该排查什么？
排查 reward scale、returns 计算、mask、终止位置、value head 初始化、学习率和 value loss 系数。

#### 35. old logp 和 new logp 不匹配会导致什么后果？
ratio 错误，PPO clipping 失效，策略可能被错误方向更新，KL 和 loss 指标也会失真。

#### 36. 为什么 RLHF-PPO 的 batch 构造比传统 PPO 更复杂？
因为有变长文本、prompt/response 分区、padding、attention mask、response mask、reward model 打分、reference logp 和 value head 输出。

#### 37. RLHF-PPO 中生成温度会影响什么？
温度影响探索和 response 分布。温度高样本多样但噪声大，温度低探索不足，可能降低 reward 改进空间。

#### 38. 为什么 RLHF-PPO 需要独立评估而不能只看 reward model 分数？
reward model 可能被过优化或存在偏差。需要人工评估、任务指标、安全评估、事实性评估和长度/风格分析。

### 五、GRPO 基础
#### 39. GRPO 的全称是什么？
GRPO 是 Group Relative Policy Optimization，组相对策略优化。

#### 40. GRPO 想解决 RLHF-PPO 中的什么问题？
它希望省掉 value model/critic，降低显存和训练复杂度，同时避免 critic 不准带来的不稳定。

#### 41. GRPO 为什么可以不训练 value model 或 critic？
它对同一 prompt 采样多个回答，用组内 reward 均值作为 baseline，用组内相对分数构造 advantage。

#### 42. GRPO 对同一个 prompt 通常会采样什么？
采样一组候选回答或推理轨迹，例如G个 completions。

#### 43. 请写出 GRPO 组内相对 advantage 的常见形式。
```text
A_i = (r_i - mean(r_1, ..., r_G)) / (std(r_1, ..., r_G) + epsilon)
```

#### 44. GRPO 中组内均值起什么作用？
它作为同 prompt 的 baseline，让更新关注某个回答相对同题其他回答好不好。

#### 45. GRPO 中组内标准差归一化起什么作用？
标准化 reward 尺度，使不同 prompt 的 reward 差异更可比，稳定更新。

#### 46. 如果同一组回答 reward 方差接近 0，会有什么问题？
标准差太小会导致归一化不稳定，advantage 噪声大或无有效区分。实现中通常加 epsilon。

#### 47. GRPO 是否仍然使用 PPO-style ratio clipping？
通常使用。GRPO 保留 ratio clipping 来限制新旧策略变化。

#### 48. GRPO 是否仍然需要 KL 正则？为什么？
需要。没有 KL 约束时，policy 仍可能偏离 reference，出现语言质量下降和 reward hacking。

### 六、GRPO 与 PPO 对比
#### 49. RLHF-PPO 和 GRPO 在 baseline 上有什么区别？
RLHF-PPO 使用 value head/critic 估计 baseline。GRPO 使用同 prompt 组内 reward 均值作为 baseline。

#### 50. RLHF-PPO 和 GRPO 在模型组件上有什么区别？
RLHF-PPO 通常需要 policy、reference、reward、value。GRPO 通常不需要 value model，主要是 policy、reference、reward。

#### 51. RLHF-PPO 和 GRPO 在显存和计算成本上有什么差异？
GRPO 省掉 critic/value head 训练，显存和 critic 计算减少；但每个 prompt 需要采样多个回答，生成成本增加。

#### 52. GRPO 的 group size 会影响什么？
影响 advantage 估计质量、生成成本和组内比较稳定性。group 太小基线不稳，太大成本高。

#### 53. GRPO 为什么适合数学推理或代码任务？
这类任务可用规则、答案校验或测试用例打分。同一题可采样多个解答，组内比较信号明确。

#### 54. GRPO 相比 PPO 的主要风险是什么？
组内 reward 方差不稳定，group size 影响大；若 reward 信号粗糙，组内相对优势噪声高；多样本生成成本高。

#### 55. GRPO 和 REINFORCE with baseline 有什么联系？
两者都用log pi * advantage形式。GRPO 的 advantage 来自组内 reward 相对 baseline，而不是 value network。

#### 56. GRPO 中同一个回答的 advantage 是否一定逐 token 不同？
不一定。常见做法中同一回答的 group advantage 可共享给该回答的所有 response token；具体实现也可能结合 token-level KL 或其他 shaping。

### 七、DeepSeek-R1 与 KL 估计
#### 57. DeepSeek-R1/DeepSeekMath 场景中，GRPO 的奖励可以来自哪些信号？
可以来自答案正确性、格式约束、数学验证、代码测试、规则奖励或奖励模型评分。

#### 58. 为什么可验证任务特别适合 GRPO？
因为 reward 可以相对客观地比较同 prompt 下多个候选，组内相对优势可靠，不一定需要训练 critic。

#### 59. 什么是KL(pi || ref)的基本定义？
```text
KL(pi || ref) = E_{a ~ pi}[log pi(a|s) - log ref(a|s)]
```

#### 60. 在 sampled action 上估计 KL 时，logp_policy - logp_ref表示什么？
表示当前采样 token 在 policy 下相对 reference 的 log probability 差，是前向 KL 的单样本估计项。

#### 61. 为什么不同代码库的 KL 符号和方向必须仔细检查？
有的代码定义logp_policy - logp_ref，有的用反方向或非负近似。如果符号弄反，KL penalty 会鼓励偏离 reference。

#### 62. KL penalty 和 PPO clipping 分别限制什么？
KL penalty 限制 policy 相对 reference model 的偏离。PPO clipping 限制当前更新中新策略相对 old policy 的变化。

#### 63. GRPO 中如果 KL 系数太小，会有什么风险？
模型可能过度优化 reward，偏离 reference，产生格式投机、语言质量下降或安全性问题。

#### 64. GRPO 中如果 KL 系数太大，会有什么风险？
策略被 reference 过强约束，难以学习新的推理行为，reward 改进有限。

### 八、综合设计与面试追问
#### 65. 请画出或描述 RLHF-PPO 的完整训练流程图。
```text
prompts -> policy 生成 responses -> 保存 old logp
        -> reference 计算 ref logp
        -> reward model 打分
        -> 计算 KL penalty、token rewards、values、advantages
        -> PPO clipped loss + value loss + mask
        -> 更新 policy/value head
```

#### 66. 请画出或描述 GRPO 的完整训练流程图。
```text
prompt -> policy 采样 G 个 responses
       -> reward/规则/验证器分别打分
       -> 组内均值和标准差归一化得到 group advantage
       -> 结合 old logp、new logp、KL penalty 和 PPO-style clipping
       -> 更新 policy
```

#### 67. 如果要把 RLHF-PPO 改成 GRPO，需要删除和新增哪些步骤？
删除 value head 训练、value loss、GAE/value-based advantage。新增同 prompt 多候选采样、组内 reward 均值/标准差、group relative advantage。保留 reference KL、old logp、ratio clipping。

#### 68. 如果 reward model 偏好长答案，PPO 和 GRPO 分别可能学到什么坏行为？
PPO 可能学会生成冗长回答以提高 reward。GRPO 如果组内长答案普遍得分更高，也会提高长答案概率。需要长度惩罚、校准 reward、人工评估和多指标约束。

#### 69. 在大模型 RL 中，为什么“奖励上升”不一定代表真实能力上升？
奖励模型或规则可能有漏洞，模型可能学会投机格式、变长、模板化、自信胡编。真实能力需要独立 benchmark、人评、鲁棒性和安全评估验证。

#### 70. 请完整比较 SFT、DPO、RLHF-PPO、GRPO 的数据形式、训练目标、优缺点和适用场景。
SFT 使用 prompt-answer 数据，目标是模仿示范，稳定但只能学习标注分布。DPO 使用 chosen/rejected 偏好对，直接优化偏好目标，不需要在线 RL 和 reward model，工程简单但依赖离线偏好数据。RLHF-PPO 使用 prompt 采样 response、reward model 打分、PPO 优化，能在线探索并优化奖励，但成本高且需要 critic、KL 和复杂工程。GRPO 对同 prompt 采样多候选，用组内相对 reward 优化，省 critic，适合数学、代码、推理等可验证任务，但生成成本和 reward 质量仍是关键风险。
