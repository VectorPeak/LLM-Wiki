---
title: "微信_汐的小世界_强化学习：DAPO、GSPO 与 SAPO_公众号文章剪藏_2026-06-21_1-3"
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

## 0x01. 十七：强化学习：DAPO、GSPO 与 SAPO
> 发布日期：2026-06-21  
> 原文链接：[十七：强化学习：DAPO、GSPO 与 SAPO](https://mp.weixin.qq.com/s/4KVte5UR9HLr1e6PtdIsZQ)

### 1. 学习定位
第十五天已经学习了 RLHF-PPO 和 GRPO。第十七天继续看 GRPO 之后的大模型强化学习改进方法：DAPO、GSPO、SAPO。

这三类方法都围绕同一个问题展开：

核心背景：

- PPO/RLHF-PPO 需要 critic/value head，工程复杂。
- GRPO 去掉 critic，用同一 prompt 的多回答组内相对奖励构造 advantage。
- 但 GRPO 仍有 token-level ratio 高方差、无效样本、熵坍塌、长输出惩罚、MoE 训练不稳定等问题。
本日知识链路：

### 2. GRPO 回顾
GRPO(Group Relative Policy Optimization)的基本思路：

组内 advantage：

然后使用 PPO-style ratio clipping：

GRPO 的优势是省掉 value model，适合数学、代码、推理等可验证任务。它的风险是：如果一组回答全对或全错，组内 reward 方差为 0，advantage 近似无效；token-level ratio 波动大，训练可能不稳定。

### 3. DAPO 的定位
DAPO 是 Decoupled Clip and Dynamic sAmpling Policy Optimization。论文标题是 DAPO: An Open-Source LLM Reinforcement Learning System at Scale。

DAPO 的目标不是只提出一个小公式，而是公开一套大规模 LLM RL 训练系统，并解释使推理 RL 有效的关键细节。

DAPO 论文强调四个关键技术：

这些改动都围绕一个目标：让基于 GRPO 的大规模推理 RL 更稳定、更高效、更可复现。

### 4. DAPO 的 Clip-Higher
PPO/GRPO 中常见 ratio clipping：

传统裁剪上下界通常对称。DAPO 的 Clip-Higher 采用解耦的上下裁剪范围，尤其提高上界：

- 对正 advantage 的 token，允许 policy 更充分地提高好动作概率。
上界更高可以缓解训练中过早抑制有效正向更新的问题。
- 有助于避免 entropy collapse，让模型保持一定探索和生成多样性。
Clip-Higher 不是取消 clipping，而是让 clipping 对正向学习信号更宽松。

感觉有点像腾讯的Dual Clip PPO。

### 5. DAPO 的 Dynamic Sampling
GRPO 对同一 prompt 采样一组回答。如果一组回答奖励完全相同，例如全对或全错：

这样的 prompt 对策略更新几乎没有贡献。Dynamic Sampling 的思想是动态过滤或重采样，使 batch 中保留有有效组内差异的 prompts。

在数学推理任务中，这很重要。太简单的问题一组全对，太难的问题一组全错，都会产生弱学习信号。Dynamic Sampling 让训练更集中在模型“会一部分但不稳定”的区域。

### 6. DAPO 的 Token-Level Policy Gradient Loss
GRPO/PPO 在 LLM 中需要把 token-level log probability 汇总成 policy loss。不同归一化方式会影响长度权重和梯度分配。

DAPO 强调 token-level policy gradient loss。可以理解为：在所有有效 response tokens 上聚合策略梯度，而不是让每条 response 先内部平均后再等权平均。

抽象形式：

这样每个有效 token 都以一致方式进入优化。它有助于减少 response 长度带来的不合理权重差异，也更适合长链式推理输出。

### 7. DAPO 的 Overlong Reward Shaping
推理模型容易生成很长的 chain-of-thought。如果只用最大长度截断或硬惩罚，训练信号会很粗糙。

Overlong Reward Shaping 的思想是对过长回答设计更平滑的惩罚，而不是只在超过上限时给一个突兀的坏奖励。

这能减少模型为了拿奖励而无限延长推理的倾向，同时保留有效长推理所需的空间。

### 8. DAPO 的训练流程
基于 GRPO/DAPO 的推理 RL 流程可以概括为：

DAPO 适合可验证推理任务，例如数学答案、代码测试、格式检查等。

### 9. GSPO 的定位
GSPO 是 Group Sequence Policy Optimization。它由 Qwen 团队提出，目标是解决 GRPO/token-level policy optimization 在大模型，尤其 MoE 模型训练中的不稳定问题。从 Token 视角的“局部微观”提升到 Sequence 视角的“全局宏观”，并以此作为稳定 MoE 模型强化学习训练的关键利器。

GSPO 的核心变化：

它把一整条 response 看作一个更一致的优化单元，而不是让每个 token 独立触发 clipping。

### 10. GSPO 的 Sequence-Level Ratio
token-level ratio：

sequence-level ratio 可以理解为整条 response 概率变化的度量。常见稳定写法会使用长度归一化 log ratio：

如果不做长度归一化，完整序列概率乘积会随长度快速变得极小或极大，不利于稳定训练。

GSPO 对r_seq做 clipping，并将序列级别的信号用于整条回答的优化。

### 11. GSPO 为什么强调 Sequence-Level
LLM 的回答质量通常是 sequence-level 的：

数学题答案是否正确取决于完整推理。
代码是否通过测试取决于完整程序。
对话是否有帮助取决于完整回复。
token-level clipping 可能出现一个问题：同一条回答中有些 token 被裁剪，有些 token 没有被裁剪，优化信号不一致。GSPO 用 sequence-level ratio 让整条回答作为一个整体被约束，更符合序列生成任务。

### 12. GSPO 与 MoE 稳定性
GSPO 论文特别强调它能稳定 MoE 模型 RL 训练。MoE 模型中，不同 token 可能路由到不同专家，token-level ratio 和梯度波动更明显(专家抖动)。

sequence-level ratio 的直觉优势：

GSPO 论文报告它相比 GRPO 有更好的训练效率和性能，并对 Qwen3 系列模型改进有贡献。

### 13. SAPO 的定位
SAPO 是 Soft Adaptive Policy Optimization。它针对 hard clipping 的问题提出 soft adaptive gate。

- GRPO 使用 token-level hard clipping。
- GSPO 使用 sequence-level hard clipping。
- hard clipping 的问题是边界不连续，超过裁剪范围后可能直接抑制有效梯度。
- 如果说 GSPO 是为了解决 MoE 专家抖动而发明的“全局减震器”，那么 SAPO 就是为了解决 GSPO 带来的“连坐惩罚”而设计的“智能独立悬挂系统”。
SAPO 的核心思想：

### 14. SAPO 的 Soft Adaptive Gate
在 PPO、GRPO 和 GSPO 中使用的clip操作，在数学上存在一个致命的缺陷：导数为 0(梯度消失)。 当一个 Token 的比率r_t越过了1+epsilon的边界(意味着这个 Token 偏离原策略比较远了)，它的目标函数值就被死死卡在了(1+epsilon)A。 这时候你对它求导，结果是0！

这意味着，只要 Token 越界，网络在这个 Token 上就彻底停止学习了。这就好比一个学生某次考试超常发挥考了满分，老师直接把他的试卷收走，不再给他任何反馈。

SAPO 不再只用：

而是引入一个平滑 gate：

在 0 到 1 之间。
是温度参数，控制衰减的平滑程度。
ratio 越偏离可信区域，权重越小。
- 接近 on-policy 的 token 保留较多学习信号。
具体实现可以使用 sigmoid 类函数。面试中重点不是背某个实现细节，而是理解：SAPO 用连续权重衰减替代硬裁剪。

### 15. SAPO 的 Sequence-Coherent 与 Token-Adaptive
SAPO 论文强调两个特性：

当一条序列只有少数 token 高度 off-policy 时：

- GSPO 可能因为 sequence-level hard clipping 抑制整条序列梯度。
- SAPO 可以只降低异常 token 的权重，同时保留其他 near-on-policy token 的学习信号。
因此 SAPO 试图在稳定性和样本效率之间取得更细粒度的平衡。

通俗解释就是：

GSPO 因为把整条序列捆绑，会导致“一行错代码毁掉 499 行好代码”的连坐问题。

SAPO 完美破解了这个困局：

它保留了序列级别的一致性(Sequence-Coherent)，让整条逻辑链的方向保持大体一致。

但通过加入 Token 级别的软门控(Token-Adaptive)，当序列中出现极个别极其夸张的 off-policy Token(比如产生幻觉的词汇)时，SAPO 的机制会自动让这几个坏 Token 的w_t趋近于 0，从而在计算梯度时把它们“软屏蔽”掉。

结果就是：那 499 行好代码继续开心地上分，而那 1 行离谱的错误代码被悄悄孤立，不会拖垮整个队伍的优化步伐。

### 16. GRPO、DAPO、GSPO、SAPO 对比
| 方法 | 核心机制 | 优点 | 风险 / 不足 |
| --- | --- | --- | --- |
| GRPO | 组内奖励标准化构造优势，移除价值网络(critic)；Token 级硬裁剪 | 架构极简、参量少、训练 / 部署成本低，适配数学 / 代码等可验证任务 | 组内奖励方差为 0 时优势失效；Token 级 ratio 波动大，训练易不稳 |
| DAPO | 动态采样、Clip-Higher 策略、Token 级损失、超长序列优化约束 | 扩充有效样本，大幅提升推理类任务 RL 训练稳定性 | 工程实现繁琐，效果高度依赖任务奖励设计，调参成本高 |
| GSPO | 将裁剪与概率比值从 Token 级改为序列级，沿用硬裁剪 | 保障整条输出序列的语义一致性，适配 MoE 模型训练，稳定性优于 GRPO | 粒度过粗：单个 Token 异常会导致整条序列梯度被抑制，浪费样本 |
| SAPO | 用平滑自适应门控(Soft Gate)替代传统硬裁剪，结合序列一致性 + Token 自适应 | 梯度平滑衰减而非粗暴截断；仅削弱异常 Token 权重，保留正常学习信号，兼顾稳定性与样本效率 | 新增温度等超参数，调参难度上升；函数逻辑更复杂，实现成本更高 |

### 17. 方法选型
DAPO 更适合：

可验证推理任务。
需要复现大规模 LLM RL 系统。
存在大量全对/全错样本。
需要处理过长推理输出。
GSPO 更适合：

序列级质量更重要。
- token-level ratio 方差大。
MoE 模型 RL 训练不稳定。
希望简化 sequence-level RL 基础设施。
SAPO 更适合：

hard clipping 导致样本效率损失。
- 一条序列中只有局部 token off-policy。
- 希望兼顾 sequence coherence 和 token adaptivity。
### 18. 工程监控指标
训练 DAPO/GSPO/SAPO 时常关注：

reward / pass@k / pass@1。
response length。
group reward std。
zero-advantage prompt 比例。
policy entropy。
KL to reference。
ratio 分布。
clip fraction 或 soft gate 权重分布。
overlong response 比例。
valid format rate。
- batch token 数和有效 token 数。
这些指标能帮助判断是奖励问题、采样问题、长度问题、KL 问题还是 clipping 问题。

### 19. 常见误区
误区一：DAPO、GSPO、SAPO 是完全替代 PPO 的无关算法。 它们仍然继承 policy gradient、importance ratio、clipping/KL 的思想，只是在 LLM RL 场景做结构化改造。

误区二：Dynamic Sampling 只是为了加速数据加载。 它的关键是提高 batch 中有有效 advantage 的样本比例。

误区三：GSPO 只是把 token ratio 平均一下。 GSPO 的重点是 sequence-level optimization，把整条回答作为更一致的优化单元。

误区四：SAPO 只是把 clip 换成 sigmoid。 SAPO 的意义是用平滑 gate 保留 near-on-policy 学习信号，避免 hard clipping 的粗糙截断。

误区五：这些算法只看 reward 越高越好。 大模型 RL 必须同时看 reward、KL、长度、格式、人工评估和安全性。

### 20. 核心总结
第十七天需要掌握的最小闭环：

### 21. 参考资料
- DAPO 原论文：https://arxiv.org/abs/2503.14476
- DAPO 快速了解：https://yam.gift/2025/03/19/NLP/LLM-Training/2025-03-19-LLM-PostTrain-DAPO/
- GSPO 原论文：https://arxiv.org/abs/2507.18071
- 通俗解释 GSPO 原理：https://blog.csdn.net/weixin_41544125/article/details/149977267
- SAPO 原论文：https://arxiv.org/abs/2511.20347
- 从 PPO 到 SAPO 的演进：https://zhuanlan.zhihu.com/p/1978480903136245222
- SkyRL DAPO 文档：https://skyrl.readthedocs.io/en/latest/algorithms/dapo.html
- RLinf DAPO 文档：https://rlinf.readthedocs.io/en/latest/rst_source/tutorials/rlalg/dapo.html

## 0x02. 十七：强化学习：DAPO、GSPO 与 SAPO自测题
> 发布日期：2026-06-07  
> 原文链接：[十七：强化学习：DAPO、GSPO 与 SAPO自测题](https://mp.weixin.qq.com/s/5NsxqRJoWYUPLJAnlJTa9w)

### 覆盖范围
 GRPO 的问题与改进动机

 DAPO 的四个关键技术

 Clip-Higher、Dynamic Sampling、Token-Level Policy Gradient Loss、Overlong Reward Shaping

 GSPO 的 sequence-level ratio、sequence-level clipping 与 MoE 稳定性

 SAPO 的 soft adaptive gate、sequence-coherent、token-adaptive

 DAPO/GSPO/SAPO 与 GRPO、PPO 的系统对比

 大模型推理 RL 的工程监控与排错

### 一、GRPO 改进背景
 GRPO 的核心思想是什么？

 GRPO 为什么能省掉 value model 或 critic？

 GRPO 中 group-relative advantage 如何计算？

 为什么同一 prompt 的一组回答全对或全错会导致学习信号弱？

 GRPO 中 token-level importance ratio 可能带来什么不稳定？

 大模型推理 RL 为什么特别关注 response length？

 为什么可验证任务适合 GRPO/DAPO 这类方法？

 DAPO、GSPO、SAPO 共同想解决什么问题？

### 二、DAPO 总体框架
 DAPO 的全称是什么？

 DAPO 相比 GRPO 主要增加了哪四个关键技术？

 DAPO 为什么被看作大规模 LLM RL 系统，而不只是单个 loss？

 DAPO 适合哪些任务场景？

 DAPO 的 reward 通常可以来自哪些来源？

 DAPO 为什么强调开源和可复现训练细节？

 DAPO 的训练流程可以如何概括？

 DAPO 与 RLHF-PPO 在是否需要 critic 上有什么区别？

### 三、Clip-Higher 与 Dynamic Sampling
 传统 PPO/GRPO clipping 的基本形式是什么？

 Clip-Higher 的核心思想是什么？

 为什么提高上裁剪阈值可能缓解 entropy collapse？

 Clip-Higher 是否意味着取消 clipping？为什么？

 Dynamic Sampling 解决什么问题？

 什么样的 prompt 在 GRPO/DAPO 中可能产生 zero advantage？

 Dynamic Sampling 为什么能提高有效梯度密度？

 Dynamic Sampling 是否可能引入数据分布偏差？

 如果训练中 zero-advantage prompt 比例很高，应该如何处理？

 Clip-Higher 和 Dynamic Sampling 分别作用在训练的哪个环节？

### 四、Token-Level Loss 与 Overlong Reward Shaping
 DAPO 中 Token-Level Policy Gradient Loss 的直觉是什么？

 token-level 聚合和 response-level 平均有什么区别？

 Token-Level Policy Gradient Loss 为什么适合长链式推理？

 如果每条 response 等权平均，可能带来什么长度相关问题？

 Overlong Reward Shaping 解决什么问题？

 为什么只对超长回答做硬惩罚可能不好？

 Overlong Reward Shaping 可以如何设计？

 过长惩罚如果太强，会有什么副作用？

 过长惩罚如果太弱，会有什么副作用？

 DAPO 中哪些指标可以帮助诊断长度问题？

### 五、GSPO 基础
 GSPO 的全称是什么？

 GSPO 相比 GRPO 的核心变化是什么？

 什么是 token-level ratio？

 什么是 sequence-level ratio？

 为什么 sequence-level ratio 常需要长度归一化？

 GSPO 为什么更符合文本生成的 sequence-level reward？

 token-level clipping 在同一条回答中可能产生什么不一致？

 GSPO 如何改善这种不一致？

 GSPO 为什么被认为有助于 MoE 模型 RL 稳定？

 GSPO 与 DAPO 的关注点有什么不同？

### 六、SAPO 基础
 SAPO 的全称是什么？

 SAPO 想解决 hard clipping 的什么问题？

 SAPO 中 soft adaptive gate 的直觉是什么？

 温度参数在 soft gate 中通常控制什么？

 SAPO 为什么被称为 sequence-coherent？

 SAPO 为什么被称为 token-adaptive？

 当一条序列只有少数 token 高度 off-policy 时，GSPO 和 SAPO 可能如何不同？

 SAPO 相比 GRPO 的改进点是什么？

 SAPO 相比 GSPO 的改进点是什么？

 SAPO 新增了哪些工程复杂度？

### 七、对比、指标与排错
 请比较 GRPO、DAPO、GSPO、SAPO 的核心优化对象。

 请比较 DAPO、GSPO、SAPO 分别主要解决什么训练问题。

 什么是 ratio 分布？为什么要监控它？

 什么是 clip fraction 或 gate weight distribution？它们说明什么？

 为什么 policy entropy 是大模型 RL 的重要指标？

 如果训练 reward 上升但 KL 也快速上升，说明什么？

 如果 response length 快速变长，可能是什么原因？

 如果 group reward std 长期接近 0，应该如何排查？

 如果 DAPO 训练中有效 batch 数不足，可能是什么原因？

 如果 GSPO 训练中过多序列被裁剪，可能如何处理？

### 八、综合设计与面试追问
 请设计一个基于 DAPO 的数学推理 RL 训练流程。

 请设计一个从 GRPO 改成 GSPO 的核心代码改动思路。

 请设计一个从 GSPO 改成 SAPO 的核心改动思路。

 请完整比较 PPO、GRPO、DAPO、GSPO、SAPO 在数据、优势估计、ratio 粒度、裁剪方式、优缺点和适用场景上的差异。

## 0x03. 十七：强化学习：DAPO、GSPO 与 SAPO自测题答案
> 发布日期：2026-06-07  
> 原文链接：[十七：强化学习：DAPO、GSPO 与 SAPO自测题答案](https://mp.weixin.qq.com/s/Wh4RzcWQz7cskGLKRWgy_A)

### 参考资料
 DAPO 原论文：https://arxiv.org/abs/2503.14476

 DAPO 快速了解：https://yam.gift/2025/03/19/NLP/LLM-Training/2025-03-19-LLM-PostTrain-DAPO/

 GSPO 原论文：https://arxiv.org/abs/2507.18071

 通俗解释 GSPO 原理：https://blog.csdn.net/weixin_41544125/article/details/149977267

 SAPO 原论文：https://arxiv.org/abs/2511.20347

 从 PPO 到 SAPO 的演进：https://zhuanlan.zhihu.com/p/1978480903136245222

 SkyRL DAPO 文档：https://skyrl.readthedocs.io/en/latest/algorithms/dapo.html

 RLinf DAPO 文档：https://rlinf.readthedocs.io/en/latest/rst_source/tutorials/rlalg/dapo.html

### 评分标准
 合格：能说清 GRPO、DAPO、GSPO、SAPO 的基本动机和核心差异。

 良好：能解释 DAPO 四个关键技术、GSPO sequence-level ratio、SAPO soft adaptive gate。

 优秀：能从 ratio 粒度、裁剪方式、样本有效性、长度控制、MoE 稳定性和工程监控角度完整分析。

### 一、GRPO 改进背景
#### 1. GRPO 的核心思想是什么？
 GRPO 对同一 prompt 采样多个回答，用组内 reward 均值和标准差构造相对 advantage，不训练 critic，然后用 PPO-style ratio clipping 更新 policy。

#### 2. GRPO 为什么能省掉 value model 或 critic？
 因为同组回答的平均 reward 可以作为 baseline。回答好坏通过组内相对分数衡量，不需要单独估计 V(s)。

#### 3. GRPO 中 group-relative advantage 如何计算？
 常见形式：
```text
A_i = (r_i - mean(r_1,...,r_G)) / std(r_1,...,r_G)
```
#### 4. 为什么同一 prompt 的一组回答全对或全错会导致学习信号弱？
 如果 reward 全相同，组内标准差为 0 或接近 0，所有回答没有相对优劣，advantage 无法提供有效方向。

#### 5. GRPO 中 token-level importance ratio 可能带来什么不稳定？
 单个 token 的 log probability 变化可能很大，ratio 高方差会导致 clipping 频繁、梯度不稳定，MoE 模型中还可能受路由变化放大。

#### 6. 大模型推理 RL 为什么特别关注 response length？
 推理任务需要足够长的思考，但过长会浪费算力、触发截断、造成长度投机。长度还会影响 logp 聚合和 reward。

#### 7. 为什么可验证任务适合 GRPO/DAPO 这类方法？
 数学、代码等任务能用规则或测试得到明确 reward，同一 prompt 多候选之间容易比较，适合组内相对优势。

#### 8. DAPO、GSPO、SAPO 共同想解决什么问题？
 共同目标是让 LLM 推理 RL 更稳定、更高效、更可扩展，减少无效样本、ratio 不稳定、裁剪粗糙和长度失控等问题。

### 二、DAPO 总体框架
#### 9. DAPO 的全称是什么？
 Decoupled Clip and Dynamic sAmpling Policy Optimization。

#### 10. DAPO 相比 GRPO 主要增加了哪四个关键技术？
 Clip-Higher、Dynamic Sampling、Token-Level Policy Gradient Loss、Overlong Reward Shaping。

#### 11. DAPO 为什么被看作大规模 LLM RL 系统，而不只是单个 loss？
 DAPO 论文不仅给出 loss 改动，还公开了训练系统和关键工程细节，包括采样、裁剪、长度控制和 token-level 聚合。

#### 12. DAPO 适合哪些任务场景？
 适合数学推理、代码生成、可验证问答等能对多候选回答打分的推理任务。

#### 13. DAPO 的 reward 通常可以来自哪些来源？
 规则判分、答案匹配、代码测试、格式检查、模型评分或人工偏好。

#### 14. DAPO 为什么强调开源和可复现训练细节？
 大规模推理 RL 对采样、裁剪、长度和 batch 细节极敏感。隐藏细节会导致社区难以复现强推理模型。

#### 15. DAPO 的训练流程可以如何概括？
 采样 prompts；每个 prompt 生成多个回答；计算奖励；动态筛选有效组；计算组内 advantage；用 decoupled clipping 和 token-level loss 更新 policy；处理过长回答奖励。

#### 16. DAPO 与 RLHF-PPO 在是否需要 critic 上有什么区别？
 DAPO 基于 GRPO，不需要 value head/critic。RLHF-PPO 通常需要 critic 估计 value 和 advantage。

### 三、Clip-Higher 与 Dynamic Sampling
#### 17. 传统 PPO/GRPO clipping 的基本形式是什么？
```text
clip(r, 1-epsilon, 1+epsilon)
```
用来限制新旧策略 probability ratio 的变化。

#### 18. Clip-Higher 的核心思想是什么？
 解耦上下裁剪范围，尤其提高上裁剪阈值：
```text
[1-epsilon_low, 1+epsilon_high]
```
其中 epsilon_high 可以大于 epsilon_low。

#### 19. 为什么提高上裁剪阈值可能缓解 entropy collapse？
 上界更宽允许正 advantage 的好 token 获得更充分的概率提升，减少过早抑制有效学习信号，有助于保持探索和多样性。

#### 20. Clip-Higher 是否意味着取消 clipping？为什么？
 不是。它仍然限制 ratio，只是上下界不再对称，给正向更新更宽的空间。

#### 21. Dynamic Sampling 解决什么问题？
 解决 batch 中大量 prompt 组内 reward 无差异、advantage 为 0、梯度无效的问题。

#### 22. 什么样的 prompt 在 GRPO/DAPO 中可能产生 zero advantage？
 一组回答全对、全错或 reward 完全相同的 prompt。

#### 23. Dynamic Sampling 为什么能提高有效梯度密度？
 它让 batch 保留有 reward 差异的 prompt，使更多样本提供非零 advantage。

#### 24. Dynamic Sampling 是否可能引入数据分布偏差？
 可能。它更关注中等难度或有区分度的样本，可能减少极易/极难样本占比，需要监控覆盖范围。

#### 25. 如果训练中 zero-advantage prompt 比例很高，应该如何处理？
 可以启用 dynamic sampling、调整题目难度、增加 group size、改进 reward 粒度或提高采样多样性。

#### 26. Clip-Higher 和 Dynamic Sampling 分别作用在训练的哪个环节？
 Clip-Higher 作用在 policy update 的 ratio clipping 环节。Dynamic Sampling 作用在 rollout/batch 构造环节。

### 四、Token-Level Loss 与 Overlong Reward Shaping
#### 27. DAPO 中 Token-Level Policy Gradient Loss 的直觉是什么？
 在所有有效 response tokens 上统一聚合 policy gradient，使每个 token 以一致权重进入优化。

#### 28. token-level 聚合和 response-level 平均有什么区别？
 token-level 聚合按有效 token 汇总；response-level 平均先对每条回答平均，再对回答平均，会让不同长度回答的 token 权重不同。

#### 29. Token-Level Policy Gradient Loss 为什么适合长链式推理？
 长推理包含大量有效 token。token-level 聚合能更自然地处理长输出中的每个决策位置。

#### 30. 如果每条 response 等权平均，可能带来什么长度相关问题？
 短回答每个 token 的权重更大，长回答每个 token 的权重更小，可能扭曲长推理学习信号。

#### 31. Overlong Reward Shaping 解决什么问题？
 解决回答过长、触发截断、无限延长推理以博取奖励的问题。

#### 32. 为什么只对超长回答做硬惩罚可能不好？
 硬惩罚信号突兀，接近上限的回答没有平滑反馈，可能导致训练不稳定或过度避免长推理。

#### 33. Overlong Reward Shaping 可以如何设计？
 正常长度不惩罚，接近上限时逐步增加惩罚，超过或被截断时给明确负奖励。

#### 34. 过长惩罚如果太强，会有什么副作用？
 模型可能过早停止推理，输出短但不充分的答案，推理能力下降。

#### 35. 过长惩罚如果太弱，会有什么副作用？
 模型可能生成冗长思考，浪费算力，甚至通过长度投机提高 reward。

#### 36. DAPO 中哪些指标可以帮助诊断长度问题？
 平均 response length、截断率、overlong 比例、reward 与长度相关性、pass@1 与长度关系。

### 五、GSPO 基础
#### 37. GSPO 的全称是什么？
 Group Sequence Policy Optimization。

#### 38. GSPO 相比 GRPO 的核心变化是什么？
 从 token-level importance ratio/clipping 转为 sequence-level importance ratio/clipping 和 sequence-level optimization。

#### 39. 什么是 token-level ratio？
```text
r_t = exp(logp_new_t - logp_old_t)
```
表示某个 token 动作的新旧策略概率比。

#### 40. 什么是 sequence-level ratio？
 它衡量整条 response 在新旧策略下的概率变化。常见稳定写法是长度归一化 log ratio 后指数化：
```text
r_seq = exp(1/|y| * sum_t (logp_new_t - logp_old_t))
```
#### 41. 为什么 sequence-level ratio 常需要长度归一化？
 完整序列概率是 token 概率乘积，长度越长数值越极端。长度归一化能让不同长度回答更可比较。

#### 42. GSPO 为什么更符合文本生成的 sequence-level reward？
 文本质量、答案正确性和推理成功通常由完整回答决定，sequence-level 更新更符合任务目标。

#### 43. token-level clipping 在同一条回答中可能产生什么不一致？
 同一条回答中部分 token 被裁剪，部分 token 未被裁剪，导致序列内部更新信号不一致。

#### 44. GSPO 如何改善这种不一致？
 用整条序列的 ratio 和 clipping 决定更新，让回答作为整体被优化或约束。

#### 45. GSPO 为什么被认为有助于 MoE 模型 RL 稳定？
 MoE 中 token 路由变化会放大 token-level ratio 波动。sequence-level ratio 能降低局部波动对更新的影响，保持序列一致性。

#### 46. GSPO 与 DAPO 的关注点有什么不同？
 DAPO 更关注有效采样、裁剪上界、token-level loss 和长度 shaping。GSPO 更关注 ratio 粒度从 token 到 sequence 的改变。

### 六、SAPO 基础
#### 47. SAPO 的全称是什么？
 Soft Adaptive Policy Optimization。

#### 48. SAPO 想解决 hard clipping 的什么问题？
 hard clipping 边界粗糙，超过范围后学习信号可能被过度抑制。SAPO 用平滑权重衰减保留有用信号。

#### 49. SAPO 中 soft adaptive gate 的直觉是什么？
 根据 ratio 偏离程度给 token 或更新分配 0 到 1 的连续权重，越 off-policy 权重越小。

#### 50. 温度参数在 soft gate 中通常控制什么？
 控制 gate 衰减曲线的平滑程度。温度越高越平滑，温度越低越接近硬门控。

#### 51. SAPO 为什么被称为 sequence-coherent？
 它保持类似 GSPO 的序列级一致性，不完全回到孤立 token 更新。

#### 52. SAPO 为什么被称为 token-adaptive？
 它能对序列中的不同 token 自适应下调权重，而不是整条序列一刀切。

#### 53. 当一条序列只有少数 token 高度 off-policy 时，GSPO 和 SAPO 可能如何不同？
 GSPO 可能因为序列级 hard clipping 抑制整条序列梯度。SAPO 可以降低异常 token 权重，同时保留其他 token 的学习信号。

#### 54. SAPO 相比 GRPO 的改进点是什么？
 它用平滑、温控的缩放机制替代 hard token clipping，降低高方差 ratio 带来的不稳定。

#### 55. SAPO 相比 GSPO 的改进点是什么？
 它避免 sequence-level hard clipping 过于粗糙，能在保持序列一致的同时进行 token-adaptive 调节。

#### 56. SAPO 新增了哪些工程复杂度？
 需要实现 soft gate、调节温度参数、监控 gate 权重分布，并处理和 KL、ratio、mask 的交互。

### 七、对比、指标与排错
#### 57. 请比较 GRPO、DAPO、GSPO、SAPO 的核心优化对象。
 GRPO 优化组内相对 advantage 下的 token-level clipped objective。DAPO 在 GRPO 上改进采样、裁剪、token 聚合和长度奖励。GSPO 优化 sequence-level ratio。SAPO 用 soft adaptive gate 调节 policy update。

#### 58. 请比较 DAPO、GSPO、SAPO 分别主要解决什么训练问题。
 DAPO 解决有效样本、熵坍塌、长度控制和 token 聚合。GSPO 解决 token ratio 高方差和序列不一致。SAPO 解决 hard clipping 粗糙导致的样本效率损失。

#### 59. 什么是 ratio 分布？为什么要监控它？
 ratio 分布是新旧策略概率比的统计。它反映 policy update 幅度，过大或过宽说明更新不稳定。

#### 60. 什么是 clip fraction 或 gate weight distribution？它们说明什么？
 clip fraction 表示被 hard clip 的比例。gate weight distribution 表示 SAPO 中软权重分布。它们说明有多少样本被抑制以及更新是否过猛。

#### 61. 为什么 policy entropy 是大模型 RL 的重要指标？
 entropy 反映策略多样性。过快下降可能说明探索不足或 entropy collapse。

#### 62. 如果训练 reward 上升但 KL 也快速上升，说明什么？
 模型可能快速偏离 reference，存在 reward hacking 或语言质量下降风险。需要加强 KL、降低学习率或调整 clipping。

#### 63. 如果 response length 快速变长，可能是什么原因？
 reward 偏好长推理、过长惩罚不足、长度归一化设置不当或模型学到长度投机。

#### 64. 如果 group reward std 长期接近 0，应该如何排查？
 检查任务难度、reward 是否过粗、group size 是否太小、采样温度是否太低、是否大量全对/全错。

#### 65. 如果 DAPO 训练中有效 batch 数不足，可能是什么原因？
 Dynamic Sampling 条件过严、题目难度不匹配、生成多样性不足、reward 过于稀疏或 group size 太小。

#### 66. 如果 GSPO 训练中过多序列被裁剪，可能如何处理？
 降低学习率、减少更新 epoch、调整 clipping 范围、检查 ratio 计算和长度归一化、加强 KL 控制。

### 八、综合设计与面试追问
#### 67. 请设计一个基于 DAPO 的数学推理 RL 训练流程。
 准备数学题 prompts；每题采样多条解答；用答案校验和格式规则打分；过滤全对/全错组；计算组内 advantage；使用 Clip-Higher 和 token-level loss 更新；对过长回答做 shaping；监控 pass@1、长度、KL、entropy 和 group std。

#### 68. 请设计一个从 GRPO 改成 GSPO 的核心代码改动思路。
 把 token-level ratio 聚合为 sequence-level ratio，例如长度归一化 log ratio；用 sequence ratio 做 clipping；将同一序列共享的 clipped 权重应用到 response token；调整监控指标为 sequence ratio 和 sequence clip fraction。

#### 69. 请设计一个从 GSPO 改成 SAPO 的核心改动思路。
 保留序列一致性指标，引入 soft adaptive gate；用 gate 权重替代硬裁剪或对硬裁剪做平滑化；按 token 或序列-token 混合方式衰减 off-policy 更新；新增温度和 gate 分布监控。

#### 70. 请完整比较 PPO、GRPO、DAPO、GSPO、SAPO 在数据、优势估计、ratio 粒度、裁剪方式、优缺点和适用场景上的差异。
 PPO 使用 rollout 和 critic/value 估计 advantage，token/action ratio clipping，通用但工程复杂。GRPO 对同 prompt 多回答做组内 advantage，无 critic，适合可验证 LLM RL，但有 zero-advantage 和 token ratio 方差问题。DAPO 在 GRPO 上加入 Clip-Higher、Dynamic Sampling、token-level loss 和过长 shaping，适合大规模推理 RL 复现。GSPO 把 ratio 和 clipping 提升到 sequence level，适合序列级奖励和 MoE 稳定训练。SAPO 用 soft adaptive gate 替代硬裁剪，在稳定性和样本效率之间更细粒度折中，适合 hard clipping 损失有效信号的场景。
