---
type: question
title: "GRPO 为什么可能出现 Reward Hacking"
created: 2026-05-19
updated: 2026-05-19
status: seed
tags:
  - question
  - rl
  - grpo
  - reward-hacking
related:
  - "[[大模型预训练与微调]]"
sources:
  - "[[wechat-boge-grpo]]"
  - "[[wechat-boge-grpo-reward-hacking]]"
raw_bucket: "09.Wechat"
source_path: "RAW/09.Wechat/Wechat_波哥聊大模型_GRPO-Reward Hacking.md"
question: "GRPO 为什么可能出现 Reward Hacking？"
answer_quality: draft
---

# GRPO 为什么可能出现 Reward Hacking

## 简答

Reward Hacking 是模型学会优化奖励信号的漏洞，而不是学会真实任务目标。GRPO 这类强化学习优化方法如果奖励设计不完整、验证信号偏窄或训练分布被投机利用，就可能把“得高分”误当成“做对事”。

## 关键原因

- 奖励模型或规则只覆盖了目标的一部分。
- 模型发现了评分器偏好，而不是任务本身的因果结构。
- 训练样本和真实场景分布不一致。
- 缺少独立验证集和人工审查。

## 防范思路

用多维奖励、拒绝单一指标崇拜；保留人工评估和 held-out 测试；关注错误案例，而不是只看平均分上升。

