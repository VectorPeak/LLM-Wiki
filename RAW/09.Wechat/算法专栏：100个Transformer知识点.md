---
title: "算法专栏：100个Transformer知识点"
source: "https://mp.weixin.qq.com/s/NDjDRtVQXooR08nTKD-99A"
author:
  - "[[乔木mq]]"
published:
created: 2026-05-19
description: "1. Transformer 是什么？→ 一种基于自注意力机制的序列到序列模型，2017 年由 Vaswani 等人提出，取代 RNN/CNN 成为 NLP 主流架构。"
tags:
  - "clippings"
---
乔木mq *2026年4月28日 07:17*

1. 1\. Transformer 是什么？  
	→ 一种基于自注意力机制的序列到序列模型，2017 年由 Vaswani 等人提出，取代 RNN/CNN 成为 NLP 主流架构。
2. 2\. 为什么叫 “Transformer”？  
	→ 强调“转换”输入序列表示的能力，通过注意力机制动态重组信息。
3. 3\. 核心创新点是什么？  
	→ 自注意力机制（Self-Attention） + 并行化训练（无递归依赖）。
4. 4\. 相比 RNN/LSTM 的优势？  
	→ 并行计算快、长距离依赖建模强、梯度传播更稳定。
5. 5\. Encoder-Decoder 架构的作用？  
	→ Encoder 编码输入语义，Decoder 逐词生成输出（如机器翻译）。
6. 6\. 纯 Decoder 架构（如 GPT）适用场景？  
	→ 自回归生成任务（文本续写、对话），无需编码器。
7. 7\. 纯 Encoder 架构（如 BERT）适用场景？  
	→ 理解型任务（分类、问答、NER），双向上下文建模。
8. 8\. 输入如何表示？  
	→ Token ID → Embedding 向量 + Positional Encoding。
9. 9\. 为什么需要位置编码（Positional Encoding）？  
	→ Transformer 无顺序感知，需显式注入位置信息。
10. 10\. 位置编码类型？  
	→ 固定（正弦/余弦函数） vs 可学习（参数化）。
11. 11\. 为什么用正弦函数做位置编码？  
	→ 能表示绝对位置，且任意偏移可线性表示（利于外推）。
12. 12\. Embedding 层后为何乘以 √dₘₒᵈₑₗ？  
	→ 抵消位置编码对向量范数的影响，保持数值稳定。
13. 13\. Tokenization 常见方法？  
	→ WordPiece（BERT）、BPE（GPT）、SentencePiece（T5）。
14. 14\. 最大序列长度限制原因？  
	→ 注意力矩阵 O(n²) 内存消耗，硬件限制。
15. 15\. 如何处理超长序列？  
	→ 滑动窗口、稀疏注意力、Longformer、FlashAttention。
16. 16\. Self-Attention 公式？  
	→ Attention(Q,K,V) = softmax(QKᵀ/√dₖ)V
17. 17\. Q, K, V 从哪来？  
	→ 输入 X 分别乘以三个可学习权重矩阵 W\_Q, W\_K, W\_V。
18. 18\. 为什么 Q 和 K 要不同？  
	→ 若相同，则相似度仅反映自身，无法建模交互。
19. 19\. 为何用点积而非加法？  
	→ 点积计算快、可并行，且等价于缩放后的余弦相似度。
20. 20\. 为何要 scaled（除以 √dₖ）？  
	→ 防止 dₖ 大时 softmax 进入饱和区（梯度消失）。
21. 21\. Softmax 的作用？  
	→ 将相似度转为概率分布，实现加权聚合。
22. 22\. Masked Self-Attention 是什么？  
	→ Decoder 中防止看到未来 token（下三角 mask）。
23. 23\. Padding Mask 如何实现？  
	→ 将 padding 位置设为 -∞，softmax 后权重为 0。
24. 24\. 多头注意力（Multi-Head）动机？  
	→ 捕捉不同子空间的特征（如语法、语义、指代）。
25. 25\. 多头如何实现？  
	→ 将 Q,K,V 分成 h 组，每组独立计算注意力，再拼接投影。
26. 26\. 头数越多越好吗？  
	→ 不一定，过多增加计算量，可能过拟合（BERT 用 12 头）。
27. 27\. 多头后为何要线性变换？  
	→ 融合各头信息，恢复维度（W\_O ∈ ℝ^{hd\_v × d\_model}）。
28. 28\. 自注意力复杂度？  
	→ 时间/空间均为 O(n²d)，n=序列长，d=维度。
29. 29\. 能否替代 CNN/RNN？  
	→ 在多数 NLP 任务中已取代；CV 中与 CNN 融合（如 ConvNeXt）。
30. 30\. 自注意力能捕捉局部特征吗？  
	→ 可以，但不如 CNN 高效（需大量数据学习局部模式）。
31. 31\. 注意力权重可视化意义？  
	→ 分析模型关注点（如问答中聚焦关键词）。
32. 32\. 交叉注意力（Cross-Attention）是什么？  
	→ Decoder 中 Q 来自前一层，K/V 来自 Encoder 输出。
33. 33\. 为什么交叉注意力有效？  
	→ 实现输入-输出对齐（如翻译中源词→目标词）。
34. 34\. 自注意力是置换不变的吗？  
	→ 否！因有位置编码，顺序敏感。
35. 35\. 能否无位置编码工作？  
	→ 短序列可能，但性能大幅下降（失去顺序信息）。
36. 36\. Encoder 层结构？  
	→ Multi-Head Attention → Add & Norm → FFN → Add & Norm
37. 37\. Decoder 层结构？  
	→ Masked MHA → Add & Norm → Cross-Attention → Add & Norm → FFN → Add & Norm
38. 38\. 残差连接（Residual Connection）作用？  
	→ 缓解梯度消失，加速训练，保留原始信息。
39. 39\. Layer Normalization 作用？  
	→ 稳定训练，加速收敛（比 BatchNorm 更适合序列）。
40. 40\. 为何用 LayerNorm 而非 BatchNorm？  
	→ BN 依赖 batch 统计，小 batch 或变长序列不稳定。
41. 41\. 前馈网络（FFN）结构？  
	→ 两层全连接：d\_model → d\_ff → d\_model（ReLU 激活）
42. 42\. d\_ff 通常多大？  
	→ 2048（BERT）或 4×d\_model（如 768→3072）
43. 43\. 激活函数选择？  
	→ ReLU（原始论文），GELU（BERT），SwiGLU（LLaMA）
44. 44\. Dropout 用在哪？  
	→ Attention 输出、FFN、Embedding（防过拟合）
45. 45\. 初始化策略？  
	→ Xavier/Glorot 初始化，或特定缩放（如 LLaMA）
46. 46\. 输出如何生成？  
	→ Decoder 最后一层 → Linear（vocab\_size） → Softmax
47. 47\. 共享 Embedding 与 Output Weight？  
	→ 是（原始论文），减少参数，提升泛化。
48. 48\. 为什么能共享？  
	→ 输入/输出同词汇表，语义空间一致。
49. 49\. Encoder 和 Decoder 参数是否共享？  
	→ 通常不共享（任务不对称），但 T5 等统一架构会共享。
50. 50\. 如何处理变长输入？  
	→ Padding + Mask，或动态批处理（bucketing）
51. 51\. 最大长度超了怎么办？  
	→ 截断（truncate）或分段处理（sliding window）
52. 52\. Batch 内序列长度不同如何处理？  
	→ Padding 至最长，配合 attention mask
53. 53\. 训练时 Decoder 输入是什么？  
	→ Ground truth 右移一位（teacher forcing）
54. 54\. 推理时如何生成？  
	→ 自回归：逐 token 生成，作为下一步输入
55. 55\. Beam Search 作用？  
	→ 改进贪心搜索，保留 top-k 候选，提升生成质量
56. 56\. 损失函数？  
	→ 交叉熵（Cross-Entropy） + Label Smoothing（防过拟合）
57. 57\. Label Smoothing 作用？  
	→ 软化 one-hot 标签，提升泛化，缓解置信度过高
58. 58\. 优化器选择？  
	→ AdamW（带权重衰减的 Adam）
59. 59\. 学习率调度？  
	→ Warmup + Decay（如 linear decay, cosine）
60. 60\. 为何需要 Warmup？  
	→ 初始阶段梯度不稳定，逐步增大学习率更稳
61. 61\. Batch Size 如何选？  
	→ 越大越好（但受显存限制），常用 256~4096
62. 62\. 梯度裁剪（Gradient Clipping）？  
	→ 防止梯度爆炸（尤其在长序列）
63. 63\. 如何防止过拟合？  
	→ Dropout、Weight Decay、Early Stopping、Data Augmentation
64. 64\. 预训练 + 微调范式？  
	→ 先在大规模语料预训练，再在下游任务微调
65. 65\. MLM（掩码语言建模）？  
	→ BERT 预训练任务：预测被 mask 的词
66. 66\. NSP（下一句预测）？  
	→ BERT 早期任务，现多被弃用（效果有限）
67. 67\. 自回归预训练（如 GPT）？  
	→ 预测下一个 token，最大化似然
68. 68\. 对比学习在 Transformer 中的应用？  
	→ SimCSE、ColBERT 等用于句子表示
69. 69\. 混合精度训练（AMP）？  
	→ FP16 加速 + 梯度缩放，节省显存
70. 70\. 分布式训练策略？  
	→ Data Parallelism（数据并行）、Tensor Parallelism（张量并行）
71. 71\. ZeRO 优化是什么？  
	→ DeepSpeed 的内存优化技术，分片存储优化器状态
72. 72\. 如何评估模型性能？  
	→ Perplexity（语言建模）、Accuracy/F1（分类）、BLEU/ROUGE（生成）
73. 73\. 训练不稳定怎么办？  
	→ 检查 learning rate、batch size、初始化、gradient norm
74. 74\. Loss 不下降可能原因？  
	→ 学习率太低、模型容量不足、数据噪声大
75. 75\. 如何调试注意力？  
	→ 可视化 attention weights，检查是否聚焦合理位置
76. 76\. 推理加速技术？  
	→ KV Cache（避免重复计算）、FlashAttention（IO 优化）
77. 77\. KV Cache 原理？  
	→ 缓存历史 K/V，生成新 token 时复用
78. 78\. 模型压缩方法？  
	→ 剪枝（Pruning）、量化（Quantization）、蒸馏（Distillation）
79. 79\. INT8 量化效果？  
	→ 体积减 75%，速度翻倍，精度损失 <1%
80. 80\. ONNX 导出作用？  
	→ 跨框架部署（PyTorch → TensorRT/OpenVINO）
81. 81\. TensorRT 优化？  
	→ 层融合、内核自动调优，极致推理加速
82. 82\. 如何支持长上下文？  
	→ RoPE（旋转位置编码）、ALiBi（相对位置 bias）
83. 83\. RoPE 原理？  
	→ 用旋转矩阵编码相对位置，支持外推
84. 84\. ALiBi 是什么？  
	→ Attention Bias 随距离衰减，无需位置编码
85. 85\. LoRA 微调原理？  
	→ 低秩适配：冻结原权重，只训练低秩增量矩阵
86. 86\. QLoRA 是什么？  
	→ 4-bit 量化 + LoRA，可在消费级 GPU 微调大模型
87. 87\. Hugging Face Transformers 库作用？  
	→ 提供预训练模型、Tokenizer、Trainer 一站式工具
88. 88\. 如何加载本地模型？  
	→ `from_pretrained("path/to/model")`
89. 89\. Tokenizer 如何保存/加载？  
	→ `tokenizer.save_pretrained()` / `AutoTokenizer.from_pretrained()`
90. 90\. 如何监控训练？  
	→ Weights & Biases、TensorBoard 记录 loss/metrics
91. 91\. Vision Transformer（ViT）？  
	→ 将图像分块，用 Transformer 建模（取代 CNN）
92. 92\. Swin Transformer？  
	→ 引入滑动窗口，实现局部+全局注意力（适合检测/分割）
93. 93\. Perceiver / Perceiver IO？  
	→ 处理多模态输入（图像、音频、文本统一架构）
94. 94\. Mamba 架构？  
	→ 替代注意力的状态空间模型（SSM），O(n) 复杂度
95. 95\. RetNet？  
	→ 微软提出的 RNN+Attention 混合架构，兼顾效率与性能
96. 96\. MoE（Mixture of Experts）？  
	→ 每层激活部分专家（如 Mixtral），提升容量不增计算
97. 97\. Ring Attention？  
	→ 分布式注意力，突破单机显存限制
98. 98\. Agent 与 Transformer 结合？  
	→ 用 Transformer 作为 Agent 的“大脑”，调用工具链
99. 99\. RAG（检索增强生成）？  
	→ 检索外部知识 + Transformer 生成，解决幻觉
100. 100\. 未来方向？  
	→ 更高效注意力（线性/稀疏）、多模态统一、具身智能、世界模型

算法工程师 · 目录

继续滑动看下一个

乔木mq

向上滑动看下一个