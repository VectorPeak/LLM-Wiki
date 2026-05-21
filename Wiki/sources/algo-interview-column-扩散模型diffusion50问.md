---
type: source
title: "算法面试专栏：扩散模型Diffusion50问"
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
source_path: "RAW/09.Wechat/算法面试专栏：扩散模型Diffusion50问.md"
source_type: wechat
author: ""
date_published: ""
url: ""
confidence: medium
key_claims:
  - "文章围绕“算法面试专栏：扩散模型Diffusion50问”整理概念、面试问题或工程经验。"
  - "内容具有面试题/八股整理属性，写入 Wiki 时应区分可验证事实、答题话术和个人经验。"
  - "其中涉及的技术结论后续可拆分到 concepts、methods、questions 或 comparisons 页面。"
---

# 算法面试专栏：扩散模型Diffusion50问

## 摘要

1. 1\. 在基于随机微分方程（SDE）的扩散模型框架下，推导反向SDE 的离散化形式，并解释其与DDPM中 采样公式的等价性。 2. 2\. 请从变分推断的角度出发，严格推导DDPM的证据下界（ELBO），并说明其如何简化为去噪得分匹配（Denoising Score Matching）目标 。 3. 3\. 在训练基于ODE的扩散模型（如Flow Matching）时，推导其损失函数对神经网络参数 的梯度 ，并分析该梯度在不同时间步 下的方差特性。 4. 4\. 对比分析DDIM和DPMSolver在加速采样

## 关键断言

- 文章围绕“算法面试专栏：扩散模型Diffusion50问”整理概念、面试问题或工程经验。
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
