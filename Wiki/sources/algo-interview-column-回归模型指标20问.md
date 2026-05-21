---
type: source
title: "算法面试专栏：回归模型指标20问"
created: 2026-05-19
updated: 2026-05-19
status: developing
tags:
  - source
  - wechat
  - algorithm
  - interview
related:
  - "[[算法与编程基础]]"
sources: []
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/算法面试专栏：回归模型指标20问.md"
source_type: wechat
author: ""
date_published: ""
url: ""
confidence: medium
key_claims:
  - "文章围绕“算法面试专栏：回归模型指标20问”整理概念、面试问题或工程经验。"
  - "内容具有面试题/八股整理属性，写入 Wiki 时应区分可验证事实、答题话术和个人经验。"
  - "其中涉及的技术结论后续可拆分到 concepts、methods、questions 或 comparisons 页面。"
---

# 算法面试专栏：回归模型指标20问

## 摘要

1. 1\. 在多输出回归任务中，若使用均方误差（MSE）作为损失函数，推导其关于模型参数 的梯度表达式，并分析当输出维度 极大时（如 ），该梯度计算在 GPU 上的显存瓶颈主要出现在哪一步？如何通过 Jacobian 矩阵的稀疏性或低秩近似进行优化？ 2. 2\. 考虑 Huber 损失函数 ，请推导其关于 的二阶导数，并讨论该性质对牛顿法或拟牛顿法（如 LBFGS）收敛速度的影响。 3. 3\. 在分布式训练中，若采用 ZeRO3 对回归模型的 optimizer states 进行分片，当计算验证集上的 MA

## 关键断言

- 文章围绕“算法面试专栏：回归模型指标20问”整理概念、面试问题或工程经验。
- 内容具有面试题/八股整理属性，写入 Wiki 时应区分可验证事实、答题话术和个人经验。
- 其中涉及的技术结论后续可拆分到 concepts、methods、questions 或 comparisons 页面。

## 涉及实体

- 待抽取

## 涉及概念

- [[算法与编程基础]]

## 可复用方法

- 待进一步摄取时抽取

## 局限与不确定性

- 微信文章可能包含面试话术、经验判断或二手整理；涉及当前模型、项目状态、版本、性能数据时需要二次核对。

## 可继续追问

- 这篇资料应拆到哪些概念、方法、问题或对比页面？
