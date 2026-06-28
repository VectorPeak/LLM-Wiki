---
title: "微信_汐的小世界_分布式训练：DeepSpeed 与 ZeRO_公众号文章剪藏_2026-06-21_1-3"
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

## 0x01. 二十二：分布式训练：DeepSpeed 与 ZeRO
> 发布日期：2026-06-21  
> 原文链接：[二十二：分布式训练：DeepSpeed 与 ZeRO](https://mp.weixin.qq.com/s/4rd4_UlFpprXkvW79Ou5MQ)

### 1. 学习定位
第 21 天学习了 DDP。DDP 每张卡保存完整参数、梯度和优化器状态，因此显存冗余大。DeepSpeed 的核心价值之一是 ZeRO(Zero Redundancy Optimizer)，通过分片优化器状态、梯度和参数，让多卡共同承载更大的模型。

本日知识链路：

### 2. 大模型训练的显存组成
训练一个模型时，显存通常包括：

- 参数 parameters。
- 梯度 gradients。
- 优化器状态 optimizer states，Adam 通常包含 momentum 和 variance。
- 激活 activations。
- 临时 buffer、通信 buffer、fragmentation。
以 Adam + FP16/BF16 训练为例，优化器状态可能比参数本身更占显存。DDP 每张卡都保存完整副本，因此模型越大，冗余越严重。

### 3. ZeRO 的核心思想
ZeRO 的目标是消除数据并行中的冗余状态。DDP 中每张卡保存完整：

- 模型参数。
- 梯度。
- 优化器状态。

问题在于：所有卡存了一模一样的完整数据，显存是高度冗余的，卡数越多、模型越大，这种浪费就越明显。

ZeRO 把这些状态按 data parallel ranks 分片，让每张卡只保存其中一部分。

核心直觉：

接下来是 ZeRO 的三级分片，逐级解放显卡。

### 4. ZeRO Stage 1---只分片优化器状态
ZeRO Stage 1 分片 optimizer states。

适合优化器状态显存占比高，但模型参数还能放下的场景。

- 前向、反向和标准 DDP 一致，参数、梯度全程每张卡都持有完整副本。
- 反向得到全局梯度后，通过 reduce-scatter 将梯度分片分发到对应 rank。
- 各 rank 仅用本地分片的 Adam 动量 m、v，完成局部参数更新。
- 改动相对小。
- 显存节省明显。
- 通信复杂度相对低。

### 5. ZeRO Stage 2---分片优化器状态+梯度
ZeRO Stage 2 在 Stage 1 基础上进一步分片 gradients。

相比 Stage 1，进一步减少梯度显存。训练时需要 reduce-scatter 等通信，把梯度分片分发给对应 rank。

- 前向传播同 DDP，参数全局复制。
- 反向计算梯度过程中，执行 reduce-scatter，梯度直接按分片归属分发到对应 rank，不再全局保留完整梯度。
- 各 rank 结合本地梯度分片 + 优化器状态分片，完成参数更新。
Stage 2 常用于中大型模型训练，显存效率和通信成本之间较平衡。

### 6. ZeRO Stage 3---分片优化器状态+梯度+模型参数(全分片)
ZeRO Stage 3 进一步分片 parameters。

每张卡只常驻一部分参数。forward/backward 需要临时 all-gather 当前层参数，用完后释放。

- 前向计算某一层时，执行 all-gather 从其他 rank 拉取当前层完整参数。
- 计算完成后，立即释放临时聚合的参数，只保留本地分片。
- 反向传播同理，梯度经 reduce-scatter 归位到对应 rank。
- 各 rank 仅更新自己管辖的参数、梯度、优化器状态分片。
Stage 3 显存最省，但通信最复杂。它适合单卡无法保存完整模型参数或 optimizer states 的超大模型。

### 7. ZeRO 与 DDP/FSDP 对比
ZeRO：

FSDP：

实际选型要看框架生态、模型结构、checkpoint、集成成本和团队熟悉度。

### 8. Offload
Offload = 把 GPU 常驻的训练状态，转移到 CPU 内存 / NVMe 硬盘存放，本质是用低速大容量存储，置换高速 GPU 显存。

DeepSpeed 支持把部分状态 offload 到 CPU 或 NVMe：

- 显著降低 GPU 显存。
- 可训练更大模型。
- 带宽瓶颈：PCIe/NVMe 带宽远低于 GPU 显存。
- 训练速度可能明显下降。
- 需要调 prefetch、pin memory、buffer 等参数。

Offload 是“用更慢的存储换更大容量”。

### 9. ZeRO-Infinity 与 ZeRO-Offload
ZeRO-Offload 主要把 optimizer states 和计算转移到 CPU，降低 GPU 显存压力。

ZeRO-Infinity 扩展到 NVMe offload，面向更大规模模型，利用 CPU/NVMe 层级存储承载模型状态。利用「GPU 显存 → CPU 内存 → NVMe 硬盘」三级存储架构，彻底突破硬件显存 / 内存上限。

面试中重点不是背所有参数，而是说明：

### 10. Activation Checkpointing 激活重计算
激活显存随 batch size、sequence length、hidden size、layers 增长。activation checkpointing 的思想是：

DeepSpeed 支持 activation checkpointing，可与 ZeRO 组合。

- backward 计算量增加。
- 训练时间变长。
- 显著降低长序列和大模型训练显存。

### 11. DeepSpeed 配置文件
DeepSpeed 通常通过 JSON 配置：

常见字段：

/bf16。
配置错误是 DeepSpeed 使用中最常见问题之一。

### 12. Batch 语义
DeepSpeed 中有三个容易混淆的 batch 概念：

如果配置不一致，DeepSpeed 可能报错或自动推断，建议明确计算。

### 13. DeepSpeed 初始化
典型代码：

DeepSpeed 接管 backward、optimizer step、梯度累积、ZeRO 通信和状态管理。

使用 Hugging Face Trainer 或 Accelerate 时，DeepSpeed 可通过配置文件集成，用户不一定直接调用deepspeed.initialize。

### 14. Mixed Precision
DeepSpeed 支持 FP16、BF16 和部分低精度训练配置。

FP16：

BF16：

大模型训练中，BF16 通常是更稳的默认选择。使用 FP16 时要关注 loss scale、overflow 次数和梯度异常。

### 15. DeepSpeed Checkpoint
ZeRO 下 checkpoint 不再只是普通state_dict。尤其 ZeRO-3 中参数被分片保存。

常见操作：

需要注意：

- 每个 rank 可能保存自己的 shard。
- 从 ZeRO checkpoint 合并成普通 FP32 state_dict 需要专门工具。
- 保存/加载时 world size 变化可能涉及转换。
- Hugging Face 格式导出要确认是否已 gather 完整权重。

### 16. DeepSpeed 与 Hugging Face
Hugging Face Trainer 可通过参数启用 DeepSpeed：

Accelerate 也支持 DeepSpeed plugin。

常见组合：

- SFT + DeepSpeed ZeRO-2/3。
- LoRA/QLoRA + DeepSpeed。
- RLHF/PPO + DeepSpeed。
- 多机训练 + DeepSpeed launcher。

需要注意 PEFT、量化、ZeRO-3 参数 gather 和保存之间的交互。

### 17. 性能与通信
ZeRO 节省显存，但通信更多。

常见通信：

- all-gather 参数。
- reduce-scatter 梯度。
- all-reduce 部分统计。
- offload prefetch/evict。

性能优化方向：

- 合理选择 ZeRO stage。
- 增大 micro batch 或 gradient accumulation。
- 减少 offload。
- 使用 BF16。
- 开启 activation checkpointing。
- 调整 bucket size。
- 避免频繁 checkpoint。

### 18. 常见 OOM 排查
OOM 时先判断显存来源：

- 参数太大：考虑 ZeRO-3/FSDP。
- 优化器状态太大：ZeRO-1/2。
- 梯度太大：ZeRO-2。
- activation 太大：activation checkpointing、减 sequence length、减 micro batch。
- 临时 buffer：减 bucket size、检查 kernel。

常见策略：

### 19. 常见误区
误区一：DeepSpeed 一定比 DDP 更快。 DeepSpeed 主要优势是显存和大模型能力。ZeRO stage 越高通信越多，不一定更快。

误区二：ZeRO-3 永远最好。 ZeRO-3 最省显存但通信重。如果模型 DDP/ZeRO-2 能放下，ZeRO-3 可能更慢。

误区三：Offload 是免费显存扩展。 Offload 会消耗 CPU/NVMe 带宽，速度可能明显下降。

误区四：DeepSpeed batch 配置可以随便写。 micro batch、accumulation、world size、global batch 必须一致。

误区五：ZeRO checkpoint 就是普通 PyTorch checkpoint。 ZeRO checkpoint 可能是分片格式，导出和恢复要按 DeepSpeed 规则处理。

### 20. 核心总结
第 22 天需要掌握的最小闭环：

### 21. 参考资料
- DeepSpeed 官方文档：https://www.deepspeed.ai/
- DeepSpeed ZeRO 文档：https://www.deepspeed.ai/tutorials/zero/
- ZeRO 论文：https://arxiv.org/abs/1910.02054
- ZeRO-Offload 论文：https://arxiv.org/abs/2101.06840
- ZeRO-Infinity 论文：https://arxiv.org/abs/2104.07857
- DeepSpeed 实战视频：https://www.bilibili.com/video/BV1hb421E7WY/
- DeepSpeed 详解：https://blog.csdn.net/zwqjoy/article/details/130732601
- 分布式训练方法汇总：https://zhuanlan.zhihu.com/p/598714869

## 0x02. 二十二：分布式训练：DeepSpeed 与 ZeRO自测题
> 发布日期：2026-06-12  
> 原文链接：[二十二：分布式训练：DeepSpeed 与 ZeRO自测题](https://mp.weixin.qq.com/s/ESPZnVyC9rZbAcx4-ml-XA)

对于本节内容，有条件的还是自己实际试一下会更好理解。

### 覆盖范围
 DeepSpeed 基础定位

 ZeRO Stage 1/2/3

 optimizer states、gradients、parameters 分片

 offload、activation checkpointing、mixed precision

 DeepSpeed JSON 配置和 batch 语义

 Hugging Face 集成、checkpoint、OOM 和性能排错

 DDP、FSDP、ZeRO 对比

### 一、DeepSpeed 与显存基础
 DeepSpeed 主要解决什么问题？

 大模型训练显存通常由哪些部分组成？

 Adam 优化器状态为什么显存开销大？

 DDP 在显存上有什么冗余？

 ZeRO 的核心目标是什么？

 ZeRO 用什么换取显存节省？

 DeepSpeed 是否只用于训练？它还可以支持哪些场景？

 DeepSpeed 和 PyTorch DDP 的关系是什么？

### 二、ZeRO Stage 1/2/3
 ZeRO Stage 1 分片什么？

 ZeRO Stage 1 中参数和梯度是否复制？

 ZeRO Stage 2 在 Stage 1 基础上增加了什么？

 ZeRO Stage 2 为什么能进一步省显存？

 ZeRO Stage 3 分片什么？

 ZeRO Stage 3 为什么最省显存？

 ZeRO Stage 3 为什么通信开销更高？

 Stage 1、2、3 分别适合什么场景？

 为什么 ZeRO-3 不一定比 ZeRO-2 更快？

 ZeRO 和 FSDP 有什么相似点和区别？

### 三、Offload 与 Activation Checkpointing
 什么是 optimizer offload？

 什么是 parameter offload？

 CPU offload 和 NVMe offload 的主要代价是什么？

 ZeRO-Offload 主要解决什么问题？

 ZeRO-Infinity 的核心思路是什么？

 什么是 activation checkpointing？

 activation checkpointing 用什么换显存？

 长序列训练为什么特别需要 activation checkpointing？

 offload 和 activation checkpointing 可以一起使用吗？

 如果开启 offload 后训练变慢，应该如何解释？

### 四、DeepSpeed 配置
 DeepSpeed 通常用什么形式配置训练？

- train_micro_batch_size_per_gpu
 表示什么？

- gradient_accumulation_steps
 表示什么？

- train_batch_size
 与 micro batch、accumulation、world size 的关系是什么？

- zero_optimization.stage
 控制什么？

 DeepSpeed 中 fp16 和 bf16 配置有什么区别？

- gradient_clipping
 在 DeepSpeed 中有什么作用？

 optimizer 和 scheduler 可以由 DeepSpeed 配置吗？

 配置中 batch size 不一致会导致什么问题？

 为什么 DeepSpeed 配置文件是排错重点？

### 五、DeepSpeed 训练流程与集成
- deepspeed.initialize
 返回哪些对象？

 DeepSpeed 中为什么通常调用 model_engine.backward(loss)？

 DeepSpeed 中为什么调用 model_engine.step() 而不是普通 optimizer.step？

 DeepSpeed 如何接管 gradient accumulation？

 Hugging Face Trainer 如何启用 DeepSpeed？

 Accelerate 如何与 DeepSpeed 集成？

 LoRA/QLoRA 和 DeepSpeed 组合时要注意什么？

 DeepSpeed 与 RLHF/PPO 组合时有什么额外复杂性？

### 六、Checkpoint 与恢复
 DeepSpeed checkpoint 和普通 PyTorch checkpoint 有什么区别？

 ZeRO-3 checkpoint 为什么通常是分片的？

- save_checkpoint
 和 load_checkpoint 的作用是什么？

 从 ZeRO checkpoint 导出普通 FP32 权重可能需要什么？

 断点恢复时除了模型还要恢复哪些状态？

 world size 改变后恢复 checkpoint 可能有什么问题？

 为什么保存 checkpoint 会影响训练性能？

 Hugging Face 格式保存和 ZeRO 分片保存有什么区别？

### 七、性能与 OOM 排错
 DeepSpeed OOM 时应如何判断显存主要花在哪里？

 参数太大导致 OOM 应优先考虑什么？

 activation 太大导致 OOM 应优先考虑什么？

 优化器状态太大导致 OOM 应优先考虑什么？

 ZeRO stage 提高后仍 OOM，可能还要做什么？

 DeepSpeed 训练变慢可能有哪些原因？

 如何判断 offload 是否成为瓶颈？

 bucket size 影响什么？

 为什么 micro batch 太小会影响吞吐？

 为什么通信和计算重叠很重要？

### 八、综合设计
 请设计一个 ZeRO-2 的 SFT 训练配置要点。

 请设计一个 ZeRO-3 + offload 的超大模型训练方案。

 如何从 DDP 迁移到 DeepSpeed？

 如何选择 DDP、FSDP、DeepSpeed ZeRO-2、ZeRO-3？

 DeepSpeed 训练中出现 loss scale overflow 应如何排查？

 请完整比较 DDP、DeepSpeed ZeRO-1/2/3、Offload、Activation Checkpointing 的目标、显存收益、通信/计算代价和适用场景。

## 0x03. 二十二：分布式训练：DeepSpeed 与 ZeRO自测题答案
> 发布日期：2026-06-12  
> 原文链接：[二十二：分布式训练：DeepSpeed 与 ZeRO自测题答案](https://mp.weixin.qq.com/s/K3UQ4TLACIn-SnnP2MI7oQ)

### 参考资料
 DeepSpeed 官方文档：https://www.deepspeed.ai/

 DeepSpeed ZeRO 文档：https://www.deepspeed.ai/tutorials/zero/

 ZeRO 论文：https://arxiv.org/abs/1910.02054

 ZeRO-Offload 论文：https://arxiv.org/abs/2101.06840

 ZeRO-Infinity 论文：https://arxiv.org/abs/2104.07857

 DeepSpeed 实战视频：https://www.bilibili.com/video/BV1hb421E7WY/

 DeepSpeed 详解：https://blog.csdn.net/zwqjoy/article/details/130732601

 分布式训练方法汇总：https://zhuanlan.zhihu.com/p/598714869

### 评分标准
 合格：能说清 DeepSpeed、ZeRO Stage 1/2/3、batch 关系和 offload 基本概念。

 良好：能解释 activation checkpointing、配置字段、checkpoint、Hugging Face 集成和 OOM 排错。

 优秀：能结合模型规模、显存、通信、吞吐和工程复杂度选择 DDP/FSDP/ZeRO 方案。

### 一、DeepSpeed 与显存基础
#### 1. DeepSpeed 主要解决什么问题？
 DeepSpeed 主要解决大模型训练的显存、吞吐和扩展问题，尤其通过 ZeRO 消除数据并行冗余。

#### 2. 大模型训练显存通常由哪些部分组成？
 参数、梯度、优化器状态、激活、通信 buffer、临时 tensor 和碎片。

#### 3. Adam 优化器状态为什么显存开销大？
 Adam 为每个参数保存一阶和二阶动量，常常还保存 FP32 master weights，因此状态可能是参数显存的数倍。

#### 4. DDP 在显存上有什么冗余？
 每张卡都有完整参数、梯度和优化器状态。

#### 5. ZeRO 的核心目标是什么？
 把数据并行中重复保存的训练状态分片，减少每张 GPU 的显存占用。

#### 6. ZeRO 用什么换取显存节省？
 用更多通信、参数 gather、梯度 reduce-scatter 和状态管理复杂度换显存。

#### 7. DeepSpeed 是否只用于训练？它还可以支持哪些场景？
 不只训练，也支持推理优化、模型并行、offload 和大模型部署相关能力。

#### 8. DeepSpeed 和 PyTorch DDP 的关系是什么？
 DeepSpeed 可构建在数据并行基础上，但提供 ZeRO、offload、checkpoint 等更高级能力。

### 二、ZeRO Stage 1/2/3
#### 9. ZeRO Stage 1 分片什么？
 分片 optimizer states。

#### 10. ZeRO Stage 1 中参数和梯度是否复制？
 是。参数和梯度仍复制，optimizer states 分片。

#### 11. ZeRO Stage 2 在 Stage 1 基础上增加了什么？
 进一步分片 gradients。

#### 12. ZeRO Stage 2 为什么能进一步省显存？
 每张卡只保存部分梯度，而不是完整梯度副本。

#### 13. ZeRO Stage 3 分片什么？
 参数、梯度和优化器状态都分片。

#### 14. ZeRO Stage 3 为什么最省显存？
 因为每张卡不再常驻完整参数，三类主要训练状态都按数据并行组分片。

#### 15. ZeRO Stage 3 为什么通信开销更高？
 forward/backward 需要频繁 all-gather 当前层参数，用完再释放，通信更复杂。

#### 16. Stage 1、2、3 分别适合什么场景？
 Stage 1 适合 optimizer states 成为瓶颈；Stage 2 适合梯度也占显存；Stage 3 适合参数本身也无法完整复制。

#### 17. 为什么 ZeRO-3 不一定比 ZeRO-2 更快？
 ZeRO-3 更省显存但参数 all-gather 更频繁，通信开销可能超过收益。

#### 18. ZeRO 和 FSDP 有什么相似点和区别？
 都分片训练状态。FSDP 是 PyTorch 原生方案，ZeRO 是 DeepSpeed 体系，配置、checkpoint 和生态不同。

### 三、Offload 与 Activation Checkpointing
#### 19. 什么是 optimizer offload？
 把 optimizer states 放到 CPU 或 NVMe，减少 GPU 显存。

#### 20. 什么是 parameter offload？
 把参数分片也放到 CPU/NVMe，需要时再预取到 GPU。

#### 21. CPU offload 和 NVMe offload 的主要代价是什么？
 带宽和延迟远低于 GPU 显存，训练速度可能明显下降。

#### 22. ZeRO-Offload 主要解决什么问题？
 把优化器状态和部分计算卸载到 CPU，使较少 GPU 显存能训练更大模型。

#### 23. ZeRO-Infinity 的核心思路是什么？
 利用 GPU、CPU、NVMe 分层存储承载超大模型状态。

#### 24. 什么是 activation checkpointing？
 forward 不保存所有激活，backward 重新计算部分激活，以计算换显存。

#### 25. activation checkpointing 用什么换显存？
 用额外 forward 重计算开销换显存。

#### 26. 长序列训练为什么特别需要 activation checkpointing？
 激活显存随序列长度显著增长，长上下文训练中 activation 往往成为主要显存来源。

#### 27. offload 和 activation checkpointing 可以一起使用吗？
 可以。一个减少状态显存，一个减少激活显存。

#### 28. 如果开启 offload 后训练变慢，应该如何解释？
 数据在 GPU、CPU、NVMe 间移动，PCIe/NVMe IO 成为瓶颈。

### 四、DeepSpeed 配置
#### 29. DeepSpeed 通常用什么形式配置训练？
 通常用 JSON 配置文件。

#### 30. train_micro_batch_size_per_gpu 表示什么？
 每张 GPU 每次 forward/backward 的 micro batch 大小。

#### 31. gradient_accumulation_steps 表示什么？
 累积多少个 micro batch 后执行一次 optimizer step。

#### 32. train_batch_size 与 micro batch、accumulation、world size 的关系是什么？
```text
train_batch_size = micro_batch_per_gpu *grad_accum_steps* data_parallel_world_size
```
#### 33. zero_optimization.stage 控制什么？
 控制 ZeRO 使用 Stage 0/1/2/3 中哪一级状态分片。

#### 34. DeepSpeed 中 fp16 和 bf16 配置有什么区别？
 FP16 通常需要 loss scaling；BF16 动态范围大，稳定性更好但需要硬件支持。

#### 35. gradient_clipping 在 DeepSpeed 中有什么作用？
 限制梯度范数，避免梯度爆炸和混合精度不稳定。

#### 36. optimizer 和 scheduler 可以由 DeepSpeed 配置吗？
 可以。DeepSpeed config 可定义 optimizer、scheduler 和相关参数。

#### 37. 配置中 batch size 不一致会导致什么问题？
 DeepSpeed 可能报错、自动推断错误，或实际 global batch 与预期不一致。

#### 38. 为什么 DeepSpeed 配置文件是排错重点？
 ZeRO stage、batch、dtype、offload、optimizer、checkpoint 等关键行为都由配置控制。

### 五、DeepSpeed 训练流程与集成
#### 39. deepspeed.initialize 返回哪些对象？
 常返回 model_engine、optimizer、training dataloader、scheduler 等。

#### 40. DeepSpeed 中为什么通常调用 model_engine.backward(loss)？
 DeepSpeed 需要接管反向、梯度缩放、ZeRO 通信和梯度累积。

#### 41. DeepSpeed 中为什么调用 model_engine.step() 而不是普通 optimizer.step？
 model_engine.step() 会处理梯度累积、优化器更新、ZeRO 状态同步和 scheduler。

#### 42. DeepSpeed 如何接管 gradient accumulation？
 根据配置自动累积 micro steps，并在合适时机 step。

#### 43. Hugging Face Trainer 如何启用 DeepSpeed？
 训练参数中传入 --deepspeed ds_config.json 或 TrainingArguments 的 deepspeed 字段。

#### 44. Accelerate 如何与 DeepSpeed 集成？
 通过 accelerate config 选择 DeepSpeed plugin，并指定 ZeRO stage 和配置。

#### 45. LoRA/QLoRA 和 DeepSpeed 组合时要注意什么？
 注意可训练参数范围、ZeRO-3 gather、量化模型兼容、保存 adapter 和 reference 权重。

#### 46. DeepSpeed 与 RLHF/PPO 组合时有什么额外复杂性？
 policy、reference、reward、value 多模型并存，生成和训练阶段显存不同，ZeRO 与 rollout engine 也要协调。

### 六、Checkpoint 与恢复
#### 47. DeepSpeed checkpoint 和普通 PyTorch checkpoint 有什么区别？
 DeepSpeed checkpoint 可能保存分片参数、优化器状态和 ZeRO 元数据，不一定是单个完整 state_dict。

#### 48. ZeRO-3 checkpoint 为什么通常是分片的？
 因为参数本身在各 rank 上分片存储。

#### 49. save_checkpoint 和 load_checkpoint 的作用是什么？
 按 DeepSpeed 规则保存和恢复模型、优化器、scheduler、ZeRO 状态等。

#### 50. 从 ZeRO checkpoint 导出普通 FP32 权重可能需要什么？
 需要 DeepSpeed 提供的合并脚本或工具把分片权重 gather 成完整 state_dict。

#### 51. 断点恢复时除了模型还要恢复哪些状态？
 优化器、scheduler、global step、epoch、随机数、scaler、ZeRO 分片状态。

#### 52. world size 改变后恢复 checkpoint 可能有什么问题？
 分片布局变化，可能需要重新分片或转换 checkpoint。

#### 53. 为什么保存 checkpoint 会影响训练性能？
 大模型 checkpoint 体积巨大，IO、同步和 gather 可能阻塞训练。

#### 54. Hugging Face 格式保存和 ZeRO 分片保存有什么区别？
 HF 格式通常是可直接加载的完整或 safetensors 权重；ZeRO 分片保存包含 rank-specific shards。

### 七、性能与 OOM 排错
#### 55. DeepSpeed OOM 时应如何判断显存主要花在哪里？
 区分参数、梯度、优化器状态、activation 和临时 buffer，可通过 stage 变化、batch/seq 调整和 profiler 判断。

#### 56. 参数太大导致 OOM 应优先考虑什么？
 ZeRO-3、FSDP、tensor parallel 或 parameter offload。

#### 57. activation 太大导致 OOM 应优先考虑什么？
 activation checkpointing、减小 micro batch、缩短 sequence length、使用更省显存 attention。

#### 58. 优化器状态太大导致 OOM 应优先考虑什么？
 ZeRO-1/2、optimizer offload、8-bit optimizer 或减少可训练参数。

#### 59. ZeRO stage 提高后仍 OOM，可能还要做什么？
 开启 activation checkpointing、offload、减 batch/sequence、用 LoRA/QLoRA 或模型并行。

#### 60. DeepSpeed 训练变慢可能有哪些原因？
 ZeRO stage 过高、offload IO 慢、通信瓶颈、micro batch 太小、checkpoint 频繁、dataloader 慢。

#### 61. 如何判断 offload 是否成为瓶颈？
 观察 CPU/NVMe IO、PCIe 带宽、GPU 利用率下降和 step time 增加。

#### 62. bucket size 影响什么？
 影响通信粒度、内存 buffer 和通信计算重叠效率。

#### 63. 为什么 micro batch 太小会影响吞吐？
 GPU 计算不饱和，通信和调度开销占比变大。

#### 64. 为什么通信和计算重叠很重要？
 可以隐藏部分通信时间，提高整体训练吞吐。

### 八、综合设计
#### 65. 请设计一个 ZeRO-2 的 SFT 训练配置要点。
 使用 bf16、ZeRO stage 2、合理 micro batch 和 accumulation、gradient clipping、activation checkpointing 视情况开启，保存 DeepSpeed checkpoint。

#### 66. 请设计一个 ZeRO-3 + offload 的超大模型训练方案。
 ZeRO stage 3 分片参数/梯度/优化器，optimizer/parameter offload 到 CPU 或 NVMe，开启 activation checkpointing，使用 bf16，严格控制 micro batch 和 checkpoint 频率。

#### 67. 如何从 DDP 迁移到 DeepSpeed？
 引入 DeepSpeed config，替换初始化和 backward/step 调用，确认 batch 语义、checkpoint、AMP、optimizer 和 launch 方式。

#### 68. 如何选择 DDP、FSDP、DeepSpeed ZeRO-2、ZeRO-3？
 模型能单卡放下且追求简单速度选 DDP；需要原生 PyTorch 分片选 FSDP；想用 DeepSpeed 生态和 ZeRO 选 ZeRO；显存压力一般选 ZeRO-2，参数也放不下选 ZeRO-3。

#### 69. DeepSpeed 训练中出现 loss scale overflow 应如何排查？
 降低学习率、检查异常数据和 loss、启用 gradient clipping、改用 BF16、查看 FP16 loss scale 配置。

#### 70. 请完整比较 DDP、DeepSpeed ZeRO-1/2/3、Offload、Activation Checkpointing 的目标、显存收益、通信/计算代价和适用场景。
 DDP 复制完整状态，简单快速但显存冗余。ZeRO-1 分 optimizer states，低成本省显存。ZeRO-2 再分 gradients，平衡常用。ZeRO-3 再分 parameters，最省显存但通信重。Offload 把状态放 CPU/NVMe，突破显存但速度下降。Activation checkpointing 不保存部分激活，靠重算省显存，适合长序列和大模型。
