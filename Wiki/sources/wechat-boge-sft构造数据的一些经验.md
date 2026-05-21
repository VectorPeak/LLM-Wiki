---
type: source
title: "SFT构造数据的一些经验"
created: 2026-05-19
updated: 2026-05-19
status: developing
tags:
  - source
  - wechat
  - training
related:
  - "[[大模型预训练与微调]]"
sources: []
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/Wechat_波哥聊大模型_SFT构造数据的一些经验.md"
source_type: wechat
author: "波哥聊大模型"
date_published: ""
url: ""
confidence: medium
key_claims:
  - "文章围绕“SFT构造数据的一些经验”组织问题和解释，主要小节包括：〇、SFT 的定位变了，先把这事儿说清楚、一、Long-CoT：绕不过去的话题、蒸馏来的比手写的好得多、但也不能一味追求长、Long-CoT SFT 是 RL 的前置条件。"
---

# SFT构造数据的一些经验

## 摘要

以前我们对 posttraining 的理解很朴素：SFT 教模型干活，RLHF 教模型做人。DeepSeekR1 出来之后这个认知被打破了——R1Zero 连 SFT 都没做，直接拿 base model 跑 RL，推理能力就涌现了，自我验证、反思、长链推理都有。

## 关键断言

- 文章围绕“SFT构造数据的一些经验”组织问题和解释，主要小节包括：〇、SFT 的定位变了，先把这事儿说清楚、一、Long-CoT：绕不过去的话题、蒸馏来的比手写的好得多、但也不能一味追求长、Long-CoT SFT 是 RL 的前置条件。

## 涉及实体

- [[波哥聊大模型]]

## 涉及概念

- [[大模型预训练与微调]]

## 可复用方法

- 待进一步摄取时抽取

## 局限与不确定性

- 微信文章可能包含面试话术、经验判断或二手整理；涉及当前模型、项目状态、版本、性能数据时需要二次核对。

## 可继续追问

- 这篇资料应拆到哪些概念、方法、问题或对比页面？
