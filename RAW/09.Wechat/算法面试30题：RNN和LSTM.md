---
title: "算法面试30题：RNN和LSTM"
source: "https://mp.weixin.qq.com/s/H-H4-03tpnac-_2lITunJg"
author:
  - "[[乔木mq]]"
published:
created: 2026-05-19
description: "1. 请简单解释什么是循环神经网络（RNN）？它主要用于处理什么类型的数据？"
tags:
  - "clippings"
---
乔木mq *2026年3月12日 22:58*

1. 1\. 请简单解释什么是循环神经网络（RNN）？它主要用于处理什么类型的数据？
2. 2\. RNN 与全连接神经网络（FCN）或卷积神经网络（CNN）最大的区别是什么？
3. 3\. 什么是“隐藏状态”（Hidden State）？它在 RNN 中起什么作用？
4. 4\. 为什么 RNN 被称为具有“记忆”能力的网络？
5. 5\. 请简述 RNN 在时间步（Time Step）上的展开过程。
6. 6\. 什么是“梯度消失”（Vanishing Gradient）问题？它对训练长序列的 RNN 有什么影响？
7. 7\. 什么是“梯度爆炸”（Exploding Gradient）问题？通常如何解决？
8. 8\. 什么是长短期记忆网络（LSTM）？它是为了解决 RNN 的什么问题而设计的？
9. 9\. LSTM 细胞中包含哪三个主要的“门”（Gate）结构？
10. 10\. 请简述“遗忘门”（Forget Gate）的作用。
11. 11\. 请简述“输入门”（Input Gate）的作用。
12. 12\. 请简述“输出门”（Output Gate）的作用。
13. 13\. 什么是“细胞状态”（Cell State）？它与隐藏状态有什么区别？
14. 14\. 为什么 LSTM 能够有效缓解梯度消失问题？
15. 15\. 什么是 GRU（Gated Recurrent Unit）？它与 LSTM 的主要区别是什么？
16. 16\. 在自然语言处理（NLP）任务中，RNN/LSTM 通常用于哪些具体应用？
17. 17\. 什么是“双向 RNN”（Bi-directional RNN）？它有什么优势？
18. 18\. 什么是“多层 RNN”（Stacked RNN）？增加层数会带来什么好处和挑战？
19. 19\. 在训练 RNN/LSTM 时，常用的损失函数是什么？
20. 20\. 什么是“截断反向传播”（Truncated BPTT）？为什么要使用它？
21. 21\. RNN/LSTM 对输入序列的长度有固定要求吗？如何处理变长序列？
22. 22\. 什么是“填充”（Padding）和“掩码”（Masking）？它们在处理变长序列时起什么作用？
23. 23\. 在 PyTorch 或 TensorFlow 中，RNN 层输出的形状通常是怎样的？
24. 24\. 相比于 Transformer 模型，RNN/LSTM 的主要缺点是什么（关于并行计算）？
25. 25\. 什么是“序列到序列”（Seq2Seq）模型？它通常由什么组成？
26. 26\. 在 Seq2Seq 模型中，“编码器”（Encoder）和“解码器”（Decoder）分别做什么？
27. 27\. 什么是“教师强制”（Teacher Forcing）？它在训练 RNN 解码器时如何使用？
28. 28\. 什么是“暴露偏差”（Exposure Bias）？它与教师强制有什么关系？
29. 29\. 如果数据集中存在非常长的依赖关系，应该优先选择 vanilla RNN 还是 LSTM？
30. 30\. 请列举一个不适合使用 RNN/LSTM 而更适合使用 CNN 或 Transformer 的场景。

算法工程师 · 目录

继续滑动看下一个

乔木mq

向上滑动看下一个