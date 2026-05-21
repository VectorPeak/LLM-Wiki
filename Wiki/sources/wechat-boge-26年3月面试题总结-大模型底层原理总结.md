---
type: source
title: "26年3月面试题总结-大模型底层原理总结"
created: 2026-05-19
updated: 2026-05-19
status: developing
tags:
  - source
  - wechat
  - llm
  - interview
related:
  - "[[Agent 与 RAG 工程面试]]"
sources: []
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/Wechat_波哥聊大模型_26年3月面试题总结-大模型底层原理总结.md"
source_type: wechat
author: "波哥聊大模型"
date_published: ""
url: ""
confidence: medium
key_claims:
  - "文章围绕“26年3月面试题总结-大模型底层原理总结”组织问题和解释，主要小节包括：一、Self-Attention：面试的绝对中心、1.1 Self-Attention 的完整计算流程、1.2 为什么 QK^T 要除以 √dₖ？、1.3 Self-Attention 的 O(n²) 复杂度来源、1.4 为什么 Q/K/V 需要三个独立的线性投影？。"
  - "内容具有面试题/八股整理属性，写入 Wiki 时应区分可验证事实、答题话术和个人经验。"
  - "其中涉及的技术结论后续可拆分到 concepts、methods、questions 或 comparisons 页面。"
---

# 26年3月面试题总结-大模型底层原理总结

## 摘要

从 180+ 道真实面试题中提炼，主要包括SelfAttention、位置编码、归一化、架构选型、MoE等5方面的内容 （完整面经获取方法，（1）加入LLM冲刺营（wx联系Burger\_AI）；（2）加入DailyLLM社群（见文末二维码））

## 关键断言

- 文章围绕“26年3月面试题总结-大模型底层原理总结”组织问题和解释，主要小节包括：一、Self-Attention：面试的绝对中心、1.1 Self-Attention 的完整计算流程、1.2 为什么 QK^T 要除以 √dₖ？、1.3 Self-Attention 的 O(n²) 复杂度来源、1.4 为什么 Q/K/V 需要三个独立的线性投影？。
- 内容具有面试题/八股整理属性，写入 Wiki 时应区分可验证事实、答题话术和个人经验。
- 其中涉及的技术结论后续可拆分到 concepts、methods、questions 或 comparisons 页面。

## 涉及实体

- [[波哥聊大模型]]

## 涉及概念

- 待归类

## 可复用方法

- 待进一步摄取时抽取

## 局限与不确定性

- 微信文章可能包含面试话术、经验判断或二手整理；涉及当前模型、项目状态、版本、性能数据时需要二次核对。

## 可继续追问

- 这篇资料应拆到哪些概念、方法、问题或对比页面？
