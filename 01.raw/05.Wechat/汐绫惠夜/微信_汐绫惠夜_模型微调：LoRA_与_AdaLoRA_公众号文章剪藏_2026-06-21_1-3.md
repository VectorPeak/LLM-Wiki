---
title: "微信_汐绫惠夜_模型微调：LoRA 与 AdaLoRA_公众号文章剪藏_2026-06-21_1-3"
source: "/api/v1/wechat_mp/web/fetch_mp_article_detail_html"
author:
  - "汐绫惠夜"
published: "2026-05-28"
created: 2026-06-21
description: "TikHub 命中的微信公众号文章候选，共 3 条，本文档收录 3 条"
tags:
  - "clippings"
  - "wechat"
  - "汐绫惠夜"
---

## 0x01. 七：模型微调：LoRA 与 AdaLoRA
> 发布日期：2026-05-28  
> 原文链接：[七：模型微调：LoRA 与 AdaLoRA](https://mp.weixin.qq.com/s/_3JsOsqh053KHlQv3AyAmQ)

### 1. 学习定位
 模型微调的目标是让预训练模型适配下游任务、领域数据或特定输出格式。大模型参数规模很大，全量微调成本高、显存占用大、保存多个任务版本也昂贵，因此参数高效微调 PEFT 成为常用方案。

 第七天重点是 LoRA 和 AdaLoRA。LoRA 是最常见的大模型参数高效微调方法之一，核心是冻结原模型权重，只训练低秩增量矩阵。AdaLoRA 在 LoRA 基础上进一步根据参数重要性自适应分配 rank 预算。

 本日知识链路：
```text
预训练模型
-> 下游任务适配需求
-> 全量微调成本高
-> PEFT 只训练少量参数
-> LoRA 用低秩矩阵表示权重增量
-> 冻结 W，只训练 A/B
-> 训练后可合并到原权重
-> AdaLoRA 自适应给重要模块分配更多 rank
```
面试中 LoRA 常被追问：

 LoRA 的公式是什么。

 为什么低秩更新有效。

 LoRA 参数量如何计算。

 LoRA 的 rank、alpha、dropout 分别是什么。

 LoRA 应该加到哪些模块。

 LoRA 和全量微调、Adapter、Prefix Tuning 有什么区别。

 LoRA 训练和推理时如何处理权重。

 LoRA merge/unmerge 有什么意义。

 AdaLoRA 如何自适应分配 rank。

### 2. 模型微调的基本范式
 预训练模型学习通用语言能力，但具体业务或任务通常需要微调。常见微调范式包括：
```text
全量微调：
  更新模型所有参数。

部分层微调：
  冻结大部分层，只训练部分层或 task head。

参数高效微调 PEFT：
  冻结原模型，只训练少量新增参数或低秩增量。

Prompt/Prefix 类方法：
  不改原权重，学习连续提示向量或前缀键值。
```
全量微调表达能力强，但显存、训练成本和存储成本高。PEFT 更适合多任务、多领域、资源有限或需要快速迭代的场景。

### 3. 全量微调的成本
 全量微调需要训练所有参数。以 7B 模型为例，仅参数本身在 bf16 下约需要：
```text
7B * 2 bytes ≈ 14 GB
```
训练时还需要梯度、优化器状态、激活等显存。Adam 优化器通常还要保存一阶和二阶动量，实际显存远大于参数本身。

 全量微调还会带来存储成本：
```text
每个任务保存一份完整 checkpoint
```
如果一个 7B 模型有几十个任务版本，存储和管理都会很重。

 LoRA 的价值在于：大部分预训练权重不变，只训练和保存很小的增量参数。

### 4. PEFT 的核心思想
 PEFT 是 Parameter-Efficient Fine-Tuning，参数高效微调。它的共同目标是减少可训练参数，同时尽量保持下游性能。

 PEFT 的主要思路：

 冻结预训练模型主体。

 只训练少量新增参数。

 让新增参数影响模型输出。

 每个任务只保存小规模 adapter/LoRA/prompt 参数。

 PEFT 的优势：

 显存更低。

 训练更快。

 多任务存储成本低。

 原模型权重保持不变，便于管理。

 部署时可按任务加载不同增量模块。

 局限是：表达能力通常弱于全量微调；任务差异很大或需要深度改变模型行为时，PEFT 可能不足。

### 5. LoRA 的核心公式
 LoRA 的全称是 Low-Rank Adaptation。它认为微调过程中权重更新 Delta W 具有低内在秩，可以用两个低秩矩阵近似。

 原始线性层：
```text
y = W x
```
LoRA 后：
```text
y = W x + Delta W x
Delta W = B A * alpha / r
```
其中：

- W
 是冻结的原始权重。

- A
 和 B 是可训练低秩矩阵。

- r
 是 rank。

- alpha
 是缩放系数。

- alpha / r
 是 LoRA scaling。

 如果 W: [d_out, d_in]，则通常：
```yaml
A: [r, d_in]
B: [d_out, r]
Delta W = B A: [d_out, d_in]
```
训练时只更新 A 和 B，不更新 W。

### 6. LoRA 的低秩直觉
 全量微调允许 W 的每个元素独立变化，参数量是：
```text
d_out * d_in
```
LoRA 限制权重更新位于低秩子空间：
```text
Delta W = B A
rank(Delta W) <= r
```
当 r << min(d_in, d_out) 时，可训练参数量大幅减少：
```text
r *d_in + d_out* r = r(d_in + d_out)
```
LoRA 的经验观察是：大模型适配下游任务时，不一定需要在全参数空间中任意更新，很多有效更新可以由低秩子空间表达。

### 7. LoRA 参数量计算
 假设一个线性层：
```text
W: [4096, 4096]
```
全量训练参数：
```text
4096 * 4096 = 16,777,216
```
若 LoRA rank r=8：
```yaml
A: [8, 4096]      -> 32,768
B: [4096, 8]      -> 32,768
total             -> 65,536
```
参数量约是全量的：
```text
65,536 / 16,777,216 ≈ 0.39%
```
这就是 LoRA 显存和存储高效的来源。

### 8. LoRA 初始化
 LoRA 通常希望训练开始时不改变原模型输出。因此常见初始化是：
```text
A 随机初始化
B 初始化为 0
```
这样初始时：
```text
Delta W = B A = 0
```
模型一开始等价于原始预训练模型。随着训练进行， B 和 A 学习任务相关增量。

 也有实现可能反过来初始化，但核心目标是让初始增量为 0 或足够小，避免破坏原模型。

### 9. Rank、Alpha 与 Dropout
 LoRA 常见超参：
```yaml
r: rank
alpha: scaling factor
lora_dropout: dropout applied before LoRA branch
target_modules: 哪些线性层加 LoRA
```
rank r 控制低秩子空间容量。rank 越大，可训练参数越多，表达能力越强，但显存和过拟合风险增加。

 alpha 控制 LoRA 增量的缩放：
```text
scaling = alpha / r
```
alpha 较大时 LoRA 分支影响更强，但过大可能不稳定。

 lora dropout 是对 LoRA 分支输入做 dropout，用于正则化，尤其在数据较小场景有用。

### 10. LoRA Target Modules
 在 Transformer 中，LoRA 通常加在线性层上，尤其是 attention 和 MLP 的投影矩阵。

 常见 target modules：
```text
q_proj
k_proj
v_proj
o_proj
gate_proj
up_proj
down_proj
```
不同任务和资源下选择不同：

 只加 q_proj 、 v_proj：参数更少，经典设置之一。

 加 q_proj,k_proj,v_proj,o_proj：attention 适配更充分。

 加 MLP 投影：表达能力更强，但参数更多。

 all-linear：几乎所有线性层都加 LoRA，能力更强，资源更多。

 面试中需要能解释 target module 选择是容量、成本和任务需求之间的折中。

### 11. LoRA 在 Attention 中的作用
 以 query projection 为例：
```text
Q = X W_q^T
```
加入 LoRA：
```text
Q = X W_q^T + X A_q^T B_q^T * alpha/r
```
LoRA 改变了 Q/K/V/O 等投影后的表示，从而影响 attention score、value 聚合和输出变换。

 因为 attention 决定 token 间信息路由，给 Q/V 或 Q/K/V/O 加 LoRA 通常能有效适配任务。

### 12. LoRA 训练流程
 典型 LoRA 微调流程：
```text
1. 加载预训练模型。
2. 冻结原始模型权重。
3. 在 target modules 中注入 LoRA A/B 矩阵。
4. 只把 LoRA 参数设为 trainable。
5. 用下游数据训练。
6. 保存 LoRA adapter 权重。
7. 推理时加载 base model + LoRA adapter，或 merge 后推理。
```
检查可训练参数非常重要：
```text
trainable params << total params
```
如果误把 base model 参数也设为 trainable，就失去 LoRA 的参数高效优势。

### 13. LoRA Merge 与 Unmerge
 LoRA 的一个重要优点是可以合并到原权重：
```text
W_merged = W + B A * alpha/r
```
合并后推理可以只执行普通线性层，不需要额外 LoRA 分支，推理延迟更低。

 unmerge 则是把增量从权重中移除，恢复 base weight 和 LoRA adapter 的分离状态。

 部署时有两种方式：

 不 merge：灵活切换多个 LoRA adapter。

 merge：单任务推理更简单、更快，但不便于动态切换。

### 14. LoRA 与全量微调对比
 LoRA：

 可训练参数少。

 显存和存储成本低。

 多任务切换方便。

 对小数据更不容易过拟合。

 表达能力受 rank 和 target modules 限制。

 全量微调：

 表达能力更强。

 可深度改变模型行为。

 显存、优化器状态、存储成本高。

 多任务版本管理成本大。

 更容易遗忘原能力或过拟合。

 选择时要看任务规模、数据量、资源、是否需要多任务部署以及性能要求。

### 15. LoRA 与 Adapter 对比
 Adapter 通常在 Transformer 层中插入小型瓶颈 MLP：
```text
x -> down projection -> nonlinearity -> up projection -> x + adapter(x)
```
LoRA 则是在已有线性层权重上添加低秩增量：
```text
W -> W + BA
```
对比：

 Adapter 增加新的前向模块，可能增加推理延迟。

 LoRA 可 merge 到原权重，推理更友好。

 Adapter 更像新增旁路网络，LoRA 更像约束后的权重更新。

### 16. LoRA 与 Prompt/Prefix Tuning 对比
 Prompt/Prefix Tuning 学习连续提示向量，不直接改模型权重。
```yaml
Prompt Tuning:
  学习输入 embedding 前面的 soft prompt。

Prefix Tuning:
  为每层 attention 学习 prefix key/value。

LoRA:
  学习线性层权重的低秩增量。
```
Prompt/Prefix 参数量可以更少，但表达能力和任务适配能力有时弱于 LoRA。LoRA 通常是性能、成本和工程便利之间非常强的折中。

### 17. AdaLoRA 的动机
 普通 LoRA 给所有目标矩阵设置相同 rank 或手动指定 rank。但不同层、不同模块对任务的重要性不同。

 例如某些层的 Q/V 更新很重要，另一些层可能不需要太大 rank。固定 rank 会造成：

 重要模块容量不足。

 不重要模块浪费参数预算。

 AdaLoRA 的目标是：在固定参数预算下，自适应把更多 rank 分配给更重要的权重更新。

### 18. AdaLoRA 的核心思想
 AdaLoRA 使用可分解形式表示增量，并根据重要性分数动态裁剪或分配 rank。

 直觉流程：
```text
1. 为多个模块分配初始较高 rank。
2. 训练过程中估计各 rank 方向的重要性。
3. 在预算约束下保留重要方向，裁剪不重要方向。
4. 最终得到不同模块、不同矩阵的自适应 rank。
```
相比普通 LoRA，AdaLoRA 不要求所有模块用相同 rank，而是学习 rank 分配。

 面试中不必完整复现所有数学细节，但要讲清：AdaLoRA 关注“参数预算如何分配”，LoRA 关注“用低秩矩阵表示增量”。

### 19. LoRA 超参选择
 常见经验：

 rank r=4/8/16/32/64 都常见。

- alpha
 常设为 r 、 2r 或其他经验值。

 小数据可加 lora_dropout，例如 0.05 或 0.1。

 target modules 越多，能力越强，成本越高。

 学习率通常可比全量微调稍大，但要结合模型和数据调试。

 不要机械认为 rank 越大越好。rank 大可能提升上限，也可能增加过拟合和训练成本。

### 20. LoRA 数据与评测
 LoRA 只是训练方法，不保证数据质量。下游效果依赖：

 指令数据质量。

 任务覆盖。

 输入输出格式一致。

 train/dev/test 划分。

 是否有数据泄漏。

 评价指标是否与目标一致。

 badcase 分析。

 微调报告中至少应记录：
```text
base model
dataset
template
target modules
r / alpha / dropout
learning rate
batch size / grad accumulation
epochs / steps
eval metrics
badcases
```
### 21. LoRA 常见工程问题
 常见问题：

 忘记冻结 base model。

 target module 名称写错，实际没有注入 LoRA。

 只保存了 adapter，推理时没加载 base model。

 tokenizer/chat template 和 base model 不匹配。

 LoRA rank 太低导致欠拟合。

 rank 太高或数据太少导致过拟合。

 merge 后继续训练导致权重状态混乱。

 多个 LoRA adapter 叠加时 scaling 和任务冲突。

 量化模型上训练 LoRA 时 dtype 处理不当。

 排查时先检查：
```text
print trainable parameters
inspect target modules
decode training samples
compare base vs lora outputs
verify adapter loading
```
### 22. 面试中的核心表达
 第七天内容可以压缩为：
```text
LoRA 是一种参数高效微调方法，冻结原模型 W，只训练低秩增量 Delta W。
公式是 W' = W + BA * alpha/r。
如果 W 是 d_out x d_in，LoRA 参数量是 r(d_in + d_out)，远小于 d_out d_in。
LoRA 通常加到 attention 和 MLP 的线性投影层，可训练参数少，训练和存储成本低。
训练后 LoRA 可以 merge 到原权重，降低推理开销。
rank、alpha、dropout、target modules 是关键超参。
AdaLoRA 在 LoRA 基础上自适应分配 rank，把参数预算给更重要的模块或方向。
```
### 23. 参考资料
 LoRA: Low-Rank Adaptation of Large Language Models: https://arxiv.org/abs/2106.09685

 AdaLoRA: Adaptive Budget Allocation for Parameter-Efficient Fine-Tuning: https://arxiv.org/abs/2303.10512

 Hugging Face PEFT LoRA Documentation: https://huggingface.co/docs/peft/main/en/package_reference/lora

 Hugging Face PEFT Conceptual Guides: https://huggingface.co/docs/peft/main/en/conceptual_guides/adapter

 LoRA 原论文：https://arxiv.org/pdf/2106.09685

 AdaLoRA 原论文：https://arxiv.org/pdf/2303.10512

 LoRA 作者讲解：https://www.bilibili.com/video/BV1sT4y1t7Cu/

## 0x02. 七：模型微调：LoRA 与 AdaLoRA自测题
> 发布日期：2026-05-28  
> 原文链接：[七：模型微调：LoRA 与 AdaLoRA自测题](https://mp.weixin.qq.com/s/qlGNWsDBWUXyIoDYUsFxdw)

### 覆盖范围
 全量微调、部分微调、PEFT 的基本区别

 LoRA 的低秩更新公式、参数量、初始化、超参

 LoRA 在 attention/MLP 中的 target modules

 LoRA 训练、保存、加载、merge/unmerge

 LoRA 与 full fine-tuning、Adapter、Prompt/Prefix Tuning 对比

 AdaLoRA 的动机和自适应 rank 分配

 LoRA 工程问题、评测方法和面试追问

### 一、模型微调与 PEFT 基础
 请用 1 分钟解释什么是模型微调。

 全量微调、部分层微调、PEFT 的区别是什么？

 为什么大模型全量微调成本很高？

 PEFT 的核心思想是什么？

 PEFT 相比全量微调有哪些优势？

 PEFT 有哪些潜在局限？

 多任务场景下，为什么 PEFT 的存储优势明显？

 面试中如何解释“LoRA 不是一种新模型，而是一种微调方式”？

### 二、LoRA 核心原理
 LoRA 的全称是什么？它解决什么问题？

 请写出 LoRA 的核心公式。

 LoRA 中为什么冻结原始权重 W？

 如果 W: [d_out, d_in]，LoRA 中 A 、 B 的 shape 通常是什么？

 为什么 Delta W = BA 的 rank 不超过 r？

 LoRA 为什么能显著减少可训练参数？

 请计算 W: [4096,4096] 、 r=8 时 LoRA 的参数量和全量参数量。

 LoRA 的低秩假设是什么？

 LoRA 初始时为什么通常让增量为 0？

- A
 随机初始化、 B 初始化为 0 的作用是什么？

### 三、LoRA 超参与模块选择
 LoRA rank r 控制什么？

- alpha
 和 alpha/r scaling 的作用是什么？

- lora_dropout
 的作用是什么？

 target modules 是什么？为什么它很重要？

 Transformer 中常见 LoRA target modules 有哪些？

 只对 q_proj 、 v_proj 加 LoRA 和对所有线性层加 LoRA 有什么区别？

 为什么 attention projection 是 LoRA 常见注入位置？

 MLP 层加 LoRA 可能带来什么收益和成本？

 rank 越大一定越好吗？为什么？

 LoRA 学习率通常如何相对全量微调考虑？

### 四、训练、推理与部署
 LoRA 微调的标准训练流程是什么？

 如何检查 LoRA 是否真的只训练了少量参数？

 LoRA adapter 保存的是什么？是否包含 base model 全量权重？

 推理时加载 LoRA adapter 需要哪些组件？

 什么是 LoRA merge？

 什么是 LoRA unmerge？

 merge 后推理和不 merge 推理有什么区别？

 多个 LoRA adapter 如何服务不同任务？有什么风险？

 为什么 merge 后继续训练可能导致状态混乱？

 LoRA 与量化模型结合时需要注意什么？

### 五、LoRA 方法对比
 LoRA 和全量微调相比，优势和劣势分别是什么？

 LoRA 和 Adapter 的核心区别是什么？

 LoRA 为什么通常比 Adapter 更容易做到无额外推理延迟？

 LoRA 和 Prompt Tuning 的区别是什么？

 LoRA 和 Prefix Tuning 的区别是什么？

 在小数据场景中 LoRA 有什么优势和风险？

 在领域迁移很大的场景中，LoRA 可能不如全量微调的原因是什么？

### 六、AdaLoRA
 AdaLoRA 解决了普通 LoRA 的什么问题？

 为什么固定 rank 可能不是最优？

 AdaLoRA 的核心思想是什么？

 AdaLoRA 如何理解“参数预算分配”？

 AdaLoRA 和 LoRA 的主要区别是什么？

 AdaLoRA 中重要性分数大致用于什么？

 AdaLoRA 更适合哪些场景？

 AdaLoRA 的工程复杂度相比 LoRA 有什么变化？

### 七、实验设计与评测
 做一个 LoRA 实验报告，至少应该记录哪些配置？

 如何判断 LoRA 微调是真的提升，而不是评测泄漏？

 LoRA 训练 loss 下降但验证效果不好，可能有哪些原因？

 LoRA 训练后模型格式遵循变好但通用能力下降，如何分析？

 选择 LoRA target modules 时，你会如何做消融实验？

 如何比较 LoRA 和全量微调的性价比？

 如何评估不同 rank 的效果？

### 八、工程排错与面试追问
 如果 LoRA 训练后输出几乎和 base model 一样，可能是什么原因？

 如果 LoRA 训练很快过拟合，可能如何调整？

 如果加载 adapter 后报 target module 找不到，如何排查？

 如果推理结果和训练时验证结果差异很大，LoRA 相关原因有哪些？

 如果 adapter 文件很小，这是正常的吗？为什么？

 LoRA 是否能完全避免灾难性遗忘？

 LoRA 是否只适用于语言模型？

 面试官问“LoRA 为什么有效”，你会如何回答？

 面试官问“LoRA 的参数量怎么算”，你会如何回答？

 请总结第七天 LoRA/AdaLoRA 的完整知识链路。

## 0x03. 七：模型微调：LoRA 与 AdaLoRA自测题答案
> 发布日期：2026-06-21  
> 原文链接：[七：模型微调：LoRA 与 AdaLoRA自测题答案](https://mp.weixin.qq.com/s/MNSkaR26nK3qFcQ3paTHrw)

参考资料

\##LoRA: Low-Rank Adaptation of Large Language Models: https://arxiv.org/abs/2106.09685
\##AdaLoRA: Adaptive Budget Allocation for Parameter-Efficient Fine-Tuning: https://arxiv.org/abs/2303.10512
\##Hugging Face PEFT LoRA Documentation: https://huggingface.co/docs/peft/main/en/package_reference/lora
\##Hugging Face PEFT Conceptual Guides: https://huggingface.co/docs/peft/main/en/conceptual_guides/adapter
\##LoRA 作者讲解：https://www.bilibili.com/video/BV1sT4y1t7Cu/
评分标准

\##合格：能写出W' = W + BA * alpha/r，知道冻结 W、训练 A/B、rank 控制参数量。
\##良好：能计算参数量，解释 target modules、merge/unmerge、rank/alpha/dropout。
\##优秀：能比较 LoRA、全量微调、Adapter、Prompt/Prefix，并说明 AdaLoRA、实验设计和工程排错。
### 一、模型微调与 PEFT 基础
#### 1. 请用 1 分钟解释什么是模型微调。
模型微调是在预训练模型基础上，用下游任务或领域数据继续训练，使模型适配特定任务、风格、格式或知识分布。微调可以是全量更新所有参数，也可以只训练少量新增参数。

大模型中常见的是 SFT、LoRA 微调、领域继续训练等。目标是利用预训练能力，同时用较小数据和成本完成任务适配。

#### 2. 全量微调、部分层微调、PEFT 的区别是什么？
全量微调更新模型所有参数。部分层微调只更新某些层或任务头。PEFT 冻结大部分甚至全部原模型权重，只训练少量新增参数或低秩增量，例如 LoRA、Adapter、Prefix Tuning。

区别在可训练参数量、显存、存储、表达能力和部署方式。

#### 3. 为什么大模型全量微调成本很高？
参数量巨大，训练时不仅要存权重，还要存梯度、优化器状态和激活。Adam 优化器还需要一阶、二阶动量。每个任务保存完整 checkpoint 也很占存储。

例如 7B 模型 bf16 权重约 14GB，但训练总显存远大于这个数。

#### 4. PEFT 的核心思想是什么？
PEFT 的核心是冻结预训练模型主体，只训练少量任务相关参数，让这些参数以某种方式影响模型输出。这样减少训练显存和存储成本，同时尽量保留下游效果。

#### 5. PEFT 相比全量微调有哪些优势？
优势包括：可训练参数少、显存更低、训练更快、每个任务只保存小 adapter、原模型可复用、多任务切换方便、较小数据下不容易严重过拟合。

#### 6. PEFT 有哪些潜在局限？
表达能力受限，任务差异很大或需要深度改变模型行为时可能不如全量微调。超参和 target modules 选择也影响明显，低 rank 可能欠拟合。

#### 7. 多任务场景下，为什么 PEFT 的存储优势明显？
base model 只保存一份，每个任务保存小规模 adapter/LoRA 参数即可。全量微调则每个任务都要保存完整模型 checkpoint，存储成本随任务数线性增加且很大。

#### 8. 面试中如何解释“LoRA 不是一种新模型，而是一种微调方式”？
LoRA 不改变 Transformer 的主体架构，也不是从头训练新模型。它是在已有线性层旁边加入低秩增量参数，冻结 base model，通过训练这些增量来适配任务。

### 二、LoRA 核心原理
#### 9. LoRA 的全称是什么？它解决什么问题？
LoRA 是 Low-Rank Adaptation。它解决大模型微调中参数量、显存和多任务存储成本过高的问题，通过低秩矩阵训练权重增量，实现参数高效微调。

#### 10. 请写出 LoRA 的核心公式。
对线性层：

其中W冻结，A/B可训练。

#### 11. LoRA 中为什么冻结原始权重W？
冻结W可以大幅减少可训练参数、梯度和优化器状态，保留预训练能力，并让每个任务只保存低秩 adapter。训练只学习任务相关增量。

#### 12. 如果W: [d_out, d_in]，LoRA 中A、B的 shape 通常是什么？
这样BA和Wshape 一致，可以作为权重增量。

#### 13. 为什么Delta W = BA的 rank 不超过r？
矩阵乘积的秩满足：

因此Delta W是低秩更新。

#### 14. LoRA 为什么能显著减少可训练参数？
全量更新W需要d_out*d_in个参数。LoRA 只训练：

当r远小于d_in,d_out时，参数量大幅减少。

#### 15. 请计算W: [4096,4096]、r=8时 LoRA 的参数量和全量参数量。
LoRA：

约为全量的 0.39%。

#### 16. LoRA 的低秩假设是什么？
LoRA 假设下游任务适配所需的权重更新具有较低内在秩，不需要在完整参数空间任意更新。用低秩矩阵就能捕捉主要任务增量。

#### 17. LoRA 初始时为什么通常让增量为 0？
这样训练开始时模型输出与 base model 一致，不会一开始破坏预训练能力，也让优化从稳定点开始。

18. A随机初始化、B初始化为 0 的作用是什么？
因为Delta W = BA，当B=0时初始增量为 0。A随机初始化为后续学习提供方向，B逐步学习如何组合这些方向。

### 三、LoRA 超参与模块选择
#### 19. LoRA rankr控制什么？
r控制低秩增量的容量和参数量。rank 越大，表达能力越强，可训练参数越多，显存和过拟合风险也越高。

20. alpha和alpha/rscaling 的作用是什么？
alpha/r控制 LoRA 增量的整体强度。它让 rank 改变时增量尺度更可控。alpha 太大可能不稳定，太小可能适配不足。

21. lora_dropout的作用是什么？
对 LoRA 分支输入做 dropout，起正则化作用。小数据或过拟合场景中有用，但过大可能损害学习。

#### 22. target modules 是什么？为什么
它很重要？
target modules 指在哪些线性层注入 LoRA。它决定可训练参数量、影响模型哪些计算路径以及最终适配能力。写错 target module 可能导致 LoRA 根本没有注入。

#### 23. Transformer 中常见 LoRA target modules 有哪些？
常见包括：

不同模型命名可能不同，例如query_key_value、c_attn等。

#### 24. 只对q_proj、v_proj加 LoRA 和对所有线性层加 LoRA 有什么区别？
只加 Q/V 参数少、成本低，经典且常有效。所有线性层加 LoRA 容量更强，可能效果更好，但训练和存储成本更高，过拟合风险也更大。

#### 25. 为什么 attention projection 是 LoRA 常见注入位置？
attention projection 决定 query/key/value 和输出变换，直接影响 token 间信息路由和聚合。改变这些投影能有效适配下游任务。

#### 26. MLP 层加 LoRA 可能带来什么收益和成本？
MLP 负责逐 token 非线性特征变换。给 MLP 加 LoRA 可以增强表示变换能力，提升复杂任务效果。成本是参数量、显存和训练时间增加。

#### 27. rank 越大一定越好吗？为什么？
不一定。rank 大容量强，但可能过拟合、成本增加、收益递减。最优 rank 取决于任务复杂度、数据量、target modules 和资源。

#### 28. LoRA 学习率通常如何相对全量微调考虑？
LoRA 只训练少量随机初始化参数，学习率常可比全量微调稍大。但具体仍依赖模型、数据和优化器。学习率过大也会导致不稳定或破坏输出格式。

### 四、训练、推理与部署
#### 29. LoRA 微调的标准训练流程是什么？
加载 base model，冻结原始权重，在 target modules 注入 LoRA，设置只训练 LoRA 参数，准备 tokenizer/chat template 和数据，训练并验证，保存 adapter，推理时加载 base model + adapter 或 merge 后部署。

#### 30. 如何检查 LoRA 是否真的只训练了少量参数？
打印 trainable parameters，检查可训练参数占比；遍历参数名确认只有lora_A/lora_B等参数requires_grad=True；检查 optimizer 参数组。

#### 31. LoRA adapter 保存的是什么？是否包含 base model 全量权重？
通常只保存 LoRA 的 A/B 矩阵、配置和少量相关参数，不包含 base model 全量权重。因此 adapter 文件通常很小。

#### 32. 推理时加载 LoRA adapter 需要哪些组件？
需要 base model、匹配 tokenizer、LoRA adapter 权重和 PEFT 配置。adapter 必须和训练时的 base model 架构及 target modules 匹配。

#### 33. 什么是 LoRA merge？
把 LoRA 增量合并进原权重：

合并后推理不需要额外 LoRA 分支。

#### 34. 什么是 LoRA unmerge？
把已经合并的 LoRA 增量从权重中移除，恢复 base weight 与 adapter 分离状态。用于切换 adapter 或继续管理多个任务版本。

#### 35. merge 后推理和不 merge 推理有什么区别？
merge 后前向就是普通线性层，推理更简单、可能更快。不 merge 更灵活，可以动态切换多个 adapter，但每次前向有额外 LoRA 分支计算。

#### 36. 多个 LoRA adapter 如何服务不同任务？有什么风险？
可以同一 base model 加载不同 adapter，按任务切换。风险包括 adapter 版本和 base model 不匹配、多 adapter 叠加冲突、scaling 不一致、任务格式冲突。

#### 37. 为什么 merge 后继续训练可能导致状态混乱？
merge 改变了 base weight。如果继续训练同时保留 adapter 状态，可能重复计算增量或把 base 和 adapter 边界混淆。训练前要明确当前是 merged 还是 unmerged 状态。

#### 38. LoRA 与量化模型结合时需要注意什么？
base model 可能是 4bit/8bit 量化，LoRA 参数通常用 fp16/bf16 训练。要注意 dtype、梯度 checkpoint、量化层是否支持 LoRA、optimizer 只更新 LoRA 参数，以及保存/加载流程。

### 五、LoRA 方法对比
#### 39. LoRA 和全量微调相比，优势和劣势分别是什么？
LoRA 优势是参数少、显存低、存储小、部署灵活；劣势是表达能力受低秩和 target modules 限制。全量微调能力强，但成本高、存储重、更易遗忘。

#### 40. LoRA 和 Adapter 的核心区别是什么？
Adapter 插入新的小模块；LoRA 给已有线性层添加低秩权重增量。Adapter 通常增加额外前向路径，LoRA 可 merge 到原权重。

#### 41. LoRA 为什么通常比 Adapter 更容易做到无额外推理延迟？
因为 LoRA 增量可以合并到原线性层权重中，merge 后前向结构与普通线性层一致。Adapter 即使训练参数少，通常仍是额外模块，推理时要额外计算。

#### 42. LoRA 和 Prompt Tuning 的区别是什么？
Prompt Tuning 学习输入前的连续 soft prompt，不改模型权重。LoRA 学习线性层权重增量。LoRA 通常表达能力更强，Prompt Tuning 参数可能更少。

#### 43. LoRA 和 Prefix Tuning 的区别是什么？
Prefix Tuning 通常为每层 attention 学习 prefix key/value，影响注意力上下文。LoRA 学习投影矩阵的低秩增量，直接改变模型线性变换。

#### 44. 在小数据场景中 LoRA 有什么优势和风险？
优势是可训练参数少，过拟合风险低于全量微调，训练成本低。风险是数据质量差时仍会过拟合格式或噪声，rank/alpha 过大也会过拟合。

#### 45. 在领域迁移很大的场景中，LoRA 可能不如全量微调的原因是什么？
领域差异很大时，模型可能需要更广泛的权重更新。低秩增量和有限 target modules 可能容量不足，无法充分适配新知识、风格或推理模式。

### 六、AdaLoRA
#### 46. AdaLoRA 解决了普通 LoRA 的什么问题？
普通 LoRA 通常给所有目标模块固定 rank，可能浪费参数或容量不足。AdaLoRA 解决参数预算分配问题，自适应给重要模块或方向更多 rank。

#### 47. 为什么固定 rank 可能不是最优？
不同层、不同矩阵对任务的重要性不同。统一 rank 会让不重要模块浪费容量，重要模块 rank 不够。自适应 rank 更能利用固定参数预算。

#### 48. AdaLoRA 的核心思想是什么？
训练过程中估计不同低秩方向的重要性，在总参数预算约束下保留重要方向、裁剪不重要方向，从而形成自适应 rank 分配。

#### 49. AdaLoRA 如何理解“参数预算分配”？
把总可训练低秩容量看成预算。AdaLoRA 决定预算分给哪些层、哪些矩阵、哪些 rank 方向，使同样参数量带来更好效果。

#### 50. AdaLoRA 和 LoRA 的主要区别是什么？
LoRA 通常使用固定 rank。AdaLoRA 动态调整 rank 分配，并根据重要性裁剪或保留低秩方向。它更复杂，但参数利用可能更高效。

#### 51. AdaLoRA 中重要性分数大致用于什么？
用于衡量某个 rank 方向或参数对任务损失的重要程度，指导保留、裁剪或重新分配 rank 预算。

#### 52. AdaLoRA 更适合哪些场景？
适合参数预算严格、任务复杂、不同层重要性差异明显、希望在相同参数量下获得更好性能的场景。

#### 53. AdaLoRA 的工程复杂度相比 LoRA 有什么变化？
更复杂。需要实现重要性估计、rank 调度、预算分配和裁剪逻辑。普通 LoRA 更简单、生态更成熟。

### 七、实验设计与评测
#### 54. 做一个 LoRA 实验报告，至少应该记录哪些配置？
记录 base model、tokenizer、chat template、数据集、train/dev/test 划分、target modules、rank、alpha、dropout、学习率、batch size、grad accumulation、训练步数、指标、badcase、随机种子和硬件。

#### 55. 如何判断 LoRA 微调是真的提升，而不是评测泄漏？
使用严格独立测试集，检查去重和数据泄漏，确保评测集未进入训练；做 base model 对比；看多指标和 badcase；必要时人工评估或外部 benchmark。

#### 56. LoRA 训练 loss 下降但验证效果不好，可能有哪些原因？
过拟合、数据质量差、评测分布不同、rank/alpha 过大、学习率过大、模板不一致、label mask 错误、训练和验证 tokenizer/chat template 不一致。

#### 57. LoRA 训练后模型格式遵循变好但通用能力下降，如何分析？
可能过拟合特定格式或数据分布，出现能力偏移。可评估通用 benchmark、混入通用数据、降低学习率/epoch/rank、改进数据多样性。

#### 58. 选择 LoRA target modules 时，你会如何做消融实验？
固定数据和超参，比较qv、qkvo、attention-only、MLP-only、all-linear 等配置，记录参数量、训练成本、验证指标和 badcase，选择性价比最优方案。

#### 59. 如何比较 LoRA 和全量微调的性价比？
比较最终指标、训练显存、训练时间、可训练参数量、checkpoint 大小、部署复杂度、通用能力保持、badcase 和多任务管理成本。

#### 60. 如何评估不同 rank 的效果？
设置多个 rank，如 4/8/16/32，其他配置不变。比较验证指标、过拟合程度、训练速度、显存、checkpoint 大小和推理效果。注意 rank 与 alpha/target modules 交互。

### 八、工程排错与面试追问
#### 61. 如果 LoRA 训练后输出几乎和 base model 一样，可能是什么原因？
可能 LoRA 未注入、target module 名称错误、adapter 未加载、学习率太小、rank 太低、训练步数不足、label mask 全部 ignore、数据格式错误或 merge 状态错误。

#### 62. 如果 LoRA 训练很快过拟合，可能如何调整？
减少 epoch，降低 rank/alpha，增加 dropout，降低学习率，清洗数据，增加验证集，混入多样数据，早停，减小 target modules 范围。

#### 63. 如果加载 adapter 后报 target module 找不到，如何排查？
检查 base model 架构和训练时是否一致；打印模块名；核对 PEFT 配置中的 target_modules；不同模型可能叫q_proj、c_attn、query_key_value等。

#### 64. 如果推理结果和训练时验证结果差异很大，LoRA 相关原因有哪些？
adapter 未加载或加载错；base model 版本不一致；tokenizer/chat template 不一致；merge 后 dtype/量化出错；推理参数差异；训练时使用了不同 prompt 格式。

#### 65. 如果 adapter 文件很小，这是正常的吗？为什么？
正常。LoRA adapter 只保存低秩 A/B 参数和配置，不保存完整 base model，因此通常很小。

#### 66. LoRA 是否能完全避免灾难性遗忘？
不能完全避免。冻结 base weight 有助于保持原能力，但 LoRA 分支仍会改变输出分布。过强 LoRA、数据偏斜或 merge 后使用都可能导致能力偏移。

#### 67. LoRA 是否只适用于语言模型？
不是。LoRA 可用于任何包含线性/卷积等可低秩适配权重的神经网络，包括视觉模型、多模态模型、扩散模型等。

#### 68. 面试官问“LoRA 为什么有效”，你会如何回答？
大模型预训练后已有丰富能力，下游任务适配所需更新可能处于低维子空间。LoRA 用低秩矩阵学习权重增量，在少量参数下捕捉主要任务变化，同时保留 base model 能力和降低训练成本。

#### 69. 面试官问“LoRA 的参数量怎么算”，你会如何回答？
如果原线性层W是[d_out,d_in]，全量参数是d_out*d_in。LoRA 用A:[r,d_in]和B:[d_out,r]，参数量是：

#### 70. 请总结第七天 LoRA/Ada
LoRA 的完整知识链路。
大模型全量微调成本高，因此使用 PEFT。LoRA 冻结原模型权重W，只训练低秩增量Delta W=BA*alpha/r，参数量从d_out*d_in降为r(d_in+d_out)。LoRA 常加到 attention 和 MLP 线性层，关键超参是 rank、alpha、dropout、target modules。训练后只保存 adapter，推理时可加载 adapter 或 merge 到原权重。AdaLoRA 进一步认为不同模块需要不同 rank，通过重要性估计自适应分配参数预算，提高同等参数量下的效果。
