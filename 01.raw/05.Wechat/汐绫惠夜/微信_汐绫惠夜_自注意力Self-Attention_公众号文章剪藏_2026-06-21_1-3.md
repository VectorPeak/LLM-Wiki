---
title: "微信_汐绫惠夜_自注意力Self-Attention_公众号文章剪藏_2026-06-21_1-3"
source: "/api/v1/wechat_mp/web/fetch_mp_article_detail_html"
author:
  - "汐绫惠夜"
published: "2026-05-22"
created: 2026-06-21
description: "TikHub 命中的微信公众号文章候选，共 3 条，本文档收录 3 条"
tags:
  - "clippings"
  - "wechat"
  - "汐绫惠夜"
---

## 0x01. 一：自注意力Self-Attention
> 发布日期：2026-05-22  
> 原文链接：[一：自注意力Self-Attention](https://mp.weixin.qq.com/s/_-indm9uzApSAqlhyZCaXw)

### 1. 学习定位
 self-attention 是 Transformer 架构的核心机制，也是理解现代大语言模型的入口。它的作用是让序列中每个 token 根据当前输入内容，动态读取同一序列中其他 token 的信息，并形成上下文相关的表示。

 第一天学习的重点集中在 self-attention 的基本原理，而不是 Transformer 的全部细节。需要掌握的范围包括：

 self-attention 的直观含义和计算流程。

 Query、Key、Value 的角色划分。

 scaled dot-product attention 的数学公式。

 attention score、softmax、mask、value 聚合的语义。

 单头 attention 和多头 attention 的张量形状。

 causal mask 与 padding mask 的作用。

 self-attention 的复杂度、并行性和长上下文瓶颈。

 最小 PyTorch 风格实现中的关键细节。

### 2. 序列表示与上下文依赖
 自然语言中的 token 不是孤立存在的。一个 token 的含义经常由上下文决定。同一个词在不同句子中可以表示不同实体、不同语义角色或不同指代关系。模型如果只使用静态 token embedding，就只能得到“词本身”的表示，无法充分表达它在当前句子中的语义。

 序列建模的目标之一，是把每个位置的原始 token 表示转换成上下文相关表示。上下文相关表示不仅包含当前 token 的信息，也包含与当前 token 相关的其他位置的信息。

 传统 RNN 通过时间步递推建模上下文，长距离信息需要一步步传递。CNN 通过局部卷积捕捉邻域模式，长距离交互通常需要堆叠多层。self-attention 采用另一种方式：直接计算序列中任意两个位置之间的相关性，让信息可以在一层内跨任意距离流动。

 核心思想可以概括为：
```text
self-attention = 根据 token 之间的内容相关性，动态分配权重，并对上下文信息做加权聚合。
```
### 3. Self-Attention 的整体流程
 给定输入序列表示 X，self-attention 的计算过程可以分为六步：

 从输入 X 线性投影得到 Q 、 K 、 V。

 用 QK^T 计算每个 query 对所有 key 的匹配分数。

 对匹配分数除以 sqrt(d_k) 做缩放。

 根据任务需要加入 attention mask。

 沿 key 维度做 softmax，得到 attention weights。

 用 attention weights 对 V 加权求和，得到每个位置的新表示。

 流程图如下：
```text
X
|
|-- W_Q --> Q
|-- W_K --> K
|-- W_V --> V

QK^T / sqrt(d_k)
|
+ mask
|
softmax
|
attention weights @ V
|
contextual output
```
在 Transformer 中，self-attention 通常不是单独使用，而是作为 Transformer block 的一个子层，与 residual connection、LayerNorm 或 RMSNorm、MLP/FFN 等模块配合。

### 4. Query、Key、Value
 self-attention 中每个 token 都会生成三种向量：Query、Key、Value。

 Query 表示当前位置想要查找的信息。Key 表示当前位置可以被什么查询匹配。Value 表示当前位置在被关注时实际提供的信息内容。

 可以用检索系统类比：

 Query 类似用户输入的搜索请求。

 Key 类似文档索引或可检索字段。

 Value 类似文档正文或返回内容。

 某个 token 的 Query 会和所有 token 的 Key 计算匹配分数。匹配分数经过 softmax 后变成权重，这些权重再用于聚合所有 token 的 Value。

 Q、K、V 都来自同一个输入 X，这是 self-attention 中 “self” 的含义。它们不是三份不同数据，而是同一份序列表示经过三组不同可学习线性变换得到：
```text
Q = XW_Q
K = XW_K
V = XW_V
```
使用三套投影的原因是匹配关系和信息内容需要解耦。一个 token 作为 Query 时表达“需要什么”，作为 Key 时表达“如何被匹配”，作为 Value 时表达“要传递什么”。如果直接用同一个向量承担所有角色，模型表达能力会受到限制。

### 5. Scaled Dot-Product Attention
 标准 scaled dot-product attention 公式为：
```text
Attention(Q, K, V) = softmax(QK^T / sqrt(d_k))V
```
加入 mask 后，常见形式为：
```text
Attention(Q, K, V) = softmax((QK^T / sqrt(d_k)) + mask)V
```
各部分含义如下：

- QK^T：计算 query 与 key 的点积相似度。
$$
- d_k：key/query 的维度。
$$
- sqrt(d_k)：缩放因子，用于稳定 softmax 输入尺度。
- softmax：将匹配分数转成非负且归一化的注意力权重。
- V：被加权聚合的信息内容。

 attention 的输出是 value 的加权和，而不是 query 或 key 的加权和。Q 和 K 的主要职责是计算位置间的匹配关系，V 才是被读取和传递的信息载体。

### 6. 点积相似度
 点积用于衡量两个向量的匹配程度。若 query 和 key 在向量空间中方向接近、模长较大，点积值通常更大，表示该 key 对当前 query 更相关。

 对一组 query 和 key 使用矩阵乘法可以一次性得到所有位置两两之间的匹配分数。对于长度为 T 的 self-attention，score 矩阵通常是 T x T：
```text
k1 k2 k3 ... kT
q1....
q2....
q3....
...
qT....
```
第 i 行表示第 i 个 token 作为 query 时对所有 key 的匹配分数。第 i 行第 j 列表示第 i 个 token 对第 j 个 token 的关注强度。

 这种矩阵化计算方式是 Transformer 易于并行训练的重要原因。
$$
### 7. 缩放因子 sqrt(d_k)
$$
 当 query 和 key 的维度 d_k 较大时，点积值的方差会随维度增大。若每一维近似独立且方差相近，则点积可以看作 d_k 个随机变量的和，其方差大致与 d_k 成正比。

 未缩放的点积分数过大时，softmax 会进入饱和区。饱和的 softmax 会产生极端尖锐的分布，最大位置接近 1，其他位置接近 0，导致梯度变小并影响训练稳定性。

 除以 sqrt(d_k) 可以把点积分数拉回更稳定的尺度：
```text
scores = QK^T / sqrt(d_k)
```
缩放因子的本质是数值稳定和优化稳定，不改变 attention 通过相关性聚合信息的核心语义。
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkjsVOjzJ9Uk99F6ibLEFMbwOra9zuC8OkmicYYctHrfibfibs8OuEfBRT2ONXvnQx9owu08QX9ZavBvlNfbx3YdIswxtPdPjicU7pKA/640?wx_fmt=png&from=appmsg)
 为了更透彻地理解，图片中是Attention is all you need原文描述：我们推测 d_k 数值偏大时，点积结果幅值会随之变大。简单理解就是，当维度更大的时候，维度越多，相加的随机项数量越多，叠加后总和绝对值更容易冲高，点积数值量级随之膨胀。幅值过大会让 softmax 输入落入梯度极小饱和区，所以除以 sqrt(d_k) 做幅度归一。

### 8. Softmax 与注意力权重
 softmax 将 attention score 转换为注意力权重。权重具有两个重要性质：

 每个权重非负。

 对同一个 query，所有 key 位置的权重和为 1。

 如果 attention score 的 shape 是：
```text
[B, H, T_q, T_k]
```
softmax 应沿最后一维 T_k 执行：
```text
weights = softmax(scores, dim=-1)
```
这表示每个 query 位置都会在所有 key 位置上形成一个注意力分布。

 softmax 后的权重再乘以 V：
```text
output = weights @ V
```
输出可以理解为对 value 信息的动态加权平均。不同输入样本、不同位置、不同层和不同 head 都可能产生不同的权重分布。

### 9. 单头 Attention 的张量形状
 设输入 X 的 shape 为：
```text
X: [B, T, d_model]
```
其中：

- B
 是 batch size。

- T
 是序列长度。

- d_model
 是模型隐藏维度。

 单头 self-attention 中，线性投影参数常写为：
```yaml
W_Q: [d_model, d_k]
W_K: [d_model, d_k]
W_V: [d_model, d_v]
```
投影后：
```text
Q = XW_Q: [B, T, d_k]
K = XW_K: [B, T, d_k]
V = XW_V: [B, T, d_v]
```
计算 attention score：
```text
QK^T: [B, T, T]
```
softmax 后：
```text
attention weights: [B, T, T]
```
聚合 value：
```text
output = attention weights @ V: [B, T, d_v]
```
在 self-attention 中， T_q = T_k = T。在 cross-attention 中，query 和 key/value 可以来自不同序列，因此 T_q 和 T_k 可以不同。

### 10. Multi-Head Attention
 单头 attention 只在一个表示子空间中计算相关性。multi-head attention 将模型维度拆分成多个 head，让模型在多个子空间中并行学习不同类型的关系。

 标准公式：
```text
head_i = Attention(QW_i^Q, KW_i^K, VW_i^V)
MultiHead(Q, K, V) = Concat(head_1, ..., head_h)W_O
```
其中：

- h
 是 head 数。

 每个 head 有独立的 Q/K/V 投影。

- Concat
 将所有 head 的输出拼接。

- W_O
 将拼接后的表示重新映射回 d_model。

 常见设置为：
```text
d_head = d_model / num_heads
```
这样多个 head 拼接后仍然回到 d_model 维度，整体计算量与单头完整维度 attention 保持同阶。

 示例：
```text
B = 2
T = 4
d_model = 8
num_heads = 2
d_head = 4
```
shape 变化：
```yaml
X: [2, 4, 8]
Q/K/V after linear: [2, 4, 8]
reshape: [2, 4, 2, 4]
transpose: [2, 2, 4, 4]  # [B, H, T, d_head]
score: [2, 2, 4, 4]
weights: [2, 2, 4, 4]
head output: [2, 2, 4, 4]
transpose + concat: [2, 4, 8]
output projection: [2, 4, 8]
```
多头注意力提升了模型表达能力，但 head 数并非越多越好。head 数增加会降低每个 head 的 d_head，若 d_head 过小，单个 head 的表达能力可能不足。实际模型需要在效果、计算效率、显存和硬件实现之间折中。

### 11. Attention Mask
 attention mask 用于控制哪些位置可以被关注。mask 通常在 softmax 前加入 attention score，使被屏蔽的位置在 softmax 后权重为 0。

 常见写法：
```text
scores = scores.masked_fill(mask == 0, -inf)
weights = softmax(scores, dim=-1)
```
使用 -inf 或极大负数的原因是：
```text
exp(-inf) = 0
```
在过了Softmax的exp后就会变成0，因此被屏蔽位置不会参与 value 聚合。

 mask 通常需要能 broadcast 到 attention score 的形状：
```text
scores: [B, H, T_q, T_k]
```
padding mask 常见形状可以是：
```text
[B, 1, 1, T_k]
```
causal mask 常见形状可以是：
```text
[1, 1, T_q, T_k]
```
两类 mask 可以合并使用。

### 12. Causal Mask
 decoder-only 语言模型采用自回归训练目标。每个位置只能依赖自己和之前的 token，不能看到未来 token。causal mask 用来保证这种因果约束。

 长度为 5 的 causal mask 允许关注位置如下：
```text
k1 k2 k3 k4 k5
q1    1  0  0  0  0
q2    1  1  0  0  0
q3    1  1  1  0  0
q4    1  1  1  1  0
q5    1  1  1  1  1
```
这是一个下三角结构。第 i 行只允许关注 0..i 的 key 位置。

 causal mask 避免训练时的信息泄漏。若不加 causal mask，当前位置可以看到未来 token，训练 loss 会不真实地降低，但推理生成时未来 token 不存在，训练和推理条件不一致。

 causal mask 不影响训练并行性。训练时仍可以一次性输入完整序列，矩阵乘法仍然并行执行；mask 只是在 attention score 中屏蔽未来位置。

### 13. Padding Mask
 batch 训练通常需要把不同长度的样本 padding 到同一长度。padding token 是补齐用的无效内容，不应该被真实 token 关注，也不应该参与语言模型 loss 或分类 loss。

 padding mask 的作用是屏蔽 padding 对应的 key 位置。例如：
```yaml
真实序列: 我 爱 NLP
padding 后: 我 爱 NLP <pad> <pad>
```
真实 token 的 query 不应该从 <pad> 的 value 中读取信息。实现时通常把 padding key 位置对应的 score 置为 -inf。

 在 decoder-only LM 中，padding mask 和 causal mask 经常同时存在：

 padding mask 屏蔽无效补齐位置。

 causal mask 屏蔽未来位置。

### 14. Self-Attention 与位置信息
 纯 self-attention 本身不包含顺序信息。若没有位置编码，attention 主要根据 token 内容计算相关性，对输入顺序的区分能力不足。

 Transformer 需要显式引入位置相关信息。常见方式包括：

 sinusoidal positional encoding

 learned positional embedding

 RoPE

 ALiBi

 位置机制让模型可以区分相同 token 集合的不同排列，并学习距离、先后顺序、相对位置等结构信息。

 self-attention 负责内容相关的信息聚合，位置编码负责提供顺序结构。二者共同构成 Transformer 序列建模能力的重要基础。

### 15. 复杂度与并行性
$$
self-attention 的核心计算包括 QK^T 和 attention weights @ V。
$$
 设序列长度为 T，模型维度为 d_model。attention 核心计算复杂度近似为：
```text
O(T^2 d_model)
```
attention score 矩阵的空间复杂度近似为：
```text
O(T^2)
```
在 multi-head attention 中，score 的实际形状通常是：
```text
[B, H, T, T]
```
序列长度翻倍时， T x T score 矩阵的元素数量变为原来的 4 倍。这使 self-attention 在长上下文场景中成本显著增加。

 Transformer 的训练并行性来自矩阵化计算。所有位置的 Q/K/V 投影可以并行完成，所有 query-key 匹配也可以通过大矩阵乘法并行完成。相比 RNN 的顺序递推，这种计算模式更适合 GPU/TPU。

### 16. 与 RNN 和 CNN 的对比
 RNN、CNN、self-attention 都可以用于序列建模，但建模方式不同。

 RNN 按时间步递推，天然适合流式输入，但序列维度并行性较弱，长距离依赖需要经过多步传播。

 CNN 通过局部窗口提取特征，并行性较好，但单层感受野有限。长距离依赖需要堆叠多层、扩大卷积核或使用膨胀卷积。

 self-attention 允许任意两个位置在一层内直接交互，长距离路径短，并行性强。主要代价是序列长度二次复杂度。

 对比总结：
```yaml
RNN: 顺序递推，流式友好，并行性弱。
CNN: 局部建模，并行性好，长距离依赖依赖层数扩展。
Self-attention: 全局动态建模，并行性好，长序列成本高。
```
### 17. 最小实现参考
 下面是 scaled dot-product attention 的 PyTorch 风格伪代码：
```python
import math
import torch
import torch.nn.functional as F

def scaled_dot_product_attention(q, k, v, attn_mask=None, dropout_p=0.0, training=True):
    # q: [B, H, T_q, d_head]
    # k: [B, H, T_k, d_head]
    # v: [B, H, T_k, d_v]
    d_head = q.size(-1)

    scores = torch.matmul(q, k.transpose(-2, -1)) / math.sqrt(d_head)

    if attn_mask is not None:
        scores = scores.masked_fill(attn_mask == 0, float("-inf"))

    weights = torch.softmax(scores, dim=-1)
    weights = F.dropout(weights, p=dropout_p, training=training)

    out = torch.matmul(weights, v)
    return out, weights
```
实现要点：

- k.transpose(-2, -1)
 将 key 的最后两个维度从 [T_k, d_head] 变为 [d_head, T_k]。

- scores
 的 shape 是 [B, H, T_q, T_k]。

 softmax 使用 dim=-1，表示每个 query 对所有 key 归一化。

 mask 必须能 broadcast 到 score 的形状。

 attention dropout 通常作用在 softmax 后的 attention weights 上。

 输出 shape 是 [B, H, T_q, d_v]。

### 18. 数值稳定与调试要点
 attention 实现中常见的数值问题包括 NaN、softmax 饱和、mask 语义反转和 shape 错位。

 NaN 常见来源：

 某一行 query 对应的所有 key 都被 mask，导致 softmax 输入全为 -inf。

 mixed precision 下使用过大的负数造成溢出或 kernel 不兼容。
$$
忘记除以 sqrt(d_head)，score 过大。
$$
 上游 Q/K/V 已经出现 inf 或 NaN。

 学习率过大或归一化层异常导致激活爆炸。

 shape 错误常见来源：
$$
multi-head reshape 后没有 transpose 到 [B, H, T, d_head]。
$$
- K
 转置维度错误。

 mask 维度无法正确 broadcast。

 softmax 沿错误维度执行。

 最小调试策略：

 用很小的 B 、 H 、 T 构造可打印样例。

 打印 score、mask、weights 的 shape。

 检查 softmax 后每行和是否接近 1。

 检查 mask 位置的权重是否接近 0。

 与框架内置 scaled_dot_product_attention 在无 dropout 场景下对齐数值。

### 19. Attention 权重与可解释性
 attention weights 表示某一层某个 head 中，每个 query 对不同 value 的聚合权重。它可以作为模型行为分析的线索，但不能直接等同于模型最终决策的因果解释。

 Transformer 的最终输出经过多层 attention、MLP、残差连接和归一化。某个 head 的高权重只说明该层该 head 在聚合信息时偏向某个位置，不足以证明该位置对最终预测具有决定性影响。

 更严谨的解释需要结合：

 token masking 或遮挡实验

 反事实替换

 gradient-based attribution

 head ablation

 activation patching

 面试中适合表述为：attention 权重有分析价值，但不是完整解释。

### 20. 第一层知识闭环
 self-attention 的知识闭环可以压缩为下面几条：
```text
输入 X 通过三套线性投影得到 Q、K、V。
Q 和 K 的点积产生 token 之间的匹配分数。
分数除以 sqrt(d_k) 后进入 softmax，形成每个 query 对所有 key 的权重分布。
mask 用来屏蔽 padding 或未来位置。
权重乘 V 得到上下文相关表示。
multi-head attention 在多个子空间中并行执行上述过程。
self-attention 的优势是全局交互和并行训练，限制是序列长度二次复杂度。
```
掌握以上知识后，可以进入Self-Attention题单文章进行自测。

## 0x02. 一：自注意力Self-Attention自测题
> 发布日期：2026-05-22  
> 原文链接：[一：自注意力Self-Attention自测题](https://mp.weixin.qq.com/s/4I_68HFipqsUIYzgIUDSTQ)

### 覆盖范围
 self-attention 的直观含义和 Transformer 中的作用

 Query、Key、Value 的来源、含义和矩阵形状

 scaled dot-product attention 的完整计算流程

 softmax、缩放因子、mask、加权求和的作用

 causal mask 与 padding mask 的区别

 multi-head attention 的动机、公式和张量变换

 self-attention 的时间复杂度、空间复杂度和并行性

 从公式到 PyTorch 伪代码的实现细节

 面试中常见的追问、易错点和白板推导

### 一、基础概念题
 请用 1 分钟解释什么是 self-attention。它解决了序列建模里的什么问题？

 self-attention 中的 “self” 体现在哪里？它和普通 attention、cross-attention 有什么区别？

 在 Transformer 里，一个 token 的输出表示为什么需要依赖序列中其他 token？

 Query、Key、Value 分别代表什么？请用检索系统或问答系统类比解释。

 为什么 Q、K、V 都可以从同一个输入 X 通过不同线性变换得到？为什么不直接用 X 做注意力？

 scaled dot-product attention 的公式是什么？请解释公式中每一项的作用。

 为什么用 QK^T 计算相关性？点积大意味着什么？点积注意力和余弦相似度有什么关系？

 为什么要除以 sqrt(d_k)？如果不做缩放，softmax 和梯度会出现什么问题？

 为什么要对 attention score 做 softmax？softmax 是沿哪个维度做的？

 为什么最终输出是 attention weights 对 V 的加权和，而不是对 Q 或 K 的加权和？

 self-attention 本身是否知道 token 的顺序？如果不知道，Transformer 如何引入位置信息？

 self-attention 和 RNN、CNN 相比，在长距离依赖建模上有什么优势和代价？

### 二、公式推导与张量形状题
 给定输入 X 的 shape 为 [B, T, d_model]，单头 self-attention 中 W_Q、W_K、W_V 的常见 shape 是什么？Q、K、V 的 shape 是什么？

 在单头 attention 中，QK^T、softmax 后的 attention weights、最终输出 O 的 shape 分别是什么？

 给定 B=2, T=4, d_model=8, num_heads=2，且 d_head=4，请写出 multi-head attention 中从 X 到输出的每一步 shape。

 为什么 attention weight 矩阵通常是 [T, T]？第 i 行、第 j 列分别表示什么含义？

 对一个长度为 4 的序列，请画出不带 causal mask 的 attention score 矩阵，以及 decoder causal mask 后允许关注的位置。

 如果 QK^T 得到的 score 为 [2, 1, 0]，softmax 后三个位置的权重大致有什么相对关系？这说明 attention 在做什么？

 如果 attention weights 的每一行没有归一化为 1，会带来什么问题？

 如果把 softmax 放在乘 V 之后，会发生什么概念性错误？

 在 batch 训练中，不同样本长度不同。padding token 如何影响 attention？应该如何处理？

 attention mask 的 shape 通常如何与 [B, H, T_q, T_k] 的 attention score 进行广播？

### 三、mask 与自回归生成题
 decoder-only 语言模型为什么必须使用 causal mask？

 causal mask 为什么通常是下三角矩阵？请写出长度为 5 时允许关注的位置。

 causal mask 是在 softmax 前加，还是 softmax 后乘？为什么？

 mask 中为什么常用 -inf 或很大的负数，而不是 0？

 padding mask 和 causal mask 的目的分别是什么？二者可以同时存在吗？

 训练 decoder-only LM 时已经用了 causal mask，为什么仍然可以并行计算整段序列？

 推理时如果一次只生成一个新 token，新 token 的 Q、K、V 分别如何参与 attention？

 如果 causal mask 写反了，会出现什么训练或评测异常？

### 四、多头注意力题
 multi-head attention 相比 single-head attention 的核心动机是什么？

 请写出 multi-head attention 的公式，并解释 concat 和 W_O 的作用。

 为什么多头注意力通常把 d_model 切成多个 d_head，而不是每个 head 都使用完整的 d_model？

- num_heads
 越多一定越好吗？head 数太多可能带来什么问题？

 不同 attention head 是否一定学到可解释的语言结构？面试中应该如何谨慎回答？

 multi-head attention 中最常见的 shape bug 是什么？请举例说明。

### 五、复杂度与并行性题
 self-attention 的时间复杂度和空间复杂度是多少？请分别说明和 T 、 d_model 的关系。

 当序列长度 T 翻倍时，attention score 矩阵的计算量和显存大约如何变化？

 为什么 Transformer 比 RNN 更容易并行训练？

 self-attention 的主要瓶颈是什么？长上下文场景为什么会更困难？

 对比 RNN、CNN、self-attention：它们在长距离依赖、并行性、路径长度上的区别是什么？

 如果面试官问“self-attention 是不是一定比 RNN 好”，你会如何回答？

### 六、代码实现与调试题
 请写出 scaled dot-product attention 的 PyTorch 风格伪代码，要求包含 QK^T、缩放、mask、softmax、dropout、乘 V。

- torch.matmul(Q, K.transpose(-2, -1))
 中为什么转置的是最后两个维度？

 在 PyTorch 中，为什么通常用 masked_fill(mask == 0, -inf) 处理 mask？

 mixed precision 下使用 -inf 或很大负数时要注意什么？

 attention dropout 应该作用在哪里？它和普通 residual dropout 有什么区别？

 如果模型输出出现 NaN，attention 相关实现中有哪些排查点？

 如果 attention weights 几乎是均匀分布，可能有哪些原因？

 如果 attention weights 极端 one-hot，可能有哪些原因和风险？

### 七、白板推导与面试追问题
 请从输入 token embedding 开始，完整讲一遍 self-attention 如何得到每个位置的新表示。

 面试官让你只用一句话解释 self-attention，你会怎么说？

 面试官追问：“Q、K、V 只是三个线性层，为什么能学到语义关系？”你如何回答？

 面试官追问：“如果所有 token 都能互相看，会不会信息泄漏？”你如何区分 encoder 和 decoder 的情况？

 面试官追问：“attention score 高是否代表模型真的在解释这个 token？”你如何回答？

 请设计一个最小数值例子，说明某个 token 如何通过 attention 聚合另一个 token 的信息。

 如果要手写一个最小 Transformer block，self-attention 前后还需要哪些模块配合？

 为什么 self-attention 输出后还要经过 output projection W_O？

 请解释“attention 是内容寻址的动态加权聚合”这句话。

 对第一天学习内容做一次总结：self-attention 的核心流程、核心公式、核心优势、核心限制分别是什么？

### 八、加分追问
 self-attention 和 cross-attention 在机器翻译 encoder-decoder Transformer 中分别出现在哪里？

 decoder-only 模型中，为什么 self-attention 加 causal mask 后就可以做 next token prediction？

 为什么 attention 需要位置编码配合？如果去掉位置编码会发生什么？

 为什么说 self-attention 的 attention weights 是输入相关的动态权重，而 CNN 卷积核是训练后固定的局部权重？

 请解释 PyTorch scaled_dot_product_attention 接口中的 is_causal 和 attn_mask 各自适合什么场景。

 如果让你在面试中实现 attention，你会如何验证自己的实现是正确的？

## 0x03. 一：自注意力Self-Attention自测题答案
> 发布日期：2026-05-22  
> 原文链接：[一：自注意力Self-Attention自测题答案](https://mp.weixin.qq.com/s/JmpEYWh0ETFXP_OXjIDQRw)

### 参考资料
 Attention Is All You Need: https://arxiv.org/abs/1706.03762

 PyTorch scaled_dot_product_attention: https://docs.pytorch.org/docs/2.12/generated/torch.nn.functional.scaled_dot_product_attention.html

 PyTorch MultiheadAttention: https://docs.pytorch.org/docs/2.12/generated/torch.nn.MultiheadAttention.html

 The Annotated Transformer: https://nlp.seas.harvard.edu/annotated-transformer/

### 学习标准
 合格：能写出 softmax(QK^T / sqrt(d_k))V，能解释 Q/K/V、mask 和复杂度。

 良好：能说清楚 shape、缩放原因、causal mask、multi-head 的动机和常见实现细节。

 优秀：能从数值稳定性、梯度、长上下文瓶颈、并行性、代码调试和面试追问角度完整回答。

### 一、基础概念题
#### 1. 请用 1 分钟解释什么是 self-attention。它解决了序列建模里的什么问题？
 self-attention 是一种让序列中每个 token 根据当前输入内容，动态聚合同一序列中其他 token 信息的机制。对每个位置，它会计算该位置和其他位置的相关性，把相关性变成权重，再用这些权重对其他 token 的 value 表示做加权求和，得到新的上下文表示。

 它解决的核心问题是：一个 token 的含义往往依赖上下文。例如“苹果发布了新品”和“我吃了苹果”中，“苹果”的语义不同，需要结合其他词判断。相比 RNN，self-attention 能让任意两个位置直接交互，路径长度短，并且训练时可以并行处理整段序列。

 关键得分点：动态权重、上下文聚合、任意位置交互、并行性。

#### 2. self-attention 中的 “self” 体现在哪里？它和普通 attention、cross-attention 有什么区别？
 “self” 体现在 Q、K、V 都来自同一个输入序列 X，只是经过不同线性投影。例如句子内部每个 token 都拿自己的 query 去和同一句子中所有 token 的 key 计算相关性。

 普通 attention 是更广义的概念，不要求 Q、K、V 来自同一来源。cross-attention 中，Q 通常来自一个序列，K 和 V 来自另一个序列，例如机器翻译 decoder 用当前目标端状态作为 Q，去 attend encoder 输出的源语言 K/V。

 关键区别：self-attention 是序列内部交互；cross-attention 是一个序列查询另一个序列的信息。

#### 3. 在 Transformer 里，一个 token 的输出表示为什么需要依赖序列中其他 token？
 自然语言里 token 的语义、句法功能、指代关系通常由上下文决定。孤立 token embedding 只表示静态词义，不能表示当前语境。例如“bank”可能是银行或河岸，“它”需要前文实体确定指代。self-attention 让每个 token 依据上下文重新编码，输出表示不再只是词本身，而是融合了相关上下文后的表示。

 面试回答时可以补一句：Transformer block 的目标不是为每个位置生成独立 embedding，而是生成 context-aware representation。

#### 4. Query、Key、Value 分别代表什么？请用检索系统或问答系统类比解释。
 Query 表示“我想找什么信息”，Key 表示“我能被什么查询匹配到”，Value 表示“如果我被关注，实际提供什么内容”。类比检索系统：用户查询是 Query，文档索引字段是 Key，文档正文或返回内容是 Value。

 在 self-attention 中，每个 token 都会产生自己的 Q、K、V。某个 token 的 Q 会和所有 token 的 K 做匹配，得到注意力权重，然后用这些权重汇总所有 token 的 V。

 关键点：Q/K 用来算权重，V 是被聚合的信息载体。

#### 5. 为什么 Q、K、V 都可以从同一个输入 X 通过不同线性变换得到？为什么不直接用 X 做注意力？
 因为同一个 token 在不同角色下需要表达不同信息。作为 Query 时，它表达“当前位置需要什么”；作为 Key 时，它表达“当前位置能匹配什么”；作为 Value 时，它表达“当前位置要传递什么”。用不同线性层可以把同一个输入映射到不同子空间，增加表达能力。

 如果直接用 X，匹配空间和信息传递空间被强行绑定，模型难以分别学习“相关性判断”和“内容聚合”。Q/K/V 分离相当于给模型更灵活的可学习接口。

#### 6. scaled dot-product attention 的公式是什么？请解释公式中每一项的作用。
 公式是：
```text
Attention(Q, K, V) = softmax(QK^T / sqrt(d_k)) V
```
其中 Q 是 query 矩阵，K 是 key 矩阵，V 是 value 矩阵。 QK^T 计算每个 query 对所有 key 的匹配分数； sqrt(d_k) 用来缩放分数，避免维度变大导致点积方差过大； softmax 把分数变成每行和为 1 的权重分布；最后乘 V 得到上下文加权和。

 如果有 mask，通常写成：
```text
softmax((QK^T / sqrt(d_k)) + mask) V
```
mask 中不允许关注的位置加 -inf 或极大负数。

#### 7. 为什么用 QK^T 计算相关性？点积大意味着什么？点积注意力和余弦相似度有什么关系？
 点积衡量两个向量方向和幅值的匹配程度。若 q 和 k 方向相近且模长较大，点积就大，说明这个 key 与当前 query 更匹配。用矩阵乘法 QK^T 可以一次性算出所有 query-key 对的相关性，适合 GPU 并行。

 余弦相似度是归一化后的点积，只看方向相似度，不受向量长度影响。scaled dot-product attention 没有显式做 L2 归一化，向量模长也会影响 score，这是模型可以学习利用的自由度。

#### 8. 为什么要除以 sqrt(d_k)？如果不做缩放，softmax 和梯度会出现什么问题？
 如果 q 和 k 的各维近似独立、均值为 0、方差为 1，那么点积 q dot k 是 d_k 个随机变量之和，方差会随 d_k 增大而增大，约为 d_k。d_k 越大，QK^T 的数值越容易变得很大。

 过大的 score 会让 softmax 进入饱和区：最大位置接近 1，其他位置接近 0，分布过尖，梯度变小，训练不稳定。除以 sqrt(d_k) 后，score 的方差被拉回到更稳定的尺度。

 关键得分点：点积方差随维度增长；softmax 饱和；梯度变小；缩放稳定训练。

#### 9. 为什么要对 attention score 做 softmax？softmax 是沿哪个维度做的？
 softmax 把任意实数 score 转成非负权重，并让每个 query 对所有 key 的权重和为 1。这样输出可以解释为对 value 的加权平均，模型能动态选择重点关注的位置。

 softmax 通常沿 key 维度做。若 attention score shape 是 [B, H, T_q, T_k]，softmax 在最后一维 T_k 上做，表示每个 query 位置对所有 key 位置形成一个分布。

 常见错误是沿 query 维度做 softmax，这会让“每个 key 被多少 query 关注”归一化，语义不对。

#### 10. 为什么最终输出是 attention weights 对 V 的加权和，而不是对 Q 或 K 的加权和？
 Q 和 K 的主要职责是计算匹配关系，V 才是要被传递和聚合的信息内容。可以把 Q/K 理解成“地址匹配”，V 理解成“地址里的内容”。每个 query 根据和 key 的匹配程度，从所有 value 中取信息。

 如果对 Q 加权，相当于聚合查询本身，不是在读取其他位置的信息；如果对 K 加权，也会把匹配索引和内容载体混在一起，表达能力较弱。

#### 11. self-attention 本身是否知道 token 的顺序？如果不知道，Transformer 如何引入位置信息？
 纯 self-attention 不知道顺序。因为如果没有位置编码，对输入 token 做同样的置换，attention 结果也会按相同方式置换，本质上是 permutation equivariant。它能看到 token 内容，但不知道第几个 token 在前、第几个在后。

 Transformer 需要显式引入位置信息，常见方式包括 sinusoidal positional encoding、learned positional embedding、RoPE、ALiBi 等。位置编码让模型区分“我爱你”和“你爱我”这类 token 相同但顺序不同的句子。

#### 12. self-attention 和 RNN、CNN 相比，在长距离依赖建模上有什么优势和代价？
 优势是任意两个位置可以一层内直接交互，长距离依赖路径短；训练时所有位置的 Q/K/V 和 attention score 可以并行计算，不像 RNN 必须按时间步递推。相比 CNN，self-attention 不需要堆很多层才能扩大感受野。

 代价是 attention score 是 [T, T]，时间和显存通常随序列长度平方增长。长上下文时，这个二次复杂度会成为主要瓶颈。

### 二、公式推导与张量形状题
#### 13. 给定输入 X 的 shape 为 [B, T, d_model]，单头 self-attention 中 W_Q、W_K、W_V 的常见 shape 是什么？Q、K、V 的 shape 是什么？
 若单头的维度为 d_k 和 d_v，常见设定是：
```yaml
X:   [B, T, d_model]
W_Q: [d_model, d_k]
W_K: [d_model, d_k]
W_V: [d_model, d_v]
Q = X W_Q: [B, T, d_k]
K = X W_K: [B, T, d_k]
V = X W_V: [B, T, d_v]
```
如果是简化实现，也可能让 d_k = d_v = d_model。在 multi-head 中，通常每个 head 的 d_head = d_model / num_heads。

#### 14. 在单头 attention 中，QK^T、softmax 后的 attention weights、最终输出 O 的 shape 分别是什么？
 对每个 batch：
```yaml
Q: [B, T_q, d_k]
K: [B, T_k, d_k]
V: [B, T_k, d_v]

QK^T:             [B, T_q, T_k]
attention weights: [B, T_q, T_k]
O = weights V:    [B, T_q, d_v]
```
self-attention 中通常 T_q = T_k = T，所以 score 是 [B, T, T]。cross-attention 中 T_q 和 T_k 可以不同。

#### 15. 给定 B=2, T=4, d_model=8, num_heads=2，且 d_head=4，请写出 multi-head attention 中从 X 到输出的每一步 shape。
 典型流程：
```yaml
X: [2, 4, 8]

线性投影后:
Q/K/V: [2, 4, 8]

拆成 heads:
Q/K/V: [2, 4, 2, 4]

为了矩阵乘法转置:
Q/K/V: [2, 2, 4, 4]  # [B, H, T, d_head]

score = Q @ K^T:
score: [2, 2, 4, 4]

weights = softmax(score / sqrt(4)):
weights: [2, 2, 4, 4]

head_out = weights @ V:
head_out: [2, 2, 4, 4]

转回并 concat:
concat: [2, 4, 8]

output projection W_O:
out: [2, 4, 8]
```
面试重点是能说清 transpose 的目的：让每个 head 独立在 [T, d_head] 上做 attention。

#### 16. 为什么 attention weight 矩阵通常是 [T, T]？第 i 行、第 j 列分别表示什么含义？
 self-attention 中每个位置都要作为 query 去看所有位置的 key。序列长度是 T，就有 T 个 query 和 T 个 key，因此权重矩阵是 [T, T]。

 第 i 行表示第 i 个 token 在更新自身表示时，对所有 token 的关注分布。第 i 行第 j 列表示第 i 个 token 对第 j 个 token 的 value 赋予多大权重。

 注意：行归一化后，每一行的和为 1。

#### 17. 对一个长度为 4 的序列，请画出不带 causal mask 的 attention score 矩阵，以及 decoder causal mask 后允许关注的位置。
 不带 causal mask 时，每个位置都能看所有位置：
```text
k1 k2 k3 k4
q1    1  1  1  1
q2    1  1  1  1
q3    1  1  1  1
q4    1  1  1  1
```
decoder causal mask 后，第 i 个位置只能看自己和之前的位置：
```text
k1 k2 k3 k4
q1    1  0  0  0
q2    1  1  0  0
q3    1  1  1  0
q4    1  1  1  1
```
其中 0 的位置会在 softmax 前被加上 -inf 或极大负数。

#### 18. 如果 QK^T 得到的 score 为 [2, 1, 0]，softmax 后三个位置的权重大致有什么相对关系？这说明 attention 在做什么？
 softmax 后第一个位置权重最大，第二个次之，第三个最小。大致比例与 e^2 : e^1 : e^0 成正比，所以第一个位置会获得最多关注。

 这说明 attention 根据 query-key 匹配分数，对不同 value 做不同强度的聚合。它不是平均看所有 token，而是根据当前输入动态分配权重。

#### 19. 如果 attention weights 的每一行没有归一化为 1，会带来什么问题？
 如果不归一化，输出的尺度会随 score 的绝对大小和序列长度变化，训练更不稳定，也很难解释每个 query 对所有 key 的相对关注分布。softmax 的行归一化让输出成为一个相对稳定的加权平均。

 不是说所有 attention 都必须用 softmax，但标准 scaled dot-product attention 使用 softmax 是为了得到非负、归一化、可微的动态权重。

#### 20. 如果把 softmax 放在乘 V 之后，会发生什么概念性错误？
 attention 的目标是先决定“该从哪些位置取信息”，再对这些位置的 value 加权聚合。如果先乘 V，再 softmax，就不再是在 key 维度上形成对 token 位置的权重分布，而是在输出特征维度上做归一化，语义完全变了。

 正确顺序是：先对 QK^T 的每一行做 softmax，得到位置分布，再乘 V。

#### 21. 在 batch 训练中，不同样本长度不同。padding token 如何影响 attention？应该如何处理？
 padding token 不是有效文本。如果不 mask，真实 token 可能 attend 到 padding 的 K/V，padding 位置也可能参与输出和损失，污染表示。

 处理方式是使用 padding mask，让有效 token 不关注 padding key。通常在 attention score 的 padding key 位置加 -inf，使 softmax 后权重接近 0。训练 loss 也应忽略 padding target token。

#### 22. attention mask 的 shape 通常如何与 [B, H, T_q, T_k] 的 attention score 进行广播？
 attention score 常见 shape 是 [B, H, T_q, T_k]。padding mask 可能是 [B, 1, 1, T_k]，表示每个样本哪些 key 位置无效，对所有 head 和 query 位置广播。causal mask 可能是 [1, 1, T_q, T_k]，表示位置因果约束，对 batch 和 head 广播。

 如果两种 mask 同时使用，可以合并成同 shape 的 additive mask，再加到 score 上。

### 三、mask 与自回归生成题
#### 23. decoder-only 语言模型为什么必须使用 causal mask？
 decoder-only LM 的训练目标是 next token prediction，即用当前位置及之前的 token 预测下一个 token。训练时输入是一整段序列，如果不加 causal mask，第 i 个位置就能看到未来 token，模型会信息泄漏，训练 loss 虚低，但生成时无法使用未来信息，效果会崩。

 causal mask 保证第 i 个位置只能关注 <= i 的位置，使训练条件和自回归生成条件一致。

#### 24. causal mask 为什么通常是下三角矩阵？请写出长度为 5 时允许关注的位置。
 因为第 i 个 query 只能看第 i 个及之前的 key。长度为 5 时允许矩阵为：
```text
k1 k2 k3 k4 k5
q1    1  0  0  0  0
q2    1  1  0  0  0
q3    1  1  1  0  0
q4    1  1  1  1  0
q5    1  1  1  1  1
```
这就是下三角结构。实现时通常用 torch.tril 创建。

#### 25. causal mask 是在 softmax 前加，还是 softmax 后乘？为什么？
 标准做法是在 softmax 前加到 score 上，把不允许关注的位置设为 -inf。这样 softmax 后这些位置权重为 0，且允许位置之间重新归一化。

 如果 softmax 后再乘 0，会破坏每一行权重和为 1；除非再做归一化，否则输出尺度会变化。softmax 前 mask 更自然、更稳定。

#### 26. mask 中为什么常用 -inf 或很大的负数，而不是 0？
 mask 的目标是让不允许的位置在 softmax 后权重为 0。如果给 score 加 0，等于没有屏蔽；该位置仍可能获得注意力。加 -inf 后， exp(-inf)=0，softmax 权重为 0。

 工程上有时用 -1e9 或 dtype 能表示的最小值近似 -inf。mixed precision 下要注意不要造成溢出或 NaN。

#### 27. padding mask 和 causal mask 的目的分别是什么？二者可以同时存在吗？
 padding mask 用来屏蔽无效 padding token，避免真实 token attend 到补齐位置。causal mask 用来屏蔽未来 token，避免自回归训练信息泄漏。

 二者可以同时存在。例如 decoder-only LM 训练时，一个 batch 内既有 padding，又要保证每个位置不能看未来。通常把两个 mask 合并后加到 attention score 上。

#### 28. 训练 decoder-only LM 时已经用了 causal mask，为什么仍然可以并行计算整段序列？
 因为 causal mask 只是限制 attention score 中哪些位置可见，但 Q、K、V 的线性投影和整块 QK^T 矩阵乘法仍然可以一次性并行计算。mask 后，每个位置的输出只依赖过去位置，但这些位置的计算图可以同时构建。

 RNN 的时间步依赖是计算顺序上的递推；Transformer 的因果约束是矩阵中的可见性约束，所以更易并行训练。

#### 29. 推理时如果一次只生成一个新 token，新 token 的 Q、K、V 分别如何参与 attention？
 生成第 t 个 token 时，新 token 会产生当前步的 Q、K、V。当前 Q 需要和历史所有 K 以及当前 K 做 attention，聚合历史 V 和当前 V，得到当前输出分布。

 实际系统中通常缓存历史 K/V。这样每步只需要计算新 token 的 Q/K/V，不必重复计算所有历史 token 的 K/V。自回归推理中当前 token 只能 attend 已有上下文，不能看未来。

#### 30. 如果 causal mask 写反了，会出现什么训练或评测异常？
 如果写成上三角允许未来、屏蔽过去，模型会在训练中看到不该看的未来信息，loss 可能异常低，但真实生成效果差。如果把所有未来和当前都屏蔽，可能出现整行全是 -inf，softmax 得到 NaN。若只允许看未来，语言模型会学到不符合推理条件的依赖。

 排查方法：打印小序列的 mask 矩阵，确认第 i 行只能看 0..i。

### 四、多头注意力题
#### 31. multi-head attention 相比 single-head attention 的核心动机是什么？
 multi-head attention 让模型在多个子空间里并行学习不同类型的关系。一个 head 可能偏向局部搭配，另一个 head 可能偏向长距离依赖，还有 head 可能关注句法或实体关系。虽然不要过度解释单个 head，但多头确实提升了模型同时捕捉多种关系模式的能力。

 从计算上看，把 d_model 分成多个 d_head 后，每个 head 独立做 attention，再 concat 回来，整体维度仍是 d_model。

#### 32. 请写出 multi-head attention 的公式，并解释 concat 和 W_O 的作用。
 公式：
```text
head_i = Attention(Q W_i^Q, K W_i^K, V W_i^V)
MultiHead(Q, K, V) = Concat(head_1, ..., head_h) W_O
```
每个 head 有自己的 Q/K/V 投影，学习一个子空间内的注意力模式。Concat 把所有 head 的输出拼回 d_model 维； W_O 是输出投影，用于混合不同 head 的信息，并把拼接结果映射回模型残差路径所需的维度。

#### 33. 为什么多头注意力通常把 d_model 切成多个 d_head，而不是每个 head 都使用完整的 d_model？
 如果每个 head 都使用完整 d_model，计算量和参数量会随 head 数成倍增加。标准做法让 d_head = d_model / h，这样 h 个 head concat 后仍是 d_model，整体计算量大致与单头完整维度 attention 同阶，但表达方式更灵活。

 关键点：多头不是简单堆更多完整 attention，而是在相近计算预算下提供多个表示子空间。

#### 34. num_heads 越多一定越好吗？head 数太多可能带来什么问题？
 不一定。head 数增加会让每个 head 的 d_head 变小。如果 d_head 太小，每个 head 表达能力不足，可能学不到有效关系。head 太多还会带来更复杂的 kernel 调度、通信和显存开销。

 实际模型会在 d_model 、head 数、硬件效率和效果之间折中。面试中不要说“越多越好”，而应说“多头提升多子空间建模能力，但需要合适的 head dimension”。

#### 35. 不同 attention head 是否一定学到可解释的语言结构？面试中应该如何谨慎回答？
 不一定。有些 head 可能呈现可解释模式，如关注前一个 token、标点、实体或依存关系，但 attention 权重不等同于严格解释。模型还有残差、MLP、多层组合，最终决策不能只看某一层某个 head 的权重。

 谨慎回答：attention 可作为分析线索，但不能直接等同于因果解释；需要结合消融、梯度、反事实实验等方法验证。

#### 36. multi-head attention 中最常见的 shape bug 是什么？请举例说明。
 常见 bug 是忘记把 [B, T, H, d_head] 转成 [B, H, T, d_head] 就做矩阵乘法，导致 attention 在错误维度上计算。另一个常见 bug 是 K.transpose 转错维度，例如转了 head 和 sequence 维，而不是最后两个维度。

 正确核心是：
```yaml
Q: [B, H, T_q, d_head]
K: [B, H, T_k, d_head]
score = Q @ K.transpose(-2, -1)
score: [B, H, T_q, T_k]
```
### 五、复杂度与并行性题
#### 37. self-attention 的时间复杂度和空间复杂度是多少？请分别说明和 T 、 d_model 的关系。
 对一个 Transformer layer 的 attention 部分，Q/K/V 线性投影约为 O(T d_model^2)。attention 核心计算 QK^T 和 weights V 约为 O(T^2 d_model)，因为所有 head 的 H * d_head = d_model。

 attention score/weights 显存约为 O(H T^2)，输出和 Q/K/V 约为 O(T d_model)。长序列时， T^2 的 score 矩阵通常是瓶颈。

 简化面试答案：self-attention 对序列长度是二次复杂度，时间约 O(T^2 d_model)，attention 矩阵空间约 O(T^2)。

#### 38. 当序列长度 T 翻倍时，attention score 矩阵的计算量和显存大约如何变化？
 score 矩阵从 T x T 变成 2T x 2T，元素数变为 4 倍。因此 QK^T 和 attention weights 相关显存大约增加 4 倍，attention 核心计算量也大约增加 4 倍。

 这就是长上下文模型训练和推理困难的重要原因。

#### 39. 为什么 Transformer 比 RNN 更容易并行训练？
 RNN 的 hidden state 递推依赖前一时间步，训练时序列维度很难完全并行。Transformer 中每个位置的 Q/K/V 投影可以同时计算，所有 token 两两 attention 可以通过矩阵乘法并行完成。

 即使 decoder 使用 causal mask，也只是屏蔽未来位置，不改变矩阵计算可以并行执行的事实。

#### 40. self-attention 的主要瓶颈是什么？长上下文场景为什么会更困难？
 主要瓶颈是 attention score/weights 的二次复杂度。长上下文时， T^2 会导致显存和计算快速增长。例如 T 增加 4 倍，attention score 元素数增加 16 倍。

 此外，训练时还要保存中间激活用于反向传播；推理时虽然可用 KV cache 减少重复计算，但 KV cache 显存也会随上下文长度线性增长。

#### 41. 对比 RNN、CNN、self-attention：它们在长距离依赖、并行性、路径长度上的区别是什么？
 RNN 按时间递推，并行性弱，长距离信息需要经过很多步传递，路径长。CNN 可以并行，但局部卷积的感受野有限，需要堆叠多层或扩大卷积核捕捉长距离关系。self-attention 可以并行，并且任意两个 token 一层内直接交互，路径短。

 代价是 self-attention 对序列长度有二次复杂度，长序列成本高。

#### 42. 如果面试官问“self-attention 是不是一定比 RNN 好”，你会如何回答？
 不是。self-attention 在大规模并行训练、长距离依赖和表达能力上非常强，是现代 LLM 的核心模块。但 RNN 在流式、低延迟、小模型、极长序列线性处理等场景仍可能有优势。具体选择取决于任务、数据规模、硬件和延迟约束。

 成熟回答要避免绝对化：Transformer 成功不是只因为 attention，还包括规模化训练、残差、归一化、优化器、数据和硬件生态。

### 六、代码实现与调试题
#### 43. 请写出 scaled dot-product attention 的 PyTorch 风格伪代码，要求包含 QK^T、缩放、mask、softmax、dropout、乘 V。
```python
import math
import torch
import torch.nn.functional as F

def scaled_dot_product_attention(q, k, v, attn_mask=None, dropout_p=0.0, training=True):
    # q: [B, H, T_q, d_head]
    # k: [B, H, T_k, d_head]
    # v: [B, H, T_k, d_v]
    d_head = q.size(-1)
    scores = torch.matmul(q, k.transpose(-2, -1)) / math.sqrt(d_head)

    if attn_mask is not None:
        # attn_mask should be broadcastable to [B, H, T_q, T_k]
        scores = scores.masked_fill(attn_mask == 0, float("-inf"))

    weights = torch.softmax(scores, dim=-1)
    weights = F.dropout(weights, p=dropout_p, training=training)
    out = torch.matmul(weights, v)
    return out, weights
```
如果使用 additive mask，也可以 scores = scores + mask，其中 mask 中屏蔽位置已经是 -inf。

#### 44. torch.matmul(Q, K.transpose(-2, -1)) 中为什么转置的是最后两个维度？
 因为 Q 和 K 的 shape 通常是 [B, H, T, d_head]。我们希望每个 head 内计算每个 query token 与每个 key token 的点积，即 [T_q, d_head] @ [d_head, T_k]，得到 [T_q, T_k]。

 transpose(-2, -1) 把 K 从 [B, H, T_k, d_head] 变成 [B, H, d_head, T_k]，保留 batch 和 head 维度不动。

#### 45. 在 PyTorch 中，为什么通常用 masked_fill(mask == 0, -inf) 处理 mask？
 因为要让被屏蔽位置在 softmax 后权重为 0。 masked_fill 可以把不允许关注的位置替换成 -inf，然后 softmax 时这些位置的指数为 0。

 需要注意不同 API 的 mask 语义可能不同：有的约定 True 表示保留，有的约定 True 表示屏蔽。工程中要读文档并写单元测试确认。

#### 46. mixed precision 下使用 -inf 或很大负数时要注意什么？
 float16/bfloat16 下数值范围和 kernel 行为不同。使用过大的负数可能溢出，整行都被 mask 时 softmax 可能产生 NaN。常见做法是使用框架内置 attention API，或使用 dtype 可表示的较小值，并确保每一行至少有一个有效位置。

 调试时检查：mask 是否全屏蔽、score 是否已有 inf/NaN、softmax 前后是否数值正常。

#### 47. attention dropout 应该作用在哪里？它和普通 residual dropout 有什么区别？
 标准 attention dropout 通常作用在 softmax 后的 attention weights 上，即随机丢弃部分注意力连接，再乘 V。这相当于正则化 token 间的信息聚合路径。

 residual dropout 通常作用在 attention 输出或 MLP 输出后，再加回残差。二者位置不同：attention dropout 正则化权重分布，residual dropout 正则化子层输出。

#### 48. 如果模型输出出现 NaN，attention 相关实现中有哪些排查点？
 优先检查：

 mask 是否导致某些 query 行全部为 -inf。

 mixed precision 下 -1e9 、 -inf 是否与 kernel 兼容。

 softmax 前 score 是否过大，是否忘了除以 sqrt(d_head)。

 Q/K/V 是否已有 NaN 或 inf。

 dropout、LayerNorm、学习率是否导致激活爆炸。

 mask 语义是否反了，导致有效 token 被全部屏蔽。

 最小化排查方式：用很小的 B/T/H 构造输入，打印 score、mask、weights 的 min/max 和是否存在 NaN。

#### 49. 如果 attention weights 几乎是均匀分布，可能有哪些原因？
 可能原因包括：模型还没训练好；Q 和 K 的表示区分度不足；初始化后 score 都接近；缩放或归一化让 score 太小；输入 token 本身没有明显依赖；mask 或 shape 写错导致不同位置 score 类似。

 均匀不一定总是坏事，有些层或 head 可能承担全局平均信息聚合。但如果所有层所有 head 都均匀，通常说明模型没有学到有效选择性。

#### 50. 如果 attention weights 极端 one-hot，可能有哪些原因和风险？
 可能原因包括：score 尺度过大、忘记除以 sqrt(d_head) 、训练不稳定、softmax 温度过低、某些 token 表示模长异常大。风险是分布过尖，梯度集中甚至饱和，模型过度依赖少数 token，泛化较差。

 但 one-hot 也不一定必然错误，例如复制任务或强对齐任务中某些 head 可能自然关注单个位置。要结合任务和层分布判断。

### 七、白板推导与面试追问题
#### 51. 请从输入 token embedding 开始，完整讲一遍 self-attention 如何得到每个位置的新表示。
 输入 token 先变成 embedding，加上或融合位置信息，得到 X。然后 X 分别经过三个线性层得到 Q、K、V。对每个位置的 query，和所有位置的 key 做点积，得到相关性分数；分数除以 sqrt(d_k) 稳定尺度；如果是 decoder 或有 padding，就在 score 上加 mask；然后沿 key 维度 softmax 得到注意力权重；最后用权重对所有 value 加权求和，得到每个位置的新表示。多头情况下，这个过程在多个子空间并行做，结果拼接后经过 W_O，再进入残差、归一化和 MLP。

 这是一个完整口述答案，面试中 45 到 60 秒讲完即可。

#### 52. 面试官让你只用一句话解释 self-attention，你会怎么说？
 self-attention 让每个 token 根据和其他 token 的内容相关性，动态地从同一序列中读取并聚合信息，得到上下文相关的新表示。

 如果要更技术化：
```text
self-attention = 用 Q/K 算位置间权重，用权重对 V 做加权求和。
```
#### 53. 面试官追问：“Q、K、V 只是三个线性层，为什么能学到语义关系？”你如何回答？
 单层的 Q/K/V 确实只是线性投影，但它们作用在已经包含 token、位置和前层上下文的信息表示上。训练目标会通过反向传播调整这些投影，使有助于预测或任务的 token 对在 Q/K 空间中更匹配，并通过 V 传递有用信息。

 此外，Transformer 是多层、多头、带非线性 MLP 和残差的组合。语义关系不是单靠一个线性层产生，而是在大规模数据和目标函数驱动下，由多层 attention 与 MLP 共同形成。

#### 54. 面试官追问：“如果所有 token 都能互相看，会不会信息泄漏？”你如何区分 encoder 和 decoder 的情况？
 在 encoder-only 模型中，例如 BERT，双向看到整句通常是设计目标，不叫泄漏，因为它做的是理解任务或 masked language modeling，不是严格自回归预测未来。

 在 decoder-only 语言模型中，训练目标是预测下一个 token。如果当前位置看到未来 token，就是信息泄漏。因此 decoder self-attention 必须使用 causal mask。

 核心区分：任务目标是否允许使用双向上下文。

#### 55. 面试官追问：“attention score 高是否代表模型真的在解释这个 token？”你如何回答？
 不能简单等同。attention weight 高说明在该层该 head 中，某个 query 聚合了较多来自某个 value 的信息，但模型最终输出还经过多层、多头、残差和 MLP。高 attention 可以作为分析线索，但不一定是因果解释。

 如果要证明某个 token 真的重要，需要做更严格的实验，如遮挡、反事实替换、梯度归因或 head ablation。

#### 56. 请设计一个最小数值例子，说明某个 token 如何通过 attention 聚合另一个 token 的信息。
 可以设序列有两个 token，当前 query 对两个 key 的 score 是 [3, 0]。softmax 后第一个 token 权重大约远大于第二个 token。若两个 value 分别是 v1 和 v2，输出就是 alpha v1 + beta v2，其中 alpha >> beta。这说明当前 token 主要读取第一个 token 的信息。

 如果想表达“代词关注实体”，可以说“它”的 query 和前文实体“苹果公司”的 key 匹配分高，于是“它”的新表示会更多聚合“苹果公司”的 value。

#### 57. 如果要手写一个最小 Transformer block，self-attention 前后还需要哪些模块配合？
 一个常见 Transformer block 包括：
```text
输入 X
LayerNorm 或 RMSNorm
Multi-Head Self-Attention
Residual connection
LayerNorm 或 RMSNorm
Feed-Forward Network / MLP
Residual connection
```
decoder-only 模型还需要 causal mask。实际现代 LLM 多使用 pre-norm 结构，即先 norm 再进入 attention/MLP，这有利于深层训练稳定。

#### 58. 为什么 self-attention 输出后还要经过 output projection W_O？
 多个 head 的输出 concat 后只是把不同子空间的结果拼在一起，W_O 用来混合不同 head 的信息，并映射回 d_model 维度，使其可以和残差路径相加。没有 W_O，不同 head 之间的信息交互会更弱，表达能力受限。

 W_O 也让 attention 子层输出适配后续网络结构。

#### 59. 请解释“attention 是内容寻址的动态加权聚合”这句话。
 “内容寻址”指的是模型不是按固定位置读取信息，而是根据 query 和 key 的内容相似度决定读哪里。“动态”指权重依赖当前输入，不同句子、不同位置会产生不同 attention 分布。“加权聚合”指最终输出是这些位置 value 的加权和。

 这句话抓住了 self-attention 的本质：不是固定规则，而是由输入内容决定的信息路由。

#### 60. 对第一天学习内容做一次总结：self-attention 的核心流程、核心公式、核心优势、核心限制分别是什么？
 核心流程：输入 X 经过线性投影得到 Q/K/V；用 QK^T 算匹配分数；除以 sqrt(d_k)；加 mask；softmax 得到权重；权重乘 V 得到上下文表示；多头时并行做多个子空间并 concat、投影。

 核心公式：
```text
Attention(Q, K, V) = softmax(QK^T / sqrt(d_k)) V
```
核心优势：任意位置直接交互、长距离依赖路径短、训练并行性好、权重动态依赖输入。

 核心限制：对序列长度二次复杂度；本身不包含顺序信息，需要位置编码；attention weight 不等于严格解释；长上下文成本高。

### 八、加分追问
#### 61. self-attention 和 cross-attention 在机器翻译 encoder-decoder Transformer 中分别出现在哪里？
 encoder 使用 self-attention，让源语言序列内部充分交互。decoder 先使用 masked self-attention，让目标语言已生成部分内部交互且不能看未来；随后使用 cross-attention，用 decoder 当前状态作为 Q，encoder 输出作为 K/V，从源语言句子读取信息。

 所以 self-attention 处理同一序列内部关系，cross-attention 处理目标序列对源序列的信息读取。

#### 62. decoder-only 模型中，为什么 self-attention 加 causal mask 后就可以做 next token prediction？
 causal mask 保证第 i 个位置的表示只依赖第 i 个及之前的 token。训练时把第 i 个位置的输出接 LM head，用来预测第 i+1 个 token，就和生成时“根据历史预测下一个 token”的条件一致。

 因此 decoder-only 模型不需要 encoder，也能通过 masked self-attention 学习自回归语言建模。

#### 63. 为什么 attention 需要位置编码配合？如果去掉位置编码会发生什么？
 没有位置编码时，attention 只能根据 token 内容算关系，不知道顺序。对于 token 集合相同但顺序不同的句子，模型难以区分其结构差异。去掉位置编码后，模型对顺序敏感性显著下降，语言建模、句法理解、生成连贯性都会受影响。

 位置编码提供绝对或相对位置信息，让模型知道“谁在前、谁在后、距离多远”。

#### 64. 为什么说 self-attention 的 attention weights 是输入相关的动态权重，而 CNN 卷积核是训练后固定的局部权重？
 CNN 卷积核参数训练后固定，对不同输入使用同一组局部权重；虽然激活值会变，但空间聚合模式由固定 kernel 决定。self-attention 的权重由当前输入的 Q/K 计算得到，不同样本、不同位置会产生不同 [T, T] 权重矩阵。

 因此 self-attention 更像动态路由：根据内容决定信息从哪里流向哪里。

#### 65. 请解释 PyTorch scaled_dot_product_attention 接口中的 is_causal 和 attn_mask 各自适合什么场景。
 is_causal=True 适合标准自回归 causal mask，框架会构造因果下三角约束。 attn_mask 适合自定义 mask，例如 padding mask、局部窗口 mask、跨模态可见性 mask，或非标准注意力结构。

 工程上要注意 API 对 bool mask 的语义。有的接口 True 表示保留，有的接口 True 表示屏蔽。写 attention 相关代码时，应该用小矩阵单元测试验证 mask 行为。

#### 66. 如果让你在面试中实现 attention，你会如何验证自己的实现是正确的？
 可以从四个层面验证：

 shape：输入 [B, H, T, d] 输出应为 [B, H, T, d_v]，score 为 [B, H, T, T]。

 权重：softmax 后每行和接近 1，被 mask 位置权重接近 0。

 数值：与 PyTorch 内置 scaled_dot_product_attention 在无 dropout 时比较，误差应很小。

 行为：构造简单 case，例如让某个 query 与某个 key 点积最大，检查输出是否更接近对应 value。

 如果包含 causal mask，还要打印长度为 4 或 5 的 mask，确认第 i 行不能看未来。
