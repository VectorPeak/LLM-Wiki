---
title: "微信_汐绫惠夜_Transformer 与 Decoding_公众号文章剪藏_2026-06-21_1-3"
source: "/api/v1/wechat_mp/web/fetch_mp_article_detail_html"
author:
  - "汐绫惠夜"
published: "2026-05-23"
created: 2026-06-21
description: "TikHub 命中的微信公众号文章候选，共 3 条，本文档收录 3 条"
tags:
  - "clippings"
  - "wechat"
  - "汐绫惠夜"
---

## 0x01. 二：Transformer 与 Decoding
> 发布日期：2026-05-23  
> 原文链接：[二：Transformer 与 Decoding](https://mp.weixin.qq.com/s/9L44a6haT3nYj4K-lT3Dyw)

### 1. 学习定位
 第一天已经学习了 self-attention 的核心原理。第二天要把 self-attention 放回完整 Transformer 架构中，理解输入如何变成 embedding，encoder 如何做双向上下文建模，decoder 如何做自回归生成，以及语言模型推理时如何从 logits 变成下一个 token。

 今天的知识分成两条主线：

 Transformer 结构线：Embedding -> Encoder -> Decoder -> 输出 logits。

 Decoding 策略线：logits -> 概率分布 -> temperature 调整 -> top-k/top-p 截断 -> 采样。

 面试中，这一天的内容经常以这些角度被追问：

 Transformer encoder 和 decoder 的结构差异。

 为什么 encoder 可以双向看，decoder 必须 masked self-attention。

 decoder-only LLM 和原始 encoder-decoder Transformer 的关系。

 token embedding、position embedding、output embedding/LM head 的关系。

 推理时 greedy、sampling、top-k、top-p、temperature 的区别。

 为什么 temperature 降低会更确定，升高会更多样。

 top-k 和 top-p 如何过滤候选 token，各自有什么缺陷。

### 2. Transformer 总体结构
 Transformer 最早被提出为一个 encoder-decoder 架构，用于机器翻译等 sequence-to-sequence 任务。它用 attention 替代 RNN/CNN 的序列递推或局部卷积，使序列内部的任意位置可以直接交互，并且更适合并行训练。

 经典 Transformer 可以抽象为：
```text
source tokens
  -> source embedding + position encoding
  -> encoder stack
  -> encoder memory

target tokens shifted right
  -> target embedding + position encoding
  -> decoder stack
       - masked self-attention
       - cross-attention over encoder memory
       - FFN
  -> linear / LM head
  -> logits over vocabulary
```
其中 encoder 负责把输入序列编码成上下文表示，decoder 负责在已有目标 token 的条件下逐步生成输出序列。

 现代大语言模型常见的是 decoder-only Transformer，例如 GPT、LLaMA、Qwen 等。这类模型保留 decoder 的 masked self-attention 和 MLP 堆叠，但通常没有 encoder，也没有 cross-attention。它们直接用前文 token 预测下一个 token。

### 3. Embedding 层
 Transformer 不能直接处理文本字符串。文本首先经过 tokenizer 切分成 token，再映射成 token id。Embedding 层把离散 token id 映射成连续向量。

 基本形式：
```yaml
input_ids: [B, T]
embedding_table: [V, d_model]
token_embeddings = embedding_table[input_ids]
token_embeddings: [B, T, d_model]
```
其中：

- B
 是 batch size。

- T
 是序列长度。

- V
 是词表大小。

- d_model
 是模型隐藏维度。

 Embedding table 的每一行对应一个 token 的可学习向量。模型训练时，embedding 也会通过反向传播更新。

### 4. Token Embedding、Position Encoding 与 Segment Embedding
 Transformer 的输入表示通常由多种 embedding 或位置机制组成：
```text
input representation = token embedding + position information
```
在 BERT 这类 encoder-only 模型中，还可能包含 segment/token type embedding：
```text
input representation = token embedding + position embedding + segment embedding
```
token embedding 表示 token 内容。position encoding/embedding 表示 token 在序列中的位置。segment embedding 用于区分句子 A/B 或不同片段，在现代 decoder-only LLM 中通常不使用。

 纯 self-attention 本身没有顺序意识。如果没有位置信息，模型难以区分“我爱你”和“你爱我”这类 token 集合相同但顺序不同的句子。

 常见位置机制包括：

 sinusoidal positional encoding：原始 Transformer 使用的固定正弦/余弦位置编码。

 learned absolute position embedding：可学习绝对位置 embedding。

 RoPE：旋转位置编码，把相对位置信息注入 Q/K。

 ALiBi：在 attention score 上加入与距离相关的 bias。

 第二天重点理解 embedding 和位置编码的职责分工：token embedding 提供内容，位置机制提供顺序。

### 5. Embedding 与输出 LM Head
 语言模型输出层通常把隐藏状态映射回词表维度：
```yaml
hidden_states: [B, T, d_model]
lm_head: [d_model, V]
logits = hidden_states @ lm_head
logits: [B, T, V]
```
logits[b, t, :] 表示样本 b 在位置 t 对词表中每个 token 的未归一化分数。

 很多语言模型会使用 weight tying，即输入 embedding table 和输出 LM head 共享权重：
```text
lm_head.weight = embedding_table.weight
```
这样可以减少参数量，并让输入 token 表示和输出 token 分类空间保持一致。weight tying 不是必须的，但在语言模型中非常常见。

### 6. Encoder 结构
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkiajHvVYJyyez84icZKLapw4NN9lZJfHbnsibKbSEJNZ93bzHcqSKoeXDWIaRJ9SBR3jRy1AJ9qyOTSuoszZBUVhx8iabiaegkhmOcE/640?wx_fmt=png&from=appmsg)
 Transformer encoder 是多个 encoder layer 的堆叠。每个 encoder layer 通常包含：
```text
Self-Attention
Residual Connection
LayerNorm
Feed-Forward Network
Residual Connection
LayerNorm
```
现在实现常用 pre-norm 变体：
```text
x = x + SelfAttention(Norm(x))
x = x + MLP(Norm(x))
```
encoder 的 self-attention 通常是双向的。也就是说，位置 i 可以看到同一输入序列中的所有有效 token。对于理解类任务，这种双向上下文是合理的，因为任务目标允许使用完整输入。

 encoder 输出可以看作输入序列的上下文表示：
```yaml
encoder_input:  [B, S, d_model]
encoder_output: [B, S, d_model]
```
其中 S 是 source sequence length。

 典型 encoder-only 模型包括 BERT、RoBERTa 等，常用于分类、匹配、检索、抽取、序列标注等理解任务。

### 7. Encoder Layer 的内部模块
 encoder layer 的两个核心子层是 multi-head self-attention 和 position-wise feed-forward network。

 multi-head self-attention 负责 token 间信息交互。它让每个位置根据内容相关性从其他位置读取信息。

 feed-forward network 负责对每个位置独立做非线性变换。原始 Transformer FFN 形式为：
```text
FFN(x) = max(0, xW1 + b1)W2 + b2
```
现代 LLM 常把 ReLU 替换成 GELU、SiLU 或 SwiGLU 等激活，并扩大中间维度。

 Residual connection 保留原始信息并改善梯度流动。LayerNorm/RMSNorm 稳定训练。Dropout 在原始 Transformer 中用于正则化。

 encoder 的整体效果是：每一层先做跨 token 信息混合，再做逐 token 非线性变换；堆叠多层后，每个位置获得更深层的上下文表示。

### 8. Decoder 结构
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkjWFFWibsgeic0VNB5P8UJWLjOhMrsJZX8QFXZmySJVKgEz1cwGJ7bO9ib9InY8Z50zAzedPNY2IahCv79WPmSjHicU3zcdb2HnCIQ/640?wx_fmt=png&from=appmsg)
 Transformer decoder 也由多个 decoder layer 堆叠。原始 encoder-decoder Transformer 的 decoder layer 通常包含三类子层：
```text
Masked Self-Attention
Cross-Attention
Feed-Forward Network
```
masked self-attention 让目标序列内部已经生成的 token 互相交互，但不能看到未来 token。cross-attention 让 decoder 当前状态读取 encoder 输出的 source memory。FFN 对每个位置做非线性变换。

 原始机器翻译场景中：

 encoder 输入源语言句子。

 decoder 输入右移后的目标语言 token。

 decoder 每个位置预测目标语言的下一个 token。

 decoder 输出经过线性层得到词表 logits。

### 9. Masked Self-Attention
 decoder 的 self-attention 必须使用 causal mask。对于长度为 T 的目标序列，第 i 个位置只能关注 0..i 的位置，不能关注未来位置。

 causal mask 形状示例：
```text
k1 k2 k3 k4 k5
q1    1  0  0  0  0
q2    1  1  0  0  0
q3    1  1  1  0  0
q4    1  1  1  1  0
q5    1  1  1  1  1
```
不加 causal mask 会造成训练时信息泄漏。模型可以直接看到未来答案，训练 loss 会虚低，但生成时未来 token 不存在，推理效果会明显恶化。

 训练时虽然使用 causal mask，但整段序列仍可以并行计算。mask 只是屏蔽 attention score 中的未来位置，不要求像 RNN 一样逐 token 递推训练。

### 10. Cross-Attention
 cross-attention 出现在 encoder-decoder Transformer 的 decoder 中。它的 Q 来自 decoder 当前隐藏状态，K/V 来自 encoder 输出。

 形式为：
```text
Q = decoder_hidden W_Q
K = encoder_output W_K
V = encoder_output W_V
```
decoder 通过 cross-attention 在生成目标 token 时读取源序列信息。机器翻译中，decoder 生成每个目标词时可以关注源语言句子的相关部分。

 在 decoder-only LLM 中通常没有 cross-attention。模型把 prompt 和待生成文本放在同一序列中，用 masked self-attention 建模上下文。

### 11. Encoder、Decoder、Decoder-Only 的区别
 三类结构可以这样区分：
```yaml
Encoder-only:
  双向 self-attention
  适合理解任务
  例：BERT

Encoder-decoder:
  encoder 双向编码 source
  decoder masked self-attention + cross-attention
  适合 seq2seq 任务
  例：原始 Transformer、T5、BART

Decoder-only:
  masked self-attention
  自回归 next token prediction
  适合开放式生成和通用 LLM
  例：GPT、LLaMA、Qwen
```
面试中需要明确：现代 ChatGPT 类模型通常不是原始完整 encoder-decoder Transformer，而是 decoder-only Transformer 或其变体。

### 12. Training 与 Inference 的差异
 训练 decoder-only LM 时，输入是一整段 token：
```yaml
input:  x1 x2 x3 x4
target: x2 x3 x4 x5
```
模型一次性计算所有位置的 logits，并用 causal mask 保证每个位置不能看未来。

 推理时，模型逐步生成：
```text
prompt -> logits for next token -> choose token -> append -> repeat
```
每一步只使用当前上下文预测下一个 token。为了避免重复计算历史 token 的 K/V，推理系统通常使用 KV cache。第二天重点在 decoding 策略，KV cache 后续系统课再深入。

### 13. Logits、Softmax 与下一个 Token 分布
 语言模型最后一层输出 logits：
```text
logits: [B, T, V]
```
生成时通常只取最后一个位置：
```text
next_token_logits = logits[:, -1, :]
```
再通过 softmax 得到词表概率分布：
```text
p_i = exp(logit_i) / sum_j exp(logit_j)
```
decoding 策略就是决定如何从这个分布中选出下一个 token。不同策略会影响输出的确定性、多样性、重复率、稳定性和创造性。

 常见策略包括：

 greedy search：每步选概率最高的 token。

 beam search：维护多个候选序列。

 multinomial sampling：按概率分布随机采样。

 top-k sampling：只从概率最高的 k 个 token 中采样。

 top-p/nucleus sampling：只从累计概率达到 p 的最小候选集合中采样。

 temperature scaling：改变概率分布的尖锐程度。

 今天重点是 top-k、top-p 和 temperature。

### 14. Temperature
 temperature 用来调整 logits 的尺度。公式为：
```text
p_i = softmax(logit_i / T)
```
其中 T 是 temperature，不要和序列长度混淆。

 temperature 的效果：

- T = 1：保持原始分布。
- T < 1：分布更尖锐，高概率 token 更突出，输出更保守、更确定。
- T > 1：分布更平坦，低概率 token 更有机会被采样，输出更多样但更容易跑偏。
- T -> 0：趋近 greedy decoding。

 示例 logits：
```text
token A: 5
token B: 4
token C: 1
```
当 temperature 降低时，A 与 B/C 的概率差距会变大；当 temperature 升高时，B/C 的相对机会会增加。

 temperature 只改变分布形状，不直接删除候选 token。它通常与 top-k 或 top-p 组合使用。

### 15. Top-k Sampling
 top-k sampling 的流程是：

 根据 logits 或概率选出分数最高的 k 个 token。

 把其他 token 的概率设为 0，或 logits 设为 -inf。

 对剩下的 k 个 token 重新归一化。

 从归一化后的分布中随机采样。

 形式化地说，top-k 把候选集合限制为：
```text
S_k = top k tokens by probability
```
然后从 S_k 中采样。

 top-k 的优点是简单、有效，可以过滤掉大量低概率噪声 token。缺点是 k 是固定的，无法根据当前分布形状动态调整。

 如果当前分布很尖锐， k=50 可能包含很多不必要 token。如果当前分布很平坦， k=10 可能过滤掉合理候选，损失多样性。

### 16. Top-p / Nucleus Sampling
 top-p sampling 又叫 nucleus sampling。它不是固定保留 k 个 token，而是保留累计概率达到阈值 p 的最小 token 集合。

 流程：

 按概率从高到低排序 token。

 从最高概率 token 开始累加概率。

 找到累计概率达到 p 的最小集合。

 把集合外 token 概率设为 0。

 对集合内 token 重新归一化并采样。

 候选集合：
```text
S_p = smallest set such that sum_{i in S_p} p_i >= p
```
top-p 的优点是候选集合大小会随分布形状动态变化：

 当分布很尖锐时，只保留少量 token。

 当分布较平坦时，保留更多 token。

 常见参数如 top_p=0.9 或 top_p=0.95。top-p 也不是越大越好。 top_p 太高会引入更多低质量候选，太低会使输出过于保守。

### 17. Top-k 与 Top-p 的组合
 实际生成中，top-k、top-p、temperature 常组合使用。一个典型流程是：
```text
logits
-> temperature scaling
-> top-k filter
-> top-p filter
-> softmax / renormalize
-> sample next token
```
不同框架的具体顺序可能略有差异，但核心思想是先调整分布，再过滤候选，再采样。

 组合使用时：

 temperature 控制分布尖锐程度。

 top-k 设置候选数量上限。

 top-p 根据累计概率动态控制候选范围。

 例如 temperature=0.7, top_p=0.9 通常会比纯随机采样更稳定，也比 greedy 更有多样性。具体参数要根据任务调试。

### 18. Decoding 策略与任务适配
 不同任务适合不同 decoding 策略。

 确定性任务更适合低温度、greedy 或较保守的 sampling：

 信息抽取

 分类标签生成

 JSON 格式输出

 代码补全中的严格片段

 数学推理的最终答案格式

 开放式生成更适合适度 sampling：

 创意写作

 头脑风暴

 对话回复

 多样化改写

 需要注意，decoding 不能从根本上修复模型能力问题。它只能改变从概率分布中选择 token 的方式。模型不知道答案、prompt 不清晰、上下文不足、训练偏差严重时，调 top-k/top-p/temperature 的收益有限。

### 19. 常见实现参考
 下面是一个简化的 top-k/top-p/temperature sampling 伪代码：
```python
import torch
import torch.nn.functional as F

def sample_next_token(logits, temperature=1.0, top_k=None, top_p=None):
    # logits: [V]
    if temperature <= 0:
        return torch.argmax(logits)

    logits = logits / temperature

    if top_k is not None and top_k > 0:
        values, _ = torch.topk(logits, k=top_k)
        threshold = values[-1]
        logits = torch.where(
            logits < threshold,
            torch.full_like(logits, float("-inf")),
            logits,)

    if top_p is not None and 0 < top_p < 1:
        sorted_logits, sorted_indices = torch.sort(logits, descending=True)
        sorted_probs = F.softmax(sorted_logits, dim=-1)
        cumulative_probs = torch.cumsum(sorted_probs, dim=-1)

        remove = cumulative_probs > top_p
        remove[1:] = remove[:-1].clone()
        remove[0] = False

        sorted_logits[remove] = float("-inf")
        logits = torch.full_like(logits, float("-inf"))
        logits.scatter_(0, sorted_indices, sorted_logits)

    probs = F.softmax(logits, dim=-1)
    return torch.multinomial(probs, num_samples=1)
```
工程中通常直接使用成熟框架的 generate 接口，但面试中能写出这个流程可以说明理解了 decoding 的本质。

### 20. 常见易错点
 embedding 相关易错点：

 把 token embedding 和 one-hot 编码混为一谈。one-hot 是离散索引表示，embedding 是可学习连续向量。

 忽略位置编码，误以为 self-attention 天然知道顺序。

 混淆 input embedding 和 output LM head。

 不理解 weight tying 的作用。

 encoder/decoder 相关易错点：

 认为所有 Transformer 都是 encoder-decoder。现代 LLM 多数是 decoder-only。

 认为 decoder 只能用于翻译。decoder-only 已经成为通用生成模型主流架构。

 混淆 masked self-attention 和 cross-attention。

 不知道 decoder 训练时可以并行，推理时必须逐步生成。

 decoding 相关易错点：

 把 top-k 当成“选 top-k 中最大的 token”，实际 top-k sampling 是从 top-k 候选中按概率采样。

 把 top-p 理解成“保留概率大于 p 的 token”，实际是保留累计概率达到 p 的最小集合。

 认为 temperature 会删除 token，实际它只缩放 logits。

 认为 temperature 越高越好，实际过高会增加幻觉和无关输出。

 忘记过滤后要重新归一化概率。

### 21. 知识闭环总结
 第二天的知识闭环可以压缩为：
```text
文本先经 tokenizer 得到 token id。
token id 经 embedding table 变成连续向量。
位置机制注入顺序信息。
encoder 用双向 self-attention 建模输入序列。
decoder 用 masked self-attention 保证自回归因果约束。
encoder-decoder decoder 还通过 cross-attention 读取 encoder 输出。
decoder-only LLM 省略 encoder 和 cross-attention，直接做 next token prediction。
模型输出 logits 后，decoding 策略决定如何选择下一个 token。
temperature 调整分布尖锐程度。
top-k 固定候选数量，top-p 按累计概率动态确定候选集合。
```
### 22. 参考资料
 Attention Is All You Need: https://arxiv.org/abs/1706.03762

 Hugging Face Transformers Generation Strategies: https://huggingface.co/docs/transformers/main/en/generation_strategies

 Hugging Face Blog - How to generate text: https://huggingface.co/blog/how-to-generate

 The Curious Case of Neural Text Degeneration: https://arxiv.org/abs/1904.09751

 PyTorch Transformer API: https://docs.pytorch.org/docs/2.12/generated/torch.nn.Transformer.html

 截图推荐：李宏毅老师讲解 Transformer： https://www.bilibili.com/video/BV1L142187HH

 截图推荐：讲解的很清楚的大模型解码： https://www.zhihu.com/tardis/zm/art/647813179

 截图推荐：有图有代码的大模型解码： https://blog.csdn.net/Mike0010/article/details/13832616

## 0x02. 二：Transformer 与 Decoding自测题
> 发布日期：2026-05-23  
> 原文链接：[二：Transformer 与 Decoding自测题](https://mp.weixin.qq.com/s/4QLrGV_D44bXuhcxxr6Clw)

学习主题：第二天：1.2 Transformer(Embedding、Encoder、Decoder)，1.5 Decoding 学习重点：Embedding、Encoder、Decoder、Top-k 抽样、Top-p 抽样/核采样、Temperature

### 覆盖范围
 Transformer 总体架构

 token embedding、position embedding、LM head、weight tying

 encoder layer 的结构和双向 self-attention

 decoder layer 的 masked self-attention、cross-attention 与 FFN

 encoder-only、encoder-decoder、decoder-only 的区别

 训练与推理阶段的差异

 logits、softmax 与 next-token distribution

 temperature、top-k sampling、top-p/nucleus sampling

 decoding 参数调试、实现细节和常见错误

### 一、Transformer 总体架构
 请用 1 分钟概括 Transformer 的整体思想。它相比 RNN/CNN 的核心变化是什么？

 原始 Transformer 的 encoder-decoder 架构包含哪些主要模块？

 在机器翻译场景中，encoder 和 decoder 分别承担什么职责？

 为什么说现代大语言模型通常是 decoder-only Transformer，而不是完整的原始 encoder-decoder Transformer？

 Transformer 中 residual connection、LayerNorm 和 FFN 分别起什么作用？

 pre-norm 和 post-norm Transformer block 的区别是什么？现代大模型为什么更常用 pre-norm？

 position-wise FFN 中的 “position-wise” 是什么意思？

 Transformer 的输入和输出通常有哪些关键 shape？请从 [B, T] token id 讲到 [B, T, V] logits。

### 二、Embedding 与位置表示
 token embedding 是什么？它和 one-hot 表示有什么关系和区别？

 给定 input_ids: [B, T]，词表大小 V，隐藏维度 d_model，embedding table 和输出 embedding 的 shape 分别是什么？

 为什么 Transformer 需要位置信息？纯 self-attention 为什么不天然知道顺序？

 token embedding 和 position embedding 相加后，shape 是否变化？语义上发生了什么？

 sinusoidal positional encoding 和 learned positional embedding 有什么区别？

 RoPE 和绝对位置 embedding 的思路有什么不同？这里不要求推导公式，但要讲清直觉。

 segment embedding/token type embedding 常见于哪些模型或任务？decoder-only LLM 一般是否需要？

 什么是 weight tying？输入 embedding 和输出 LM head 共享权重有什么好处？

 为什么输出层 LM head 的输出维度是词表大小 V？

 如果 tokenizer 词表扩展了，embedding table 和 LM head 需要发生什么变化？

### 三、Encoder
 Transformer encoder layer 通常由哪些子层组成？

 encoder 的 self-attention 为什么通常不需要 causal mask？

 encoder 中 padding mask 的作用是什么？

 encoder 输出的 shape 是什么？它可以被下游哪些任务使用？

 BERT 这类 encoder-only 模型为什么适合理解类任务？

 encoder 中 self-attention 和 FFN 的分工是什么？

 encoder layer 堆叠多层后，模型表示能力为什么会增强？

 如果一个理解任务需要输出句子级表示，通常如何从 encoder 输出中得到句向量？

### 四、Decoder
 原始 Transformer decoder layer 包含哪三类主要子层？

 masked self-attention 和普通 self-attention 的区别是什么？

 decoder 为什么必须使用 causal mask？不使用会发生什么？

 训练 decoder 时为什么可以并行计算整段序列，而推理时通常要逐 token 生成？

 cross-attention 中 Q、K、V 分别来自哪里？

 cross-attention 在机器翻译中起什么作用？

 decoder-only 模型为什么通常没有 cross-attention？

 decoder-only LM 的训练样本中 input 和 target 通常如何错位？

 为什么 decoder-only 模型可以把 prompt 和生成内容放在同一个序列中处理？

 causal mask 和 padding mask 可以同时用于 decoder 吗？二者分别屏蔽什么？

### 五、架构类型对比
 encoder-only、encoder-decoder、decoder-only 三类 Transformer 分别适合什么任务？

 BERT、T5/BART、GPT/LLaMA/Qwen 分别属于哪类架构？

 为什么 encoder-only 模型不适合直接做开放式自回归生成？

 为什么 decoder-only 模型在通用大语言模型中非常流行？

 如果面试官问“Transformer 就是 ChatGPT 的结构吗”，你会如何回答？

 encoder-decoder 模型和 decoder-only 模型在输入输出建模方式上有什么差异？

### 六、Decoding 基础
 语言模型输出 logits 后，为什么还需要 decoding 策略？

 logits 和 probability 的区别是什么？softmax 在生成中起什么作用？

 greedy decoding 的流程是什么？它有什么优点和缺点？

 sampling decoding 的基本思想是什么？它和 greedy 的关键区别是什么？

 为什么开放式生成中纯 greedy 或 beam search 容易出现重复、无聊或退化输出？

 decoding 策略能否弥补模型本身能力不足？为什么？

### 七、Temperature
 temperature scaling 的公式是什么？

 temperature 小于 1、等于 1、大于 1 时，输出分布分别会怎样变化？

 为什么 temperature -> 0 时接近 greedy decoding？

 temperature 是否会删除候选 token？它和 top-k/top-p 的区别是什么？

 在格式遵循、代码生成、创意写作三个场景中，temperature 应该如何倾向性设置？

 temperature 过高可能带来哪些风险？

### 八、Top-k Sampling
 top-k sampling 的完整流程是什么？

 top-k 中的 k 表示什么？ top_k=1 与 greedy decoding 有什么关系？

 top-k sampling 是“选 top-k 中概率最高的 token”吗？请解释。

 top-k sampling 为什么能减少低质量 token 的干扰？

 top-k 的固定候选数量会带来什么问题？

 如果当前分布很尖锐，使用很大的 k 可能有什么影响？如果当前分布很平坦，使用很小的 k 又有什么影响？

### 九、Top-p / Nucleus Sampling
 top-p sampling 的完整流程是什么？

 top-p 中的 p 表示什么？它是不是“保留概率大于 p 的 token”？

 为什么 top-p 又叫 nucleus sampling？

 top-p 相比 top-k 的核心优势是什么？

- top_p=0.9
 与 top_p=0.95 在候选集合和输出多样性上可能有什么区别？

 top-k 和 top-p 能否同时使用？同时使用时它们各自起什么作用？

### 十、实现、调参和排错
 请写出一个包含 temperature、top-k、top-p 的 next-token sampling 伪代码流程。

 过滤 top-k 或 top-p 后，为什么需要重新归一化概率？

 top-p 实现中为什么要先按概率降序排序？

 实现 top-p 时，为什么通常要保留第一个超过阈值的 token？

 如果生成内容重复严重，可以从 decoding 参数角度做哪些调整？

 如果生成内容太随机、跑题或幻觉增加，可以从 decoding 参数角度做哪些调整？

 如果模型需要稳定输出 JSON，应该如何设置 decoding 参数？

 在 Hugging Face generate 中， do_sample=True 、 top_k 、 top_p 、 temperature 分别控制什么？

 请总结今天的知识链路：从 token id 到 embedding，到 Transformer encoder/decoder，再到 logits 和 decoding。

## 0x03. 二：Transformer 与 Decoding自测题答案
> 发布日期：2026-05-23  
> 原文链接：[二：Transformer 与 Decoding自测题答案](https://mp.weixin.qq.com/s/bECMarVBOqdrCwBHeJwXyQ)

学习主题：第二天：1.2 Transformer(Embedding、Encoder、Decoder)，1.5 Decoding 学习重点：Embedding、Encoder、Decoder、Top-k 抽样、Top-p 抽样/核采样、Temperature

### 参考资料
 Attention Is All You Need: https://arxiv.org/abs/1706.03762

 Hugging Face Transformers Generation Strategies: https://huggingface.co/docs/transformers/main/en/generation_strategies

 Hugging Face Blog - How to generate text: https://huggingface.co/blog/how-to-generate

 The Curious Case of Neural Text Degeneration: https://arxiv.org/abs/1904.09751

 PyTorch Transformer API: https://docs.pytorch.org/docs/2.12/generated/torch.nn.Transformer.html

### 评分标准
 合格：能区分 embedding、encoder、decoder、logits 和 decoding，能解释 top-k、top-p、temperature 的基本含义。

 良好：能讲清 encoder/decoder 的 mask 差异、cross-attention 来源、decoder-only LM 的训练与推理差异。

 优秀：能写出 shape、伪代码、参数调试逻辑，能解释 top-k/top-p 的缺陷和适用场景。

### 一、Transformer 总体架构
#### 1. 请用 1 分钟概括 Transformer 的整体思想。它相比 RNN/CNN 的核心变化是什么？
 Transformer 的核心思想是用 attention 机制建模序列中 token 之间的关系，用矩阵化的 self-attention 替代 RNN 的顺序递推或 CNN 的局部卷积。它让任意两个位置在一层内直接交互，并且训练时可以并行计算整段序列。

 相比 RNN，Transformer 不需要按时间步递推，长距离依赖路径更短。相比 CNN，Transformer 不依赖固定局部窗口，单层就能建立全局 token 交互。代价是 self-attention 对序列长度通常有二次复杂度。

 关键得分点：attention、并行、全局交互、替代递推/卷积、二次复杂度。

#### 2. 原始 Transformer 的 encoder-decoder 架构包含哪些主要模块？
 原始 Transformer 包含输入 embedding、位置编码、encoder stack、decoder stack 和输出线性层/softmax。encoder stack 由多层 encoder layer 组成，每层包含 multi-head self-attention 和 FFN。decoder stack 由多层 decoder layer 组成，每层包含 masked self-attention、cross-attention 和 FFN。

 整体流程是：source token 进入 encoder 得到 source memory；右移后的 target token 进入 decoder；decoder 先看已生成目标 token，再通过 cross-attention 读取 encoder 输出，最后生成目标词表 logits。

#### 3. 在机器翻译场景中，encoder 和 decoder 分别承担什么职责？
 encoder 负责读取源语言句子，并把每个源 token 编码成上下文表示。encoder self-attention 通常是双向的，可以利用完整源句信息。

 decoder 负责生成目标语言句子。它在每个位置只能看到已经生成的目标 token，因此需要 masked self-attention；同时它通过 cross-attention 读取 encoder 输出，决定当前生成词应该对齐或参考源句中的哪些部分。

#### 4. 为什么说现代大语言模型通常是 decoder-only Transformer，而不是完整的原始 encoder-decoder Transformer？
 现代通用 LLM 多以 next token prediction 为训练目标。只要用 causal mask 保证当前位置只能看历史 token，decoder-only 结构就可以直接学习“根据上下文预测下一个 token”。这类结构把 prompt 和生成内容放在同一个序列中，不需要单独的 source encoder 和 target decoder。

 原始 encoder-decoder 更适合明确输入到输出的 seq2seq 任务，如翻译、摘要。GPT、LLaMA、Qwen 等通用生成模型通常采用 decoder-only Transformer 或其变体。

#### 5. Transformer 中 residual connection、LayerNorm 和 FFN 分别起什么作用？
 residual connection 让子层学习增量变化，并改善深层网络的梯度流动。LayerNorm 或 RMSNorm 稳定激活分布，使训练更稳定。FFN 对每个位置独立做非线性变换，增强每个 token 表示的特征变换能力。

 self-attention 主要负责跨 token 信息混合，FFN 主要负责逐 token 的非线性加工，residual 和 norm 则支撑深层堆叠的可训练性。

#### 6. pre-norm 和 post-norm Transformer block 的区别是什么？现代大模型为什么更常用 pre-norm？
 post-norm 是先执行子层并加残差，再做归一化：
```text
x = Norm(x + Sublayer(x))
```
pre-norm 是先归一化，再执行子层并加残差：
```text
x = x + Sublayer(Norm(x))
```
pre-norm 通常在深层 Transformer 中更稳定，因为残差路径更直接，梯度更容易穿过很多层。现代大模型层数深、训练规模大，因此常采用 pre-norm 或类似稳定结构。

#### 7. position-wise FFN 中的 “position-wise” 是什么意思？
 position-wise 表示同一个 FFN 对序列中每个位置独立应用，不在 FFN 内部直接混合不同 token。跨 token 信息混合由 self-attention 完成，FFN 则对每个 token 的隐藏向量做相同参数的非线性变换。

 如果输入是 [B, T, d_model]，FFN 对每个 [d_model] 向量独立处理，输出仍是 [B, T, d_model]。

#### 8. Transformer 的输入和输出通常有哪些关键 shape？请从 [B, T] token id 讲到 [B, T, V] logits。
 典型流程：
```yaml
input_ids: [B, T]
embedding_table: [V, d_model]
token_embeddings: [B, T, d_model]
position information added: [B, T, d_model]
Transformer hidden states: [B, T, d_model]
LM head: [d_model, V]
logits: [B, T, V]
```
其中 V 是词表大小， d_model 是隐藏维度。生成时通常取最后一个位置 logits[:, -1, :] 得到下一个 token 的词表分数。

### 二、Embedding 与位置表示
#### 9. token embedding 是什么？它和 one-hot 表示有什么关系和区别？
 one-hot 是长度为词表大小的离散稀疏向量，只有对应 token 的位置为 1。token embedding 是可学习的低维稠密向量，通过查表得到。

 从计算上看，one-hot 乘 embedding table 等价于按 token id 查表。但实际实现不会构造巨大 one-hot，而是直接用 id 索引 embedding table。embedding 能学习 token 间的语义和分布关系，one-hot 本身没有语义相似性。

#### 10. 给定 input_ids: [B, T]，词表大小 V，隐藏维度 d_model，embedding table 和输出 embedding 的 shape 分别是什么？
 embedding table 的 shape 是：
```text
[V, d_model]
```
输入 id 查表后得到：
```text
token_embeddings: [B, T, d_model]
```
如果说“输出 embedding”指 hidden states，则 Transformer 输出通常是 [B, T, d_model]。如果指 LM head 输出 logits，则 shape 是 [B, T, V]。

#### 11. 为什么 Transformer 需要位置信息？纯 self-attention 为什么不天然知道顺序？
 纯 self-attention 根据 token 内容计算相关性。如果没有位置编码，对输入序列做同样的置换，attention 输出也会相应置换，模型难以区分 token 的先后顺序。

 语言顺序非常重要，例如“我爱你”和“你爱我”token 集合相同但语义不同。因此 Transformer 需要通过位置编码、位置 embedding、RoPE、ALiBi 等机制注入顺序和距离信息。

#### 12. token embedding 和 position embedding 相加后，shape 是否变化？语义上发生了什么？
 shape 不变，仍是：
```text
[B, T, d_model]
```
语义上，每个位置的输入向量同时包含 token 内容信息和位置信息。相加是一种简单融合方式，让后续 attention 和 FFN 可以基于内容和位置共同建模。

#### 13. sinusoidal positional encoding 和 learned positional embedding 有什么区别？
 sinusoidal positional encoding 是固定函数生成的位置向量，不通过训练学习。原始 Transformer 使用正弦和余弦函数编码不同频率的位置模式。

 learned positional embedding 是可学习参数，每个位置对应一个向量，通过训练更新。它更灵活，但通常对最大长度有固定表大小，外推到更长序列不一定可靠。

#### 14. RoPE 和绝对位置 embedding 的思路有什么不同？这里不要求推导公式，但要讲清直觉。
 绝对位置 embedding 通常直接把“第几个位置”的向量加到 token embedding 上。RoPE 则把位置信息注入 Q/K 表示，通过旋转向量的方式让 attention score 感知相对位置关系。

 直觉上，RoPE 不只是告诉模型“我在第 i 位”，而是让 query-key 匹配时自然包含“两个 token 相距多少”的信息，因此在 decoder-only LLM 中很常见。

#### 15. segment embedding/token type embedding 常见于哪些模型或任务？decoder-only LLM 一般是否需要？
 segment embedding 常见于 BERT 这类 encoder-only 模型，用来区分句子 A 和句子 B，例如句子对分类、自然语言推理、问答匹配等任务。

 decoder-only LLM 一般不使用传统 segment embedding。它通常通过 special tokens、chat template、role tokens 或位置结构来区分 user/assistant/system 等片段。

#### 16. 什么是 weight tying？输入 embedding 和输出 LM head 共享权重有什么好处？
 weight tying 是让输入 embedding table 和输出 LM head 使用同一组权重。输入 embedding 是 [V, d_model]，LM head 常可看作 [d_model, V]，共享时通常使用 embedding table 的转置。

 好处包括减少参数量，并让输入 token 表示空间和输出分类空间保持一致。语言模型中这是一种常见设计，但不是强制要求。

#### 17. 为什么输出层 LM head 的输出维度是词表大小 V？
 语言模型每一步要从整个词表中选择下一个 token。因此模型需要给词表中每个 token 一个分数。LM head 把隐藏状态 [d_model] 映射成 [V] logits，其中第 i 个 logit 对应词表第 i 个 token 的未归一化分数。

#### 18. 如果 tokenizer 词表扩展了，embedding table 和 LM head 需要发生什么变化？
 词表从 V 扩展到 V_new 后，输入 embedding table 需要从 [V, d_model] 扩展到 [V_new, d_model]，LM head 输出维度也需要扩展到 V_new。新增 token 的 embedding 通常需要初始化。

 如果模型使用 weight tying，要确保新增 embedding 和 LM head 共享逻辑一致。扩词表后通常还需要继续训练或微调，让新增 token 表示变得有意义。

### 三、Encoder
#### 19. Transformer encoder layer 通常由哪些子层组成？
 典型 encoder layer 包含 multi-head self-attention、FFN、residual connection 和 LayerNorm/RMSNorm。原始 post-norm 写法是 attention 后加残差再 norm，FFN 后加残差再 norm。现代 pre-norm 写法通常是先 norm，再进入 attention 或 FFN，最后加残差。

 核心是：self-attention 负责 token 间信息交互，FFN 负责每个位置的非线性变换。

#### 20. encoder 的 self-attention 为什么通常不需要 causal mask？
 encoder 主要用于理解完整输入序列。理解任务允许每个位置使用左侧和右侧上下文，因此 encoder self-attention 通常是双向的，不需要屏蔽未来 token。

 但 encoder 仍需要 padding mask，用于屏蔽补齐位置。causal mask 是自回归生成目标所需，不是所有 Transformer 都需要。

#### 21. encoder 中 padding mask 的作用是什么？
 padding mask 用来屏蔽无效 padding token。batch 中样本长度不同，需要 padding 到同一长度；如果不 mask，真实 token 可能 attend 到 padding 的 K/V，污染表示。

 实现上通常把 padding key 位置的 attention score 设为 -inf，使 softmax 后权重为 0。

#### 22. encoder 输出的 shape 是什么？它可以被下游哪些任务使用？
 encoder 输入和输出通常都是：
```text
[B, S, d_model]
```
其中 S 是输入序列长度。下游可以使用每个 token 的输出做序列标注、抽取式问答；也可以池化成句向量做分类、匹配、检索；在 encoder-decoder 模型中，encoder 输出还会作为 decoder cross-attention 的 K/V memory。

#### 23. BERT 这类 encoder-only 模型为什么适合理解类任务？
 BERT 使用双向 self-attention，可以同时利用左右上下文构建 token 表示。理解任务通常给定完整输入，例如分类、匹配、抽取、序列标注，不需要逐 token 自回归生成，因此双向上下文很合适。

 BERT 预训练目标也偏理解，如 masked language modeling，使模型适合学习上下文语义表示。

#### 24. encoder 中 self-attention 和 FFN 的分工是什么？
 self-attention 负责跨 token 信息混合，让每个位置从相关上下文读取信息。FFN 负责对每个位置的表示做非线性特征变换，不直接混合不同位置。

 可以简化理解为：attention 做“信息路由和聚合”，FFN 做“逐位置特征加工”。

#### 25. encoder layer 堆叠多层后，模型表示能力为什么会增强？
 每一层都会进行一次跨 token 聚合和非线性变换。底层可能捕捉局部词法和浅层语法，高层可以组合更抽象的语义关系。多层堆叠使 token 表示反复整合上下文，从而提升表达能力。

 残差连接和归一化让这种深层堆叠更容易训练。

#### 26. 如果一个理解任务需要输出句子级表示，通常如何从 encoder 输出中得到句向量？
 常见方法包括使用 [CLS] token 的最终 hidden state、对所有有效 token 做 mean pooling、max pooling，或使用 attention pooling。BERT 分类任务常用 [CLS] 表示；句向量检索任务中 mean pooling 也很常见。

 选择哪种方式取决于预训练方式和下游任务。关键是不能把 padding token 纳入 pooling。

### 四、Decoder
#### 27. 原始 Transformer decoder layer 包含哪三类主要子层？
 原始 decoder layer 包含 masked self-attention、cross-attention 和 FFN。masked self-attention 处理目标序列内部已生成 token 的关系；cross-attention 读取 encoder 输出；FFN 对每个位置做非线性变换。

 每个子层周围都有 residual connection 和 LayerNorm。

#### 28. masked self-attention 和普通 self-attention 的区别是什么？
 普通 self-attention 可以让每个位置关注所有有效 token。masked self-attention 会通过 causal mask 屏蔽未来位置，使第 i 个位置只能关注 0..i。

 masked self-attention 用于自回归生成，防止训练时看到未来答案。

#### 29. decoder 为什么必须使用 causal mask？不使用会发生什么？
 decoder 训练目标通常是根据历史 token 预测下一个 token。如果不加 causal mask，第 i 个位置能看到未来 token，等于提前看答案。训练 loss 会虚低，但推理时未来 token 不存在，模型行为会崩坏。

 关键得分点：防止信息泄漏；保证训练条件和推理条件一致。

#### 30. 训练 decoder 时为什么可以并行计算整段序列，而推理时通常要逐 token 生成？
 训练时目标序列已知，可以一次性输入整段 token，用 causal mask 限制每个位置可见范围。矩阵乘法仍然可以并行计算所有位置。

 推理时下一个 token 尚未生成，必须先预测第一个新 token，再把它加入上下文，继续预测下一个。因此生成过程在 token 维度上是顺序的。

#### 31. cross-attention 中 Q、K、V 分别来自哪里？
 在 encoder-decoder Transformer 中，cross-attention 的 Q 来自 decoder 当前 hidden states，K 和 V 来自 encoder outputs。
```text
Q = decoder_hidden W_Q
K = encoder_output W_K
V = encoder_output W_V
```
这表示 decoder 用当前生成状态去查询 source sequence 的编码信息。

#### 32. cross-attention 在机器翻译中起什么作用？
 cross-attention 让 decoder 在生成每个目标词时读取源语言句子的相关信息。它相当于目标端对源端表示做内容寻址，帮助模型完成对齐、词义选择和上下文条件化生成。

 没有 cross-attention，decoder 只能看目标端历史，难以根据源句生成正确翻译。

#### 33. decoder-only 模型为什么通常没有 cross-attention？
 decoder-only 模型没有单独 encoder。prompt、上下文和生成内容都放在同一个序列中，通过 masked self-attention 建模。所有可见信息都来自同一条上下文序列，不需要再通过 cross-attention 查询 encoder memory。

#### 34. decoder-only LM 的训练样本中 input 和 target 通常如何错位？
 典型 next token prediction：
```yaml
input:  x1 x2 x3 x4
target: x2 x3 x4 x5
```
模型在位置 t 的 hidden state 用来预测位置 t+1 的 token。训练时通过 causal mask 保证位置 t 只能看 <=t 的输入。

#### 35. 为什么 decoder-only 模型可以把 prompt 和生成内容放在同一个序列中处理？
 decoder-only 模型通过 causal mask 建模“前文条件化后文”的关系。prompt 位于序列前面，生成内容位于后面；后面的 token 可以关注 prompt 和已生成 token，prompt token 不需要关注未来生成内容。

 因此只要把所有内容串成一个 token 序列，masked self-attention 就能完成上下文条件化生成。

#### 36. causal mask 和 padding mask 可以同时用于 decoder 吗？二者分别屏蔽什么？
 可以同时使用。causal mask 屏蔽未来位置，保证自回归因果约束。padding mask 屏蔽无效 padding 位置，避免真实 token 读取补齐内容。

 通常二者会合并成一个 attention mask，加到 attention score 上。

### 五、架构类型对比
#### 37. encoder-only、encoder-decoder、decoder-only 三类 Transformer 分别适合什么任务？
 encoder-only 适合理解任务，如文本分类、匹配、抽取、序列标注和检索。encoder-decoder 适合输入到输出的 seq2seq 任务，如翻译、摘要、结构化转换。decoder-only 适合自回归生成，如对话、续写、代码生成、通用指令跟随。

#### 38. BERT、T5/BART、GPT/LLaMA/Qwen 分别属于哪类架构？
 BERT 是 encoder-only。T5 和 BART 是 encoder-decoder。GPT、LLaMA、Qwen 通常是 decoder-only。

 注意不同模型可能有具体变体，但面试中按这三类回答是主线。

#### 39. 为什么 encoder-only 模型不适合直接做开放式自回归生成？
 encoder-only 模型通常使用双向 self-attention，它的训练目标和结构不是逐 token 只看历史并预测未来。开放式生成需要自回归条件分解，而 encoder-only 模型没有天然的 causal generation 机制。

 可以通过额外设计做生成任务，但它不是最自然、最高效的架构选择。

#### 40. 为什么 decoder-only 模型在通用大语言模型中非常流行？
 decoder-only 架构与 next token prediction 高度匹配。大规模文本可以直接构造成“根据前文预测后文”的训练样本，无需人工标注。推理时同一机制可以做续写、对话、问答、代码生成和工具调用格式输出。

 它结构相对统一，易于扩展规模，并且 prompt 可以自然作为上下文条件。

#### 41. 如果面试官问“Transformer 就是 ChatGPT 的结构吗”，你会如何回答？
 应该回答：ChatGPT 类模型通常基于 Transformer 的 decoder-only 变体，但 Transformer 本身是更广义的架构家族。原始 Transformer 是 encoder-decoder，用于机器翻译；后续有 encoder-only、encoder-decoder、decoder-only 等多种结构。ChatGPT 还包含大规模预训练、指令微调、偏好对齐、推理系统等，不只是一个裸 Transformer。

#### 42. encoder-decoder 模型和 decoder-only 模型在输入输出建模方式上有什么差异？
 encoder-decoder 明确区分 source 和 target。source 由 encoder 双向编码，target 由 decoder 自回归生成，并通过 cross-attention 读取 source memory。

 decoder-only 把 prompt 和目标输出都放在同一序列中，用 causal mask 保证每个位置只看前文。它没有单独 source memory，条件信息来自前缀上下文。

### 六、Decoding 基础
#### 43. 语言模型输出 logits 后，为什么还需要 decoding 策略？
 logits 只是模型对词表中每个 token 的分数。decoding 策略决定如何从这些分数或概率中选出实际下一个 token。不同策略会改变生成的确定性、多样性、重复率和稳定性。

 同一个模型、同一个 prompt，用不同 decoding 参数可能生成完全不同风格的输出。

#### 44. logits 和 probability 的区别是什么？softmax 在生成中起什么作用？
 logits 是未归一化分数，可以是任意实数。probability 是归一化后的非负概率，所有 token 概率和为 1。

 softmax 将 logits 转成概率分布：
```text
p_i = exp(logit_i) / sum_j exp(logit_j)
```
sampling 类 decoding 需要概率分布才能随机采样。

#### 45. greedy decoding 的流程是什么？它有什么优点和缺点？
 greedy decoding 每一步选择概率最高的 token：
```text
next_token = argmax(logits)
```
优点是简单、确定、速度快。缺点是缺乏多样性，容易陷入局部最优，开放式生成中可能重复、无聊或风格僵硬。

#### 46. sampling decoding 的基本思想是什么？它和 greedy 的关键区别是什么？
 sampling decoding 按模型给出的概率分布随机抽取下一个 token，而不是总选最大概率 token。高概率 token 更容易被选中，但低概率 token 也有机会出现。

 关键区别是：greedy 是确定性的 argmax，sampling 是随机的 multinomial draw。sampling 更有多样性，但也更可能生成不稳定内容。

#### 47. 为什么开放式生成中纯 greedy 或 beam search 容易出现重复、无聊或退化输出？
 开放式语言生成不是只有一个确定正确答案。纯 greedy 和 beam search 偏向高概率序列，容易选择安全、常见、重复的表达。研究中也观察到高概率最大化不一定对应人类偏好的自然文本。

 因此开放式生成常引入 sampling、top-k、top-p、temperature 等策略来增加合理多样性。

#### 48. decoding 策略能否弥补模型本身能力不足？为什么？
 不能从根本上弥补。decoding 只改变如何从模型给出的分布中选择 token。如果模型本身没有学会某项知识，或者 prompt 缺少必要信息，调参不能凭空产生可靠能力。

 decoding 可以改善风格、多样性、重复和保守程度，但不是能力训练或知识注入的替代。

### 七、Temperature
#### 49. temperature scaling 的公式是什么？
 公式是：
```text
p_i = softmax(logit_i / T)
```
其中 T 是 temperature。实现中通常先把 logits 除以 temperature，再 softmax 或进入后续采样过滤。

#### 50. temperature 小于 1、等于 1、大于 1 时，输出分布分别会怎样变化？
 T=1 保持原始分布。 T<1 会放大 logits 差异，使分布更尖锐，高概率 token 更占优势，输出更确定。 T>1 会缩小 logits 差异，使分布更平坦，低概率 token 更容易被采样，输出更多样。

#### 51. 为什么 temperature -> 0 时接近 greedy decoding？
 当 temperature 趋近 0 时，logits 被除以一个极小正数，最大 logit 与其他 logit 的差距被极度放大。softmax 后最大 logit 对应 token 的概率趋近 1，其他 token 概率趋近 0，因此采样结果接近 argmax，也就是 greedy。

#### 52. temperature 是否会删除候选 token？它和 top-k/top-p 的区别是什么？
 temperature 不删除候选 token，只改变分布尖锐程度。只要 token 原本概率非零，temperature 调整后仍可能被采样。

 top-k 和 top-p 是过滤策略，会把候选集合外的 token 概率置为 0。简化理解：temperature 改形状，top-k/top-p 改候选范围。

#### 53. 在格式遵循、代码生成、创意写作三个场景中，temperature 应该如何倾向性设置？
 格式遵循通常用较低 temperature，降低随机性，提升稳定输出。代码生成也常用较低或中低 temperature，尤其是要求正确性时。创意写作可以用中等或稍高 temperature，以获得更多表达变化。

 实际参数要结合模型和任务调试。高温度不等于高质量创造，过高会跑题。

#### 54. temperature 过高可能带来哪些风险？
 temperature 过高会让低概率 token 更容易出现，导致输出跑题、事实错误、幻觉增加、格式破坏、逻辑不稳定。对于需要严格遵循格式或准确性的任务，高 temperature 风险较大。

### 八、Top-k Sampling
#### 55. top-k sampling 的完整流程是什么？
 流程：

 计算下一个 token 的 logits 或概率。

 选出分数最高的 k 个 token。

 将其他 token 的 logits 设为 -inf 或概率设为 0。

 对剩余 token 重新 softmax/归一化。

 从这 k 个候选中按概率采样。

 关键是 top-k 只是限制采样池，不是直接取最大值。

#### 56. top-k 中的 k 表示什么？ top_k=1 与 greedy decoding 有什么关系？
 k 表示保留概率或 logit 最高的 k 个候选 token。 top_k=1 时候选集合只有最高分 token，如果再从这个集合采样，必然选它，因此等价于 greedy decoding。

#### 57. top-k sampling 是“选 top-k 中概率最高的 token”吗？请解释。
 不是。top-k sampling 是先筛出 top-k 个候选，然后在候选集合内按概率随机采样。如果总是选 top-k 中概率最高的 token，那就退化成 greedy。

 这个区别在面试中很重要：top-k 是过滤加采样，不是排序后取第一。

#### 58. top-k sampling 为什么能减少低质量 token 的干扰？
 语言模型词表很大，长尾 token 虽然每个概率很低，但数量很多。纯 sampling 可能偶然抽到低质量或不合适 token。top-k 先去掉低排名 token，只从模型认为最可能的一部分候选中采样，从而降低噪声。

#### 59. top-k 的固定候选数量会带来什么问题？
 固定 k 不会根据当前分布形状自适应。如果分布很尖锐，较大 k 会保留很多不必要候选；如果分布很平坦，较小 k 会过滤掉合理候选，降低多样性。

 这正是 top-p 相比 top-k 更动态的原因。

#### 60. 如果当前分布很尖锐，使用很大的 k 可能有什么影响？如果当前分布很平坦，使用很小的 k 又有什么影响？
 分布很尖锐时，大多数概率集中在少数 token 上，很大的 k 会把许多低质量低概率 token 纳入候选，增加跑偏风险。分布很平坦时，合理候选较多，很小的 k 会过度截断，输出可能保守、缺乏多样性，甚至排除正确候选。

### 九、Top-p / Nucleus Sampling
#### 61. top-p sampling 的完整流程是什么？
 流程：

 对 token 按概率从高到低排序。

 从最高概率 token 开始累加概率。

 找到累计概率达到 p 的最小候选集合。

 将集合外 token 的概率设为 0。

 对集合内概率重新归一化。

 从集合内按概率采样。

#### 62. top-p 中的 p 表示什么？它是不是“保留概率大于 p 的 token”？
 p 表示累计概率阈值，不是单个 token 的概率阈值。 top_p=0.9 表示保留按概率排序后累计概率达到 0.9 的最小 token 集合。

 常见错误是理解成“保留每个概率大于 0.9 的 token”，这几乎总是不合理，因为单个 token 概率通常不会这么高。

#### 63. 为什么 top-p 又叫 nucleus sampling？
 因为它保留的是当前概率分布的“核心”候选集合，也就是累计概率质量达到 p 的最小集合。这个核心集合大小会随上下文和分布形状动态变化。

#### 64. top-p 相比 top-k 的核心优势是什么？
 top-p 的候选集合大小是动态的。分布尖锐时，它可能只保留少数 token；分布平坦时，它会保留更多 token。这比固定 k 更能适应不同上下文中的不确定性。

#### 65. top_p=0.9 与 top_p=0.95 在候选集合和输出多样性上可能有什么区别？
 top_p=0.95 通常保留更多累计概率质量，因此候选集合往往更大，输出更多样，但跑偏风险也更高。 top_p=0.9 更保守，候选集合更小，输出更稳定。

 具体效果取决于当前概率分布。若分布非常尖锐，二者差异可能不大。

#### 66. top-k 和 top-p 能否同时使用？同时使用时它们各自起什么作用？
 可以同时使用。top-k 设置候选数量上限，避免候选集合过大；top-p 根据累计概率动态选择核心候选。组合后通常先经过一个过滤，再经过另一个过滤，最终从交集或进一步筛选后的集合中采样。

 实际框架顺序可能不同，但直觉是：top-k 控制最多看多少个，top-p 控制保留多少概率质量。

### 十、实现、调参和排错
#### 67. 请写出一个包含 temperature、top-k、top-p 的 next-token sampling 伪代码流程。
```python
def sample_next(logits, temperature=1.0, top_k=None, top_p=None):
    if temperature <= 0:
        return argmax(logits)

    logits = logits / temperature

    if top_k is not None:
        keep only top_k logits
        set other logits to -inf

    if top_p is not None:
        sort logits by probability descending
        compute cumulative probability
        keep the smallest prefix with cumulative prob >= top_p
        set other logits to -inf
        scatter back to original vocabulary order

    probs = softmax(logits)
    return multinomial_sample(probs)
```
关键得分点：temperature 先缩放 logits；top-k/top-p 过滤；过滤后重新归一化；最后按概率采样。

#### 68. 过滤 top-k 或 top-p 后，为什么需要重新归一化概率？
 过滤后集合外 token 概率被置为 0，剩余 token 的概率和通常小于 1。要从剩余候选中采样，需要让候选集合内概率重新归一化为和 1。

 如果不重新归一化，概率分布不合法，采样实现也可能行为不符合预期。

#### 69. top-p 实现中为什么要先按概率降序排序？
 top-p 要找到“累计概率达到 p 的最小高概率候选集合”。只有先按概率从高到低排序，才能从最可能 token 开始累加，并保证得到的是最小的核心集合。

 不排序直接累加会依赖词表原始顺序，语义错误。

#### 70. 实现 top-p 时，为什么通常要保留第一个超过阈值的 token？
 因为 top-p 的目标是让保留集合的累计概率至少达到 p。如果一旦超过阈值就把该 token 删除，保留集合累计概率可能低于 p。常见实现会让“第一个使累计概率超过 p 的 token”保留下来，再删除其后的 token。

 这也是很多 top-p 实现中会对 boolean mask 右移一位的原因。

#### 71. 如果生成内容重复严重，可以从 decoding 参数角度做哪些调整？
 可以适当提高 temperature，使用 top-p 或 top-k sampling，而不是纯 greedy；也可以降低 beam search 依赖，加入 repetition penalty、no-repeat-ngram、presence/frequency penalty 等。若 top-p 太低或 temperature 太低，也可能导致输出过于保守和重复。

 但重复也可能来自模型训练或 prompt 问题，decoding 只能部分缓解。

#### 72. 如果生成内容太随机、跑题或幻觉增加，可以从 decoding 参数角度做哪些调整？
 可以降低 temperature，降低 top_p，减小 top_k，或改用 greedy/更保守的 sampling。对于事实性问答和格式输出，建议使用较低随机性参数。

 也要检查 prompt 是否明确、上下文是否足够，以及是否需要检索增强或约束解码。

#### 73. 如果模型需要稳定输出 JSON，应该如何设置 decoding 参数？
 倾向使用低 temperature，较低 top_p，甚至 greedy decoding。目标是减少随机性，提升格式稳定性。还可以结合 stop tokens、schema 校验、重试、grammar constrained decoding 或 function calling。

 只靠 sampling 参数不能保证 JSON 永远合法，工程上应加入解析校验和错误恢复。

#### 74. 在 Hugging Face generate 中， do_sample=True 、 top_k 、 top_p 、 temperature 分别控制什么？
 do_sample=True 启用随机采样；否则默认常是 greedy 或 beam 类确定性搜索。 top_k 控制保留概率最高的 k 个候选。 top_p 控制保留累计概率达到 p 的 nucleus 候选集合。 temperature 控制 logits 缩放，影响分布尖锐程度。

 典型开放式生成会组合使用：
```text
model.generate(
    **inputs,
    do_sample=True,
    temperature=0.7,
    top_p=0.9,
    top_k=50,
)
```
#### 75. 请总结今天的知识链路：从 token id 到 embedding，到 Transformer encoder/decoder，再到 logits 和 decoding。
 文本先经过 tokenizer 变成 token id，shape 是 [B, T]。embedding table 把 id 映射成 [B, T, d_model]，再融合位置信息。encoder 用双向 self-attention 编码完整输入；decoder 用 masked self-attention 保证自回归约束，encoder-decoder 里的 decoder 还通过 cross-attention 读取 encoder 输出。decoder-only LLM 省略 encoder，把 prompt 和生成内容放在同一序列中做 next token prediction。

 模型最终输出 [B, T, V] logits。生成时取最后位置 logits，通过 temperature 调整分布，用 top-k/top-p 过滤候选，再 softmax 归一化并采样下一个 token。这个 token 拼回上下文，循环生成后续 token。

 这是第二天内容的完整闭环。
