---
title: "大模型Harness工程20题"
source: "https://mp.weixin.qq.com/s/F0CXsAUch7nFM6jJ87B8yg"
author:
  - "[[乔木mq]]"
published:
created: 2026-05-19
description:
tags:
  - "clippings"
---
乔木mq *2026年4月17日 06:09*

1. 1\. 在使用 LM Evaluation Harness 评估 70B 模型时，若启用 vLLM 后端并设置 tensor\_parallel\_size=8，请推导其在 multi-GPU 上的 KV Cache 分片策略，并分析不同 max\_num\_seqs 配置对吞吐与显存碎片的影响。
2. 2\. 推导 Harness 中 loglikelihood 任务的 token-level loss 计算公式：给定输入序列 和目标序列 （通常 ），写出 的高效实现方式，并说明为何需禁用 future mask 重计算。
3. 3\. 当 Harness 评估支持 DPO 偏好数据集（如 win\_rate）时，若正负样本共享 prompt，推导其在 batch 内构造 paired logits 的内存布局，并分析是否可复用 KV Cache 以减少重复前向计算。
4. 4\. 在 QLoRA 微调后的模型通过 BitsAndBytes 加载至 Harness 时，若采用 nf4 量化且启用了 double\_quant，请推导反量化后权重 的数值误差上界，并分析其对 multiple-choice 任务准确率的影响。
5. 5\. 分析 Harness 在长上下文评估（如 32k tokens）中因 padding 导致的计算浪费问题。推导 packed evaluation 下 attention mask 的构建规则，并说明如何修改 DataLoader 以支持 variable-length batch packing。
6. 6\. 在多任务联合评估中，若不同任务的 sequence length 差异极大（如 512 vs 8192），推导动态批处理（dynamic batching）策略下的 worst-case 显存占用公式，并提出基于 length bucketing 的优化方案。
7. 7\. 使用 FlashAttention-2 加速 Harness 评估时，若模型启用了 ALiBi 位置偏置，请推导其在 block-wise attention 计算中对 softmax 输入的修正项，并说明为何不能直接复用标准 FA2 内核。
8. 8\. 当 Harness 与 DeepSpeed-Inference 集成时，若模型采用 MoE 架构且 expert parallelism=4，请推导其在 forward pass 中 AllToAll 通信的触发时机，并分析通信与计算 overlap 的调度策略。
9. 9\. 推导 Harness 中 generation 任务的 beam search 实现中，log-prob 累积项 的数值稳定性保障机制，并说明为何需引入 length normalization。
10. 10\. 在分布式评估场景下，若使用 FSDP 封装模型并通过 torch.distributed.launch 启动 Harness，请推导各 rank 在 gather\_scores 阶段的 all-gather 通信量，并分析是否可改用 reduce-scatter 降低带宽需求。
11. 11\. 分析 Harness 在评估数学推理任务（如 MATH）时，因 tokenizer 对 LaTeX 符号的切分导致的语义断裂问题。推导 custom detokenization 后处理规则，并说明如何对齐 model output 与 reference answer 的符号粒度。
12. 12\. 当评估模型支持工具调用（tool use）时，若 Harness 需模拟外部 API 响应，请设计 deterministic mock server 的状态机，并推导其在多轮对话中保持 session consistency 的 key-value 存储结构。
13. 13\. 在使用 GGUF 格式模型通过 llama.cpp backend 接入 Harness 时，若量化等级为 Q4\_K\_M，请推导其在 logit 输出层的 dequantization 开销占比，并分析是否值得将 final\_norm 层保留为 FP16。
14. 14\. 推导 Harness 中 multiple-choice 准确率计算的向量化实现：设 batch size 为 ，选项数为 ，logprob 总和为 ，写出 的 PyTorch 表达式并分析其 GPU 利用率。
15. 15\. 分析 Harness 在评估 RLHF 对齐模型时出现的“过度保守”现象（如频繁输出“I cannot assist”）。从 reward hacking 角度，推导其在 safety benchmark（如 BBQ）上的 false positive 成因，并提出对抗性 probe 设计方法。
16. 16\. 在 ZeRO-Inference 模式下加载 100B 模型至 Harness 时，若启用 ZeRO-3 的 parameter offloading，请推导其在 forward pass 中参数 all-gather 与 activation checkpointing 的协同调度图，并计算 peak host memory 占用。
17. 17\. 当 Harness 评估支持 Ring Attention 的百万 token 模型时，若输入序列被环形切分至 8 GPUs，请推导其在 evaluation loop 中的 global position ID 重建逻辑，并说明 causal mask 如何跨设备对齐。
18. 18\. 推导 Harness 中 loglikelihood\_rolling 任务的 sliding window 实现：设窗口大小为 ，步长为 ，总长度为 ，计算总前向次数及重叠区域的 KV Cache 复用策略。
19. 19\. 在多语言评估中，若 tokenizer 未覆盖某些语言字符（如 Tamil），分析其导致的 OOV token 膨胀问题，并推导 subword fallback 机制对 perplexity 计算的偏差影响。
20. 20\. 当 Harness 与 Triton kernel 集成以加速自定义 metric（如 exact match with normalization）时，推导其在 GPU 上的 block/grid 配置策略，并分析 shared memory 对字符串比较的加速上限。

算法工程师 · 目录

继续滑动看下一个

乔木mq

向上滑动看下一个