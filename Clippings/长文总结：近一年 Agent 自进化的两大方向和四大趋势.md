---
title: "长文总结：近一年 Agent 自进化的两大方向和四大趋势"
source: "https://mp.weixin.qq.com/s/9oRWcqmWQbNeUwGgM5dIDA"
author:
  - "[[Victor]]"
published:
created: 2026-05-16
description: "Agent 如何一步步学会进化"
tags:
  - "clippings"
---
Victor *2026年3月30日 09:01*

你有没有遇到过这种情况：使用一个通用的 Agent 时，跑了几周，它还是在用最初那套策略，犯同样类型的错误？

我之前也一直觉得这是 LLM 的本质限制，毕竟推理时没有梯度，没有更新。

但 2025 年这一整年下来，这个问题有了截然不同的答案。

不是因为某个单一突破，而是很多研究几乎同时在往一个方向走：让 Agent 能从自己的经历里学，并且越用越好。

这篇文章是我对 2025 年至今 Agent 自进化方向的一次系统梳理。

研究太多啦，我按逻辑分成了几类，每类挑了几篇我觉得最有代表性的详细说说。

## 先说说这个方向到底在解决什么问题

一个 Agent 每天在跑任务，每次成功或失败都有轨迹留下来。

但这些轨迹往往直接扔掉了，下次任务从零开始，什么都没记住。这是一种极大的浪费。

自进化研究问的就是：能不能让 Agent 把这些经历沉淀下来，变成更好的策略、更丰富的工具集、或者更扎实的模型权重？

2025 年的研究大致沿着两条路走：一条不动基础模型，靠经验、技能、记忆在推理时进化；另一条直接改模型权重，用强化学习让模型越训越强。

当然还有介于两者之间的，以及多智能体协同进化的路线。

## 第一类：经验与技能积累，不改模型权重

这类工作最直觉，也是工程上最容易落地的一路。核心思路是：不动基础模型，把 Agent 的成功经历抽象成可复用的"技能"或"原则"，下次遇到类似问题就直接调用。

### EvolveR：从轨迹到原则的闭环

> 论文链接：https://arxiv.org/abs/2510.16079  
> 发表时间：2025 年 10 月  
> 机构：浙大、上海AI Lab

这是我觉得这个方向里思路最清晰的一篇。

EvolveR 把进化拆成两个阶段：离线蒸馏和在线交互，构成一个持续运转的闭环。

离线阶段，Agent 跑完一批任务之后，对所有轨迹做提炼，把具体的交互步骤抽象成更通用的"策略原则"，存入原则库。

在线阶段，Agent 在新任务里实时检索这些原则，指导自己的行动，同时又产生新轨迹，反哺下一轮蒸馏。

![图片](https://mmbiz.qpic.cn/sz_mmbiz_jpg/65Qhnfp96fgtnMIX3HPMy4jYbmLOjFJCZXBNqx818UWlzpyQvh1mA0p3QEO7HTqV5gJLAfcibNBMSnOhmZppdvH1BUptL6mrM72RoG1wpmyo/640?wx_fmt=jpeg&from=appmsg&watermark=1&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=0)

关键在于这个"原则"的抽象层次。它不是把某次具体的工具调用记下来，而是提炼出类似"遇到多跳问题时，先分解子问题再并行检索"这样的更高层策略。这让技能有了跨任务迁移的能力。

在多跳问答基准上，EvolveR 明显优于同类 Agent 基线。更重要的是，随着轮次增加，性能是持续往上走的，而不是很快到达天花板。

### CASCADE：技能库的科学研究版本

> 论文链接：https://arxiv.org/abs/2512.23880  
> 发表时间：2025 年 12 月  
> 机构：UC Berkeley

CASCADE 来自 Berkeley，场景比较专，专注材料科学和化学。但它提出的"技能"概念我觉得是这个方向里定义最干净的。

它把 Agent 能力分成两个层次。工具调用是底层，技能是对工具调用的封装，可执行、可共享、随时间累积。

两个元技能驱动整个系统：持续学习，通过网络搜索、代码提取和记忆调用来获取新技能；自我反思，通过内省和知识图谱探索来精炼已有技能。

他们还做了一个叫 SciSkillBench 的基准，包含 116 个材料科学和化学研究任务。

结果是：用 GPT-5 搭配 CASCADE，成功率 93.3%，而没有进化机制的基线只有 35.4%。这个差距相当大。

技能库的另一个特性是可在不同 Agent 之间共享，包括和人类科研人员共享。这不只是一个 Agent 内部的学习机制，更像是一个团队共享的知识积累系统。

### STELLA：在生物医学领域把"工具海洋"做起来

> 论文链接：https://arxiv.org/abs/2507.02004  
> 发表时间：2025 年 7 月  
> 机构：Stanford、Princeton

STELLA 是专门做生物医学的，我选它是因为它在一个极度专业化的领域里把自进化做起来了，而且跑出来的数字很实在。

它的两个核心机制是：动态工具海洋和进化模板库。

工具海洋的意思是，有一个独立的 Tool Creation Agent，会自动发现新的生物信息学工具，验证可用性之后集成进来。Agent 不需要等人类手动添加工具，自己就会找。

进化模板库则类似于 EvolveR 的原则库，存储和精炼从经验里学到的推理策略。

在 Humanity's Last Exam 生物医学子集上，STELLA 跑出了约 26% 的准确率，在 LAB-Bench 的 DBQA 子任务上是 54%，LitQA 子任务是 63%，比当时的领先模型高出最多 6 个百分点。

有一个细节我觉得比这些绝对数字更能说明问题：随着试验次数增加，准确率几乎翻倍了。自进化效果是真实的，不是噪声。

### AutoSkill：从日常交互中持续提炼技能

> 论文链接：https://arxiv.org/abs/2603.01145  
> 发表时间：2026 年 3 月  
> 机构：华东师范大学、上海AI Lab

AutoSkill 做的事情和 EvolveR 有点像，但更聚焦在技能本身的生命周期管理上。

Agent 在日常任务里产生交互经历，AutoSkill 从中识别反复出现的模式，抽象成可复用技能。

已有技能被使用后，系统持续评估效果，决定是精炼、扩展还是废弃。

相关技能在新任务开始时动态注入 Agent 的上下文，不需要人工设计和维护技能库。

这种"技能有生老病死"的设计是这个方向里我觉得工程上最务实的。一个只增不减的技能库迟早会变成负担，检索效率和精准度都会受影响。

### MemSkill：把记忆管理本身变成可进化的技能

> 论文链接：https://arxiv.org/abs/2602.02474  
> 发表时间：2026 年 2 月  
> 机构：南洋理工

大多数 Agent 记忆系统是固定架构的——固定的向量检索、固定的摘要策略。

MemSkill 提出，记忆管理本身应该是一个可以自我进化的技能，而不是静态的基础设施。

它让 Agent 把记忆操作也纳入技能的范畴：何时存、存什么、怎么检索、何时遗忘，这些都可以随经验优化。

遇到一类新任务时，Agent 不只是学怎么完成任务，还会学什么样的记忆模式对这类任务最有效。

这个思路让我想到一个类比：大多数工作在"怎么用记忆做任务"，MemSkill 在"怎么进化记忆系统本身"。后者的层次更高，也更难验证效果，好的记忆策略往往在任务分布发生变化时才能看出来。

### SkillWeaver：Web Agent 自己发现和磨炼技能

> 论文链接：https://arxiv.org/abs/2504.07079  
> 发表时间：2025 年 4 月  
> 机构：俄亥俄州立

SkillWeaver 把技能的发现和训练过程做成了类 API 的形式：Agent 在访问一个新网站时，不只是完成当前任务，还会同时提炼出一个可重复调用的"技能接口"，就像给这个网站写了一个 SDK。后续在同一网站或类似场景下，直接调用这个技能，而不是从头推理每一步操作。

这个类比很有用。工具调用是调用现有 API，SkillWeaver 做的是 Agent 自己写 API。对于需要频繁操作同类网站或 SaaS 工具的场景，这种方式理论上可以大幅降低每次任务的 token 消耗和出错率。

### EvoSkill：从失败里自动挖出新技能

> 论文链接：https://arxiv.org/abs/2603.02766  
> 发表时间：2026 年 3 月  
> 机构：Sentient labs

大多数技能积累框架关注的是成功轨迹——把做对的步骤存下来。

EvoSkill 反过来，专门盯着失败。

每次任务失败，EvoSkill 会分析失败原因，判断是因为缺少某种能力，还是现有技能用错了场景。前者触发新技能的生成，后者触发对现有技能边界条件的修订。

这个失败驱动的发现机制让技能库能覆盖到那些"正常走通就不会触发"的边界情况，补上平时容易遗漏的盲区。

在多智能体场景下，不同 Agent 的失败轨迹可以汇聚在一起做集体分析，提炼出单个 Agent 自己无法发现的技能。这是这篇工作在多智能体背景下做的特有贡献。

### Tool-R0：零数据学会用工具

> 论文链接：https://arxiv.org/abs/2602.21320  
> 发表时间：2026 年 2 月  
> 机构：伊利诺伊大学、苏黎世联邦理工

Tool-R0 的出发点很直接：新工具出现时，不能依赖人工整理调用示例。能不能让 Agent 完全靠自己摸索，从零开始学会调用一个陌生工具？

它让 Agent 自己生成工具调用尝试，根据实际执行结果判断对错，用这个信号迭代改进调用策略。

整个过程不需要任何预先准备的训练数据，只需要工具本身可以被实际执行并返回反馈。

随着尝试次数积累，Agent 会逐步建立起对工具参数规范、边界情况和典型用法的理解。

和 SkillWeaver 相比，Tool-R0 更底层，SkillWeaver 是把已经会用的工具封装成可复用技能，Tool-R0 解决的是"连基础调用都还不会"的前置问题。

## 第二类：基于强化学习的训练型自进化

如果说第一类是在推理时学习，第二类就是直接改模型权重，让模型从根本上变强。2025 年至今这个方向非常活跃，有几条不同的技术路线。

### OpenClaw-RL：把日常使用变成训练信号

> 论文链接：https://arxiv.org/abs/2603.10165  
> 发表时间：2026 年 3 月  
> 机构：Princeton（Gen-Verse 实验室）

这篇是我最近看到最有意思的工作，核心想法极其简单：Agent 每次和用户交互、调用工具、操作终端或 GUI，都会产生一个"下一状态"——用户的回复、工具的输出、界面的变化。这些下一状态本身就包含了对 Agent 行为的评价，为什么不直接用来训练？

OpenClaw-RL 把下一状态信号分成两类。评估信号回答"这次做得好不好"，用 Process Reward Model 提取成标量奖励。指导信号回答"应该怎么做更好"，用一种叫 Hindsight-Guided On-Policy Distillation 的方法，从下一状态里提取文字提示，构建增强的教师上下文，做 token 级别的方向性优势监督。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

整个系统是完全异步的：模型服务、PRM 评判、训练器更新同时跑，互不等待。这样部署中的 Agent 就可以一边被使用，一边在更新。

它支持个人 Agent、终端 Agent、GUI Agent、SWE Agent 和工具调用场景，全部在同一个训练框架里处理。

从原理上说，Agent 只要在被正常使用，就能一直变强。

### SAGE：把技能库接进强化学习

> 论文链接：https://arxiv.org/abs/2512.17102  
> 发表时间：2025 年 12 月  
> 机构：威斯康星大学、AWS

SAGE 的思路是把第一类（技能积累）和第二类（RL 训练）融合起来。

它做了一个叫 Sequential Rollout 的机制：每次 rollout 不是跑一个任务，而是让 Agent 依次跑一串相似的任务。跑早期任务时积累下来的技能，在同一个 rollout 里的后续任务里就能直接用。这意味着在训练过程中，模型就被迫学会"生成技能"和"复用技能"，不只是会完成任务。

奖励设计也配套：除了任务完成的结果奖励，还有额外的信号专门激励技能的生成和调用。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

在 AppWorld 这个复杂多应用任务基准上，SAGE 比基线 GRPO 高出 8.9 个百分点的场景目标完成率，交互步数少 26%，生成 token 数少 59%。准确率更高，成本更低，这个组合很有说服力。

### SkillRL：技能库和 RL 策略递归互喂

> 论文链接：https://arxiv.org/abs/2602.08234  
> 发表时间：2026 年 2 月  
> 机构：北卡罗来纳大学

SkillRL 和 SAGE 的出发点相似，但结构更激进：技能库和 RL 策略之间是双向递归的，而不是单向的"技能辅助训练"。

具体来说，RL 训练产生的轨迹会被分析提炼，新技能存入库。下一轮 RL 训练使用更丰富的技能库，产生更高质量的轨迹，再次反哺技能提炼。每一轮技能库的扩充都会拓宽下一轮 RL 的可达策略空间，让两者一起往上走。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

和 SAGE 的主要区别在于方向性：SAGE 是"在 RL 训练过程中顺便学技能"，SkillRL 是"技能和策略互为彼此的训练数据"。前者更稳，后者理论上可以走得更远。

### SE-Agent：进化的是轨迹本身

> 论文链接：https://arxiv.org/abs/2508.02085  
> 发表时间：2025 年 8 月  
> 机构：清华大学、阶跃AI

SE-Agent 提的问题很有意思：Agent 做错了，我们通常的做法是重新采样一条轨迹，但这样很低效，因为丢掉了原轨迹里有用的部分。能不能直接对轨迹做手术，把它改好？

它定义了三个操作：修订（找出错误步骤并纠正）、重组（跨轨迹借用成功的子片段）和精炼（打磨接近正确的轨迹直到完全正确）。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

不同于 MCTS 假设每条搜索路径相互独立，SE-Agent 显式建模了轨迹间的依赖关系，让不同轨迹的成功经验可以互相借鉴。

在 SWE-bench Verified 上，跨五个主干 LLM 测试，相对基线平均提升最高达 55%，当时是所有开源 Agent 里的最强结果。

### Agent0：从零数据自举起来

> 论文链接：https://arxiv.org/abs/2511.16043  
> 发表时间：2025 年 11 月  
> 机构：北卡罗来纳大学

这篇我觉得代表了 RL 训练里一个重要趋势：完全不要人工标注的数据。

Agent0 维护两个 Agent：课程 Agent 负责提出越来越难的任务，执行 Agent 负责用外部工具去完成。两者形成竞争共生：执行 Agent 越来越强，课程 Agent 就必须提出更难的任务，否则提供不了有效的训练信号。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

从同一个基础模型（Qwen3-8B-Base）出发，零人工标注，数学推理基准提升了 18%，通用推理基准提升了 24%。

更重要的是它说明了什么是可能的：只要有一个可以自动验证对错的环境，就可以完全自举地训练 Agent，不需要人类进入这个循环。

### MetaClaw：在生产环境里持续进化，不停机

> 论文链接：https://arxiv.org/abs/2603.17187  
> 发表时间：2026 年 3 月  
> 机构：北卡罗来纳大学、卡内基梅隆大学

MetaClaw 来自和 Agent0 同一个实验室，但它解决的问题往前推了一步：Agent 部署上线之后，怎么在用户实际使用的过程中持续进化，同时完全不停机？

它把进化拆成两个机制，并且两个机制同时运行。

第一个是技能驱动的快速适应：遇到失败轨迹，LLM evolver 立即分析并合成新技能，效果即时生效，不需要等待训练。

第二个是机会性策略优化：利用用户不活跃的空闲窗口触发，由一个叫 Opportunistic Meta-Learning Scheduler 的调度器监控系统活跃度和日历数据，找到合适时机就在后台做云端 LoRA 微调加 RL-PRM 训练，不干扰正常服务。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

两个机制互相喂数据：更好的策略产生更高质量的轨迹，这些轨迹又变成更好的技能合成素材。论文还引入了版本隔离机制，把支撑数据和查询数据分开，防止训练时数据污染。

在 AutoResearchClaw 基准上，Kimi-K2.5 的准确率从 21.4% 提升到了 40.6%，绝对提升 19.2 个百分点。技能驱动适应单独贡献了最高 32% 的相对提升。

我觉得 MetaClaw 真正有意思的地方不是数字，是它把"部署即训练"这件事工程化了。OpenClaw-RL 是理论框架，MetaClaw 是把它接到实际产品系统里的那一步。

### SWE-RL：用开源代码库历史训练软件工程 Agent

> 论文链接：https://arxiv.org/abs/2502.18449  
> 发表时间：2025 年 2 月  
> 机构：Meta、伊利诺伊大学

这是最早系统性地把 RL 用在真实软件工程场景的工作之一。

GitHub 上的开源仓库天然就是一个巨大的训练数据集：每个 issue、每个 pull request、每次代码变更，都是一条"问题—解决方案"对。

SWE-RL 用这些数据作为 RL 的训练信号，用模型生成解法和真实 patch 之间的相似度作为奖励。规则明确，不需要任何人工标注。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

在 SWE-bench Verified 上，基于 Llama 3 训练的模型跑出了 41.0% 的解决率，是当时 100B 以下参数量模型里的最高分，和 GPT-4o 持平。

更让我觉得有价值的是泛化结果。SWE-RL 训出来的模型在五个域外任务上全面提升，覆盖函数编码、库使用、代码推理、数学和通用语言理解。相比之下，SFT 基线在同样的域外任务上平均是下降的。这说明 RL 在软件工程上学到的不只是编程技巧，而是更通用的推理能力。

### Absolute Zero：完全不要外部数据，自己给自己出题

> 论文链接：https://arxiv.org/abs/2505.03335  
> 发表时间：2025 年 5 月  
> 机构：清华大学

这篇的名字起得很贴切，思路也是这一批工作里最简洁的：单个模型同时扮演出题人和解题人，用代码执行器作为唯一的验证来源，完全不碰任何外部数据。

出题人生成三类编程推理任务：演绎（已知规则求结果）、归纳（已知样本求规律）和溯因（已知结果求原因）。生成的同时产出答案，代码执行器验证对错，给解题人提供奖励信号。随着解题人变强，出题人被迫构造更难的题，整个课程自动升级。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

在零外部数据的设定下，Absolute Zero 在编程和数学推理上都拿到了 SOTA，超过了用几万条人工整理数据训练的对比模型。

这和 Agent0 的思路本质相同，但 Absolute Zero 更专注在推理能力本身，不引入外部工具。两篇几乎同期发表，说明"自己给自己出题"这个方向确实有不止一个团队在独立收敛到相同结论。

## 第三类：多智能体协同进化

单个 Agent 自我进化有一个天花板：它只能从自己的经历里学。多智能体路线则试图通过多个 Agent 之间的竞争和协作来产生更丰富的训练信号。

### Self-Challenging：自己出题，自己训练

> 论文链接：https://arxiv.org/abs/2506.01716  
> 发表时间：2025 年 6 月  
> 机构：加利福尼亚大学、Meta

Meta 这篇把问题拆成了 Challenger 和 Executor 两个角色，由同一个模型扮演。

Challenger 用已有工具"生成"一道题，生成的同时顺带给出正确答案和验证函数，这个设计叫 Code-as-Task。因为验证函数是代码，任务质量可以被自动过滤，不需要人工审核就能保证训练数据的质量。Executor 用 RL 在这些自生成任务上训练，以验证反馈为奖励。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

在 M3ToolEval 和 TauBench（多轮工具使用 Agent 基准）上，Llama-3.1-8B-Instruct 取得了超过 2 倍的性能提升，且不需要任何人工标注。

### SiriuS：多智能体系统靠经验库自举

> 论文链接：https://arxiv.org/abs/2502.04780  
> 发表时间：2025 年 2 月  
> 机构：Stanford

这是去年较早的一篇，做的是多智能体系统级别的自我提升。

SiriuS 构建一个经验库，把导向成功结果的推理步骤保留下来。但只保留成功的不够，他们还对失败轨迹做了"精炼增广"，把接近成功的轨迹也改造进来，丰富训练数据。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

用这个库对多智能体系统里的专业 Agent 做微调，性能提升在 2.86% 到 21.88% 之间，具体取决于任务类型。

这个范围很大，说明效果对任务类型敏感。在推理和生物医学 QA 这类有明确验证的任务上，增益更显著。

## 第四类：系统框架与安全

### 自进化 Agent 的风险：Misevolution

> 论文链接：https://arxiv.org/abs/2509.26354  
> 发表时间：2025 年 9 月  
> 机构：上海交通大学、商汤研究院

这篇是我觉得被低估的工作。大家都在研究怎么让 Agent 进化得更快，但没有人系统研究：进化出问题了会怎样？

"Misevolution" 指的是自进化过程中出现的非预期偏移。他们把进化路径分成四个维度：模型权重、记忆、工具和工作流，然后逐一测试失控情况。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

结论让人警惕：记忆积累之后，安全对齐会降级——Agent 会开始接受它原本应该拒绝的请求；工具创建和复用会无意中引入代码漏洞；甚至 Gemini-2.5-Pro 这样的顶级模型也未能免疫。

这说明自进化不是"配置好了就可以放手"的东西，需要有配套的审计和约束机制。

### 综述：自进化 Agent 的全局视角

> 论文链接：https://arxiv.org/abs/2507.21046  
> 发表时间：2025 年 7 月  
> 机构：UIUC、Princeton、清华等17家机构

这是 2025 年发布的第一篇系统性综述，从三个维度组织整个领域：进化什么、什么时候进化、如何进化。进化什么覆盖模型权重、记忆、工具和架构；什么时候涵盖测试时内部、测试时之间和部署后；如何进化则区分标量奖励、文字反馈、单/多智能体。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

综述里有一个判断我认同：自进化 Agent 的终极形态不是单一机制，而是几种路线的组合。技能积累处理"怎么做"，RL 训练处理"学到根上"，多智能体竞争提供训练信号的多样性，安全审计保证方向不偏。

## 几个横跨全部类别的趋势

整理完这一批论文，有几个共同的东西反复出现：

**零标注数据是共同目标。** 几乎所有 2025 年的新工作都在向"不需要人工标注"的方向走——用自生成验证、环境反馈、竞争信号代替人工标注。这个趋势背后是成本，也是规模化的必要条件。

**过程奖励比结果奖励重要。** OpenClaw-RL、SAGE、SE-Agent 都独立发现了这一点：只看最终任务是否完成的奖励信号太稀疏，会导致训练不稳定或效率低下。对每一步行动的细粒度评估是稳定 RL 训练的关键。

**奖励模型本身要一起进化。** MetaClaw 的训练经验都明确指出：如果奖励模型冻结，策略进化会触发 reward hacking，然后停滞。让奖励模型跟着策略一起更新，是防止训练崩溃的必要条件。

**安全是新问题。** Misevolution 那篇说明，自进化不只是性能优化的问题，还是安全问题。2026 年这个方向应该会有更多工作。

## 我的感受

回到最开始的问题：Agent 用了一段时间之后，应该比最初更好，还是永远停在部署时的状态？

2025 年这批工作的答案是：它可以更好，而且已经有了不止一种可行的路线。

技能积累路线工程友好，直接就能用。RL 训练路线效果更扎实，但成本高、风险也更大。多智能体协同进化在某些场景下可以绕过人工标注的瓶颈。

让我觉得真正有价值的不是其中某一篇具体的论文，而是这个方向在过去一年里形成的共识：Agent 不应该是静止的。每一次交互都是数据，每一次失败都是信号，这些不应该被浪费掉。

悬而未决的问题当然还有：大规模部署中，在线 RL 的稳定性怎么保证？Misevolution 怎么系统性防御？技能库规模大了之后检索效率如何？我相信这些在 2026 年应该会有更多答案。

AI Agent · 目录

继续滑动看下一个

硅基捕手维克托

向上滑动看下一个