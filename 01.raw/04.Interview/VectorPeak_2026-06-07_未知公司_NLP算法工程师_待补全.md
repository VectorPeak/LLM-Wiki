---
source: "https://zpwwqabeuk.feishu.cn/minutes/obcn3sf7m8ezf5dwdmol2w5w"
name: "VectorPeak"
date: "2026-06-07"
company: "未知公司"
position: "NLP算法工程师"
interviewer: "interviewer"
candidate: "王宇辉"
duration: "00:24:28"
feishu_title: "新录音"
tags:
  - interview
  - feishu-minutes
  - question-chain
  - incomplete-transcript
type: "interview-question-chain"
status: "待补全"
audio_file: "E:\\LLMWiki\\minutes\\obcn3sf7m8ezf5dwdmol2w5w\\7648579661119278039_record_audio.m4a"
transcript_file: "E:\\LLMWiki\\minutes\\obcn3sf7m8ezf5dwdmol2w5w\\transcript.txt"
notes: "飞书 vc +notes 强制覆盖后仍只返回约 714 字稀疏逐字稿；完整音频已下载，需重新 ASR 或授权 Docx 智能纪要后补全。"
---

# 2026-06-07：未知公司/NLP算法工程师/面试问题链条（待补全）

> 当前版本只基于飞书 `vc +notes` 可返回的稀疏逐字稿与 AI 摘要整理。原录音时长约 24 分 28 秒，但飞书逐字稿只覆盖少量片段，尚不能代表完整面试内容。

## 一、工程能力与项目真实性确认
1. **主问题：** 这位候选人的工程能力是否足够强？
   - **追问1：** 这块工程能力是从哪些具体表现里判断出来的？
   - **追问2：** 是否只是概念表述不够清晰，但工程落地能力仍然是有的？
   - **追问3：** 如果继续追问候选人的项目，应从哪一段内容往下抽问题？

## 二、SCM/SVM 概念理解与公式表达
1. **主问题：** 候选人所说的 SCM/SVM 主要是什么？
   - **追问1：** 它是不是在寻找一个最优的超平面？
   - **追问2：** 候选人能否说明通过什么方式得到这个最优超平面？
   - **追问3：** 候选人是否只是死背概念，而没有讲清楚背后的公式和距离最短含义？

## 三、技术表述清晰度与压力追问
1. **主问题：** 候选人在相关技术内容上的表述是否足够清晰？
   - **追问1：** 如果候选人说“通过 SCM/SVM”，那它具体是什么？
   - **追问2：** 如果涉及超平面、距离最短等公式概念，候选人能不能讲出公式层面的解释？
   - **追问3：** 如果候选人讲不清楚，是概念掌握不牢，还是表达组织能力不足？

## 四、补全处理记录
1. **主问题：** 为什么当前版本没有覆盖完整 24 分钟录音？
   - **追问1：** `lark-cli vc +notes --overwrite` 后，本地 `transcript.txt` 仍只有约 714 个中文字符，虽然时间戳横跨 00:00:01 到 00:24:01。
   - **追问2：** 原始音频已通过 `lark-cli minutes +download` 下载到本地，文件大小约 10.7 MB，时长约 1468 秒。
   - **追问3：** 尝试调用 OpenAI ASR 时，本机 `OPENAI_API_KEY` 返回 `invalid_api_key`，因此未能完成二次转写。
   - **追问4：** 飞书智能纪要 Docx 链接读取需要 `docx:document:readonly`，当前该 scope 仍未授权。
