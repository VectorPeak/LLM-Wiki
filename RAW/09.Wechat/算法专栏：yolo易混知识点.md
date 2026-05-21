---
title: "算法专栏：yolo易混知识点"
source: "https://mp.weixin.qq.com/s/pbRZsUW64Q-80N2D9mBfeA"
author:
  - "[[乔木mq]]"
published:
created: 2026-05-19
description: "YOLO 系列中存在若干容易混淆的知识点，主要体现在以下方面。正负样本的定义方式在不同版本中存在差异。"
tags:
  - "clippings"
---
乔木mq *2026年4月26日 07:21*

YOLO 系列中存在若干容易混淆的知识点，主要体现在以下方面。

正负样本的定义方式在不同版本中存在差异。YOLOv3 采用固定 anchor 与真实标注框的 IoU 阈值来判断正负样本；YOLOv5 则引入了跨网格匹配策略，一个真实标注框可能分配给多个 anchor（甚至不同尺度的检测头），从而显著增加正样本数量。

Anchor 的处理方式也有所不同。YOLOv3 和 YOLOv4 需要预先通过 k-means 聚类在数据集上得到 anchor；YOLOv5 则在训练开始时自动计算最优 anchor（即自适应 anchor），同时也可以关闭该功能使用默认值。

损失函数方面存在差异。YOLOv3 使用原始的 IoU 损失；YOLOv4 引入 CIoU 损失以提升定位精度；YOLOv5 默认使用 CIoU，同时对分类损失和置信度损失做了加权调整。

非极大值抑制的类型不同。YOLOv3 使用标准 NMS；YOLOv4 和 YOLOv5 推荐使用 DIoU-NMS，在抑制重叠框时考虑中心点距离，效果更优。

输入图像的缩放策略也有区别。YOLOv5 默认采用自适应填充（letterbox）以保持宽高比，而部分实现或旧版本可能直接拉伸图像，影响检测效果。

Backbone 结构的演进较为明显。YOLOv3 使用 Darknet-53；YOLOv4 升级为 CSPDarknet53 并加入 Mish 激活函数；YOLOv5 则使用 Focus 模块（早期版本）或简化卷积加 SiLU 激活函数，且整体基于 PyTorch 实现，属于非官方论文版本。

多尺度训练与推理方面，虽然各版本均支持多尺度，但 YOLOv5 的实现更为灵活，默认在训练中动态调整输入尺寸，而 YOLOv3 和 YOLOv4 多为固定尺寸或手动切换。

是否开源及官方性也是一个易混淆点。YOLOv1 至 YOLOv4 均有正式论文，由原作者或社区权威维护；YOLOv5 由 Ultralytics 开发，没有对应的学术论文，属于工程优化版本，常被误认为是官方第五代。

检测头结构有所变化。YOLOv3 使用独立的检测头；YOLOv4 和 YOLOv5 引入了 PANet 或改进的 FPN 与 PAN 融合结构，增强了多尺度特征交互。

数据增强策略方面，YOLOv4 首次引入 Mosaic 增强；YOLOv5 默认启用 Mosaic 和 MixUp，并在最后若干轮训练中关闭以稳定收敛，初学者容易忽略该策略在训练阶段的影响。

算法工程师 · 目录

继续滑动看下一个

乔木mq

向上滑动看下一个