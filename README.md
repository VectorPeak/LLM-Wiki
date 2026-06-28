# LLM Wiki | 大语言模型知识图谱 & 面试备战库

面向 LLM / Agent / RAG 全栈学习的个人 Obsidian Second Brain 知识体系

`markdown` `obsidian` `LLM` `RAG` `Agent` `RLHF` `SFT` `interview` `knowledge-base`

简体中文 | [English](./README.en.md)

---

## 📖 关于本仓库

这是一个**个人知识管理仓库**，基于 [Obsidian](https://obsidian.md/) 构建，记录了大语言模型（LLM）及相关技术栈的学习笔记、面试准备资料、论文精读、课程笔记和微信文章剪藏。

> **定位**：从零到一的 LLM 工程师成长路径 —— 理论 + 实战 + 面试三位一体。

---

## 🗂️ 目录结构

```
LLM-Wiki/
├── 01.raw/                    # 原始素材（核心内容）
│   ├── 00.WorkSpace/          #   项目包装、面试生存指南
│   ├── 01.Inbox/              #   收件箱（临时存放）
│   ├── 02.DailyNotes/         #   日记 / 每日记录
│   ├── 03.SelfNotes/          #   自学笔记（八股生存指北等）
│   ├── 04.Interview/          #   面试相关（真题题库、简历模板）
│   ├── 05.Wechat/             #   微信文章剪藏（汐绫惠夜、骑猪撞宝马等）
│   ├── 06.Zhihu/              #   知乎剪藏
│   ├── 07.Website/            #   网页剪藏
│   ├── 08.Research/           #   论文精读笔记
│   ├── 09.Book&Courses/       #   书籍 & 课程资料（波哥LLM训练营等）
│   ├── 10.GitHub/             #   GitHub 相关笔记
│   ├── 11.Leetcode/           #   LeetCode 刷题笔记
│   ├── 12.Others/             #   其他杂项
│   └── 13.Videos/             #   视频笔记
├── 02.wiki/                   # 知识条目（Obsidian wiki 链接）
├── 03.templates/              # 模板文件
├── 04.output/                 # 输出产物
├── Bases/                     # Obsidian Dataview 基础定义
├── boards/                    # 看板数据
├── Logs/                      # 运行日志
├── AGENTS.md                  # Codex CLI 操作手册
└── _CLAUDE.md                 # Vault 约定规则
```

---

## 🎯 核心内容板块

### 1. 面试备战 (`04.Interview/`)
- **大厂 LLM 面试真题题库（已分类版）** — 57 个文件，按主题分类
- **LLM 简历模板** — 5 个岗位模板 + MedClaw 改写版
- 覆盖：Transformer 架构、预训练/SFT/RLHF、RAG 系统、Agent 框架、分布式训练、模型压缩

### 2. 系统化自学笔记 (`03.SelfNotes/`)
- 八股生存指北系列：RL 强化学习、SFT 模型微调、构建数据集
- 面试生存指南：技术栈梳理、项目话术准备

### 3. 论文精读 (`08.Research/`)
- Agent 方向核心论文精读笔记
- 聚焦 Memory Mechanism、Multi-Agent Systems、Production-Ready Agents

### 4. 课程笔记 (`09.Book&Courses/`)
- 波哥 LLM 训练营全套课程资料：
  - CC-runtime（C++ 推理运行时）
  - Function Calling
  - RAG 实战
  - Skills 技能框架
  - Agent 拓业智询

### 5. 微信剪藏 (`05.Wechat/`)
- **汐绫惠夜** — 17 篇：RL、分布式训练、模型压缩、MoE 等
- **骑猪撞宝马** — 4 篇：Agent 面经、大模型岗位分析、学习路线

---

## 🛠️ 技术栈 & 工具链

| 工具 | 用途 |
|---|---|
| [Obsidian](https://obsidian.md/) | 知识库主界面，双向链接 + Dataview |
| [Codex CLI](https://github.com/openai/codex) | AI 协作编辑，遵循 `AGENTS.md` 规范 |
| Git + GitHub | 版本控制 & 远端备份 |
| Mermaid (`forest` theme) | 图表可视化 |

---

## 📝 使用约定

详见 [`_CLAUDE.md`](_CLAUDE.md)：

- 所有笔记使用 AI-first frontmatter（`type`, `date`, `tags`, `ai-first: true`）
- 使用 `[[wikilinks]]` 建立实体间链接
- 外部声明需标注 recency marker 和来源
- Mermaid 图表默认 `forest` 主题 + compact 布局
- 临时文件放 `._trash&cache/`，不纳入版本追踪

---

## 🔗 相关仓库

| 仓库 | 说明 |
|---|---|
| [KnowFoundry-RAG-Console](https://github.com/VectorPeak/KnowFoundry-RAG-Console) | KnowForge RAG 平台 |
| [qwen-code](https://github.com/VectorPeak/qwen-code) | Qwen Code fork |
| [vectorpeak-agent-skills](https://github.com/VectorPeak/vectorpeak-agent-skills) | 自定义 Agent Skills |

---

## 📄 License

本仓库内容仅供个人学习使用。部分内容来源于公开博客、论文和课程，版权归原作者所有。
