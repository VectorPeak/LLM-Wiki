---
title: "算法面试专栏：Transformer100问"
source: "https://mp.weixin.qq.com/s/BZaJfB5tzU700GDUVY2AMg"
author:
  - "[[乔木mq]]"
published:
created: 2026-05-19
description: "1. 推导标准 Multi-Head Attention 中 Query、Key、Value 的投影矩阵维度"
tags:
  - "clippings"
---
乔木mq *2026年4月2日 06:22*

1. 1\. 推导标准 Multi-Head Attention 中 Query、Key、Value 的投影矩阵维度：若输入 ，头数为 ，每个头维度为 ，写出 的具体形状，并分析为何 过大会导致 softmax 梯度消失。
2. 2\. FlashAttention-2 通过分块计算和重计算（recomputation）减少 HBM 访问。推导其在计算 时的 SRAM 带宽节省量，并分析 tile size 对 GPU warp 利用率的影响。
3. 3\. 在 Ring Attention 中，序列被切分为 段并在环形拓扑中流水线处理。推导其通信复杂度 与计算复杂度 的平衡点，并分析在 A100 NVLink 环境下的最优 选择。
4. 4\. ALiBi（Attention with Linear Biases）使用 作为位置偏置。推导其在长序列推理中如何避免 RoPE 的旋转矩阵累积误差，并证明其对相对位置编码的 Lipschitz 连续性。
5. 5\. RoPE（Rotary Position Embedding）将位置信息注入到 query/key 中：。推导其满足 的数学条件，并分析为何该性质支持外推（extrapolation）。
6. 6\. 在训练 70B 模型时，ZeRO-3 将 optimizer states、梯度、参数分别分片到不同 GPU。推导单卡显存占用公式：（单位：字节），并计算在 8\*A100@80G 下可训练的最大模型规模。
7. 7\. QLoRA 使用 4-bit NormalFloat 量化主权重，并引入 LoRA 适配器。推导其反向传播时梯度仅流经 LoRA 分支的数学依据，并分析为何 quantization constant 需按通道统计。
8. 8\. 在 MoE 架构中，Top-K 路由选择 K 个专家。推导当 K=2 时，辅助负载均衡损失 中路由概率 与 token 专家频率 的梯度耦合机制。
9. 9\. 分析 Transformer FFN 层中 SwiGLU 激活函数 相比 ReLU 在梯度平滑性和表达能力上的优势，并推导其 Hessian 条件数更小的理论依据。
10. 10\. 在混合精度训练中，FP16 下 softmax 的 可能下溢。推导 log-sum-exp 技巧的数值稳定实现，并分析其在 A100 Tensor Core 上的指令级优化机会。
11. 11\. 推导 RMSNorm 相比 LayerNorm 减少的参数量：无 bias 和 gain 参数，并证明其在保持梯度方差稳定的同时降低通信开销（在模型并行中）。
12. 12\. 在多模态大模型中，视觉 token 与文本 token 共享同一 Transformer。推导 cross-attention 层中 Q 来自文本、KV 来自图像时的 KV Cache 复用策略，并分析其对推理延迟的影响。
13. 13\. GQA（Grouped-Query Attention）将多个 query 头共享同一组 key/value 头。推导其在 KV Cache 显存上从 降至 的压缩比（ 为组数），并分析 过大对生成质量的影响。
14. 14\. 在 DPO（Direct Preference Optimization）中，目标函数为 。推导其等价于隐式优化一个特定奖励函数的数学证明。
15. 15\. 分析 LLaMA 架构中移除 bias 项对模型容量的影响：推导无 bias 的线性层 在零均值输入下的输出方差，并讨论其与 Pre-LN 结构的兼容性。
16. 16\. 在长上下文训练中，NTK-aware 插值如何调整 RoPE 的基频 ？推导缩放因子 与上下文长度 的关系 ，并分析其对高频位置信号的保留效果。
17. 17\. 推导 DeepSpeed 的 activation checkpointing 在 Transformer 层中的内存-计算权衡：若每层保存输入而非中间激活，显存从 降至 ，但反向传播需重计算 attention 和 FFN。
18. 18\. 在 speculative decoding 中，draft model 提前生成候选 token。推导其验证阶段在 target model 上的并行注意力计算如何通过 KV Cache 重用减少冗余计算。
19. 19\. 分析 MQA（Multi-Query Attention）在 batch size=1 推理时的加速比：由于 KV Cache 仅需存储一份，带宽需求从 降至 ，推导其在 A100 上的理论吞吐提升。
20. 20\. 在训练稳定性方面，Pre-LN 与 Post-LN 的梯度范数差异显著。推导 Post-LN 中顶层梯度放大 倍的现象，并解释为何 Pre-LN 更适合深层模型训练。
21. 21\. 推导 Rotary Embedding 的复数形式实现：将 维向量视为 个复数，旋转操作等价于逐元素复乘 ，并分析其在 CUDA kernel 中的向量化效率。
22. 22\. 在分布式推理中，Tensor Parallelism 将 attention 头切分到不同设备。推导 All-Gather 操作在 softmax 前合并 partial attention score 的通信量 。
23. 23\. 分析 LLaMA-2 的 context length 从 2k 扩展到 4k 时，RoPE 插值导致的位置编码失真。推导相邻位置间内积 的衰减率，并提出 NTK-finetuning 的补偿方案。
24. 24\. 在 MoE 模型中，专家容量因子（capacity factor）设为 1.25。推导当实际路由超过容量时，丢弃 token 的梯度如何通过 straight-through estimator 近似回传。
25. 25\. 推导 FlashAttention 的 backward pass 中，softmax 的梯度 如何与 recompute 的 结合以避免存储 。
26. 26\. 在 INT4 量化部署中，weight-only 量化假设激活为 FP16。推导其对 attention 输出误差的上界 ，并分析 outlier channel 对误差的主导作用。
27. 27\. 分析 GQA 在训练 vs 推理中的收益差异：训练时 batch size 大，KV Cache 节省有限；推理时 batch=1，显存节省显著。推导其在 vLLM PagedAttention 中的 page table 优化机会。
28. 28\. 在 long-context 微调中，YaRN（Yet another RoPE extensioN）使用温度缩放和微调。推导其动态调整 的公式 ，其中 为扩展因子。
29. 29\. 推导 Transformer 层的 FLOPs 计算公式：Attention 为 ，FFN 为 ，并分析在 时 attention 成为瓶颈的临界点。
30. 30\. 在多任务指令微调中，task prefix 如何影响 attention 分布？推导 prefix token 作为 soft prompt 在 key/value 中的注入方式，并分析其与 hard prompt 的梯度隔离效应。
31. 31\. 分析 ZeRO-1 与 ZeRO-2 的通信模式差异：ZeRO-1 仅分片 optimizer states，all-reduce 在梯度同步后执行；ZeRO-2 分片梯度，通信被拆分为多次 reduce-scatter。
32. 32\. 在 sparse attention 中，BigBird 使用随机、滑动窗口和全局 attention。推导其稀疏模式下 attention 矩阵的连通性条件，并证明其可逼近全注意力的表达能力。
33. 33\. 推导 LLaMA 的 SiLU 激活函数在反向传播中的梯度公式：。
34. 34\. 在 continuous batching 推理引擎（如 vLLM）中，PagedAttention 如何解决 KV Cache 内存碎片？推导其虚拟 block 与物理 block 的映射表更新复杂度。
35. 35\. 分析 RoPE 在 zero-shot 泛化中的失败案例：当测试序列远长于训练序列时，高频旋转导致位置混淆。推导其最大可泛化长度 。
36. 36\. 在 DPO 训练中，reference model 通常冻结。推导其 logits 缓存策略如何减少重复 forward，并分析缓存显存与 batch size 的线性关系。
37. 37\. 推导 grouped-query attention 在 multi-head 实现中的 reshape 操作：将 个 head 重组为 组，每组包含 个 query 但共享 1 个 key/value。
38. 38\. 在混合专家模型中，expert parallelism 与 data parallelism 正交。推导其通信模式：All-to-All 用于 token dispatch，All-Reduce 用于 expert 参数同步。
39. 39\. 分析 FP8 训练中 E4M3 与 E5M2 格式的 trade-off：E4M3 动态范围小但精度高，适合 activations；E5M2 范围大但精度低，适合 weights。推导其在 transformer 层中的分配策略。
40. 40\. 在 long-sequence 训练中，memorization 与 generalization 的冲突加剧。推导基于 curriculum learning 的序列长度调度策略：。
41. 41\. 推导 RMSNorm 的反向传播公式：若 ，则 。
42. 42\. 在 speculative decoding 中，若 draft model 生成 k 个候选，target model 验证的期望接受率为 。推导其理论加速比 。
43. 43\. 分析 LLaMA 架构中移除 dropout 对过拟合的影响：在大规模数据下，显式正则化非必需，但小数据微调时需重新引入。推导其与 weight decay 的等效性条件。
44. 44\. 在多语言模型中，language-specific positional encoding 是否必要？推导共享 RoPE 在跨语言迁移中的位置对齐误差，并提出 language-adaptive frequency scaling。
45. 45\. 推导 FlashAttention-2 的 warp-level 并行策略：每个 warp 处理一个 tile 的 Q 和 K，利用 shared memory 减少 global memory 访问，并分析其对 bank conflict 的规避设计。
46. 46\. 在 MoE 模型中，auxiliary loss 的权重 过大会导致 routing entropy 过高。推导 optimal 与 expert utilization rate 的关系，并提出动态调整策略。
47. 47\. 分析 GQA 在多头设置下的 head collapse 现象：当 group size 过大，query diversity 下降。推导其与 attention entropy 的负相关性。
48. 48\. 在 DPO 中， 参数控制策略偏离 reference model 的程度。推导当 时，DPO 退化为 behavioral cloning 的极限情况。
49. 49\. 推导 rotary embedding 的矩阵形式：，并证明其满足 。
50. 50\. 在 ZeRO-3 中，参数分片在 forward 前 gather，backward 后 scatter。推导其通信时机与 pipeline parallelism 的 overlap 策略，以隐藏通信延迟。
51. 51\. 分析 QLoRA 的 4-bit NormalFloat 量化：其 clipping threshold 设为均方根（RMS）而非 max。推导其对 outlier 保留的统计优势，并对比与 INT4 的精度差异。
52. 52\. 在 long-context 模型中，self-attention 的 quadratic complexity 成为瓶颈。推导 linear attention（如 Performer）的 FAVOR+ 机制：。
53. 53\. 推导 SwiGLU 在 FFN 中的参数量：，，总参数为 ，比标准 GLU 多 。
54. 54\. 在 vLLM 的 PagedAttention 中，block size 设为 16。推导其内部碎片率上界为 ，并分析动态 block size 的优化空间。
55. 55\. 分析 RoPE 在 relative position encoding 中的群表示性质：旋转操作构成 SO(2) 群的表示，保证相对位置不变性。
56. 56\. 在 DPO 训练中，preference data 的噪声（如错误标注）会导致 reward hacking。推导 robust DPO 的 loss clipping 机制：限制 log-ratio 的绝对值不超过阈值。
57. 57\. 推导 MQA 在 decoder-only 模型中的 KV Cache 存储格式：每个 layer 仅存一份 ，而非 份。
58. 58\. 在 MoE 的 expert selection 中，TopK 实现常使用 torch.topk。分析其在 GPU 上的 cublasLt 优化路径，并推导其时间复杂度 。
59. 59\. 分析 FP8 E4M3 在 attention softmax 前的 overflow 风险：由于未缩放的 值域大，需在 softmax 前进行 range calibration。
60. 60\. 在 speculative decoding 中，draft model 与 target model 的 vocab size 不同时如何处理？推导其 logits projection 的线性映射策略及精度损失。
61. 61\. 推导 LLaMA 的 pre-normalization 结构中，残差连接的梯度流：。
62. 62\. 在 long-sequence 微调中，full fine-tuning 显存不足。推导 LoRA 在 attention 和 FFN 中的 rank selection 策略：higher rank for lower layers。
63. 63\. 分析 GQA 在 training throughput 上的收益：由于减少了 key/value 的 matmul，FLOPs 从 降至 。
64. 64\. 在 DPO 中，reference model 的 KL penalty 隐含在目标函数中。推导其等价于在 reward function 中加入 项。
65. 65\. 推导 rotary embedding 的外推失败边界：当 ，cos/sin 值开始重复，导致位置混淆。计算 LLaMA-7B () 的最大可靠长度。
66. 66\. 在 ZeRO-3 中，activation checkpointing 与 parameter partitioning 正交。推导其组合显存公式：。
67. 67\. 分析 QLoRA 的 double quantization：对 quantization constants 再次量化。推导其额外节省的显存 per layer，并分析二阶量化误差的累积效应。
68. 68\. 在 MoE 模型中，expert capacity overflow 导致 token dropping。推导其对训练 loss 的 bias：dropped tokens 的梯度为零，导致 under-representation。
69. 69\. 推导 FlashAttention 的 tiling strategy：将 Q, K, V 分块为 和 ，确保 shared memory 容纳 元素。
70. 70\. 在 multi-turn 对话中，position id 需连续递增。分析若错误重置为 0 会导致 RoPE 位置混淆，并推导其对 attention score 的扰动量级。
71. 71\. 分析 LLaMA 的 SwiGLU 相比 GeLU 在训练速度上的优势：SiLU 可完全融合为 single CUDA kernel，减少 memory-bound 操作。
72. 72\. 在 DPO 的 preference pairs 中，若 和 长度差异大，log-prob 需长度归一化。推导 normalized log-likelihood 的引入动机。
73. 73\. 推导 GQA 的 attention output 计算：，其中每个 group 的 heads 共享同一 。
74. 74\. 在 MoE 的 router z-loss 中， 用于稳定 logits。推导其梯度 。
75. 75\. 分析 FP8 训练中，scaling factor 的 per-tensor vs per-channel 选择：attention weights 适合 per-channel，activations 适合 per-tensor。
76. 76\. 在 speculative decoding 中，target model 的 rejection 导致 rollback。推导其 KV Cache 的 efficient rollback 机制：仅 discard 最后 k tokens 的 cache。
77. 77\. 推导 RMSNorm 的 fused kernel 实现：将 division 和 multiplication 融合为 single pass，减少 memory reads。
78. 78\. 在 long-context evaluation 中，passkey retrieval 任务测试模型定位能力。推导其 success rate 与 context length 的负相关关系，并分析 attention sink 的作用。
79. 79\. 分析 RoPE 的 frequency base 的设计动机：低频编码长距离，高频编码短距离。推导其与 Fourier 特征的类比。
80. 80\. 在 DPO 中， 过小导致策略更新不足。推导 optimal 与 dataset quality 的关系：noisier data requires smaller 。
81. 81\. 推导 MQA 在 encoder-decoder 架构中的应用：decoder self-attention 用 MQA，cross-attention 仍用 MHA。
82. 82\. 在 MoE 的 load balancing 中，aux loss 的 gradient clipping 防止 router collapse。推导其 clipping threshold 与 expert count 的关系。
83. 83\. 分析 QLoRA 的 adapter placement：仅在 attention 的 和 FFN 的 up-projection 加 LoRA。推导其对下游任务性能的影响。
84. 84\. 在 FlashAttention-2 中，reduce-scatter 替代 all-reduce 用于 softmax。推导其通信量从 降至 。
85. 85\. 推导 LLaMA 的 context window 扩展中，dynamic NTK 的 interpolation 公式：，其中 。

算法工程师 · 目录

继续滑动看下一个

乔木mq

向上滑动看下一个