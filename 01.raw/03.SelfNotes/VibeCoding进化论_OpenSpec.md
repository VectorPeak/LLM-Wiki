## SDD开发工具
Vibe Coding 是“先让 AI 写起来再说”，优点是快，缺点是容易跑偏。 
SDD(Spec-Driven-Development 规格驱动开发) 是“先把图纸画清楚，再让 AI 施工”，速度可能慢一点，但更稳,更可复查

>**本质相同:提示词注入+方法论约束, 区别在于重量级和灵活性**

| SDD工具       | 简单理解一句话                                 |
| ----------- | --------------------------------------- |
| SuperPowers | 给 AI 配一套工程习惯，让它按流程做事                    |
| Spec-Kit    | GitHub 推出的 SDD 工具包，用来生成 spec、plan、tasks |
| OpenSpec    | 把需求变成项目里的正式规格文档，方便 AI 按图施工              |
| Kiro        | AWS 的 AI IDE，把规格、设计、任务和执行流程内置到开发环境里     |

## OpenSpec是什么?
OpenSpec 是一个给 **AI 编程助手用的「规格驱动开发」工具**。它的核心作用是：先把“要做什么、为什么做、验收标准是什么、任务怎么拆”写成项目内的规格文档，再让 Codex、Claude Code、Cursor、Copilot、OpenCode 等 Agent 按这些文档去实现代码


## OpenSpec好在哪?
***OpenSpec 的核心价值：把 AI 编程从“临时对话”变成“可追踪工程流程”***
~~~
1. 规格文档写得好
   用 proposal(为什么做?-Why)、spec(做什么?-What)、design(怎么做?-How)、tasks(按照什么顺序做?-When)把需求、设计、任务和验收标准拆清楚，
   AI 不只是“接一句 prompt”，而是按结构化上下文工作。

2. 灵活度比较高
   它不是重型项目管理系统，而是仓库里的轻量 Markdown 流程：
   既能约束 AI，又不把开发流程绑死。

3. 文档管理好
   specs/ 保存当前系统状态，
   changes/ 管理正在进行的改动，
   archive/ 留下历史轨迹。
   这让项目有“当前真相”，也有“演化记录”
~~~


## OpenSpec基本流程
### OpenSpec两种模式(core / custom)
***core模式***
core 模式更轻量，适合刚开始使用 OpenSpec：
只保留“提案 → 探索 → 实施 → 归档”这条主流程
~~~
propose  # 生成规格文档
explore  # 探索项目结构
apply    # 执行开发任务
archive  # 归档变更记录
~~~

**custom模式**
custom 模式更完整，适合长期项目：
可以继续未完成任务、同步规格、验证结果、批量归档，也更适合团队协作
~~~
propose explore apply archive
new-change continue ff-change sync verify onboard bulk-archive
~~~

**通过该命令来切换core / custom 模式**
~~~
$ openspec config set profile core/custom
~~~
>其实OpenSpec最早默认就是这11条命令, 可能后来觉得11条命令太复杂了, 就缩减到这4条命令了



### /explore 指令
> 你不需要想清楚再动手,有一个大致的想法就行,剩下的交给AI去细化(考虑edge cases)

当还没有完全想清楚需求时，先用 /explore。
它的作用不是立刻写方案，而是让 Agent 先帮你探索问题：
梳理目标、补全遗漏、识别边界情况（edge cases），并把一个模糊想法拆成更清楚的开发方向

### /propose 指令
 
 当需求方向已经比较明确时，用 /propose 创建变更提案。
 
Agent 会在 openspec/changes/ 下创建一个新的变更目录，
并按约定生成 proposal.md、design.md、tasks.md，以及对应的 specs/ 规格文件

这些文件不是随便生成的，而是按照 OpenSpec 的流程预先配置好的：**先说明为什么做，再说明做什么，最后拆成可执行任务**

 ~~~
├── proposal.md      # 为什么做？  需求背景 + 功能列表 + 影响范围
├── specs/           # 做什么？ 每一个功能点一份详细规格,用"当**则**"句式
│   ├── model-api/
│   │   └── spec.md  # 接口参数、错误处理
│   └── chat-ui/
│       └── spec.md  # 界面交互规格
├── design.md        # 怎么做？    技术选型 + 架构决策 + 风险权衡
└── tasks.md         # 按什么顺序? 带复选框的开发清单 + 可追踪的进度
 ~~~

![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260513162708170.png?imageSlim)
> 一份好的文档要把开发者变成无情的执行机器. 不要让他们思考, 拿到文档就能干活, OpenSpec生成的规格文档, 基本上是做到这个要求了
> 很多讲SDD的文章会花很多时间去讲优秀的规格文档是什么样子的.我建议你们不要研究那么多抽象的理论. 直接看一下OpenSpec的文档会更加直观



**Config 定制技巧**
OpenSpec提供了`./specs/config.yaml`配置文件, 可以写入全局要求以及对每个文档的个性化要求
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260513163604352.png?imageSlim)


### /apply 指令
当 proposal、design、tasks 和 specs 都确认之后，用 /apply 进入实现阶段

Agent 会按照 tasks.md 的任务清单开始修改代码，
并以 specs/ 中定义的行为作为实现依据


### /archive 指令
 Agent会为此处开发任务创建一个specs文件夹,然后在文件夹下创建相关文档 要创建什么文档,按照什么顺序创建,每个文档创建什么内容.这些东西都是事先配置好的
 
执行archive 指令时, OpenSpec会执行两类任务:
~~~
1.将整个文件夹移入 archive/, 名字前加上日期
add-ai-chat/ --> archive/2026-05-06-add-ai-chat/
(无脑保存每一次-->完整保留历史修改轨迹,每一次归档都是独立副本)

2.specs/内容合并到外层 specs/ 目录
变更区内的 specs.md 智能合并到外层 openspec/specs/
(智能合并保持最新-->通过三种策略合并,始终反映当前的最新状态-真相来源)
~~~

**将整个文件夹移入 archive/, 名字前加上日期**
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260513165933470.png?imageSlim)

**将 specs/内容合并到外层 specs/ 目录**
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260513165952069.png?imageSlim)
~~~
Specs智能合并的三种操作
ADDED-新功能      --> 将整个文件夹新增到 specs/ 目录
ADDED-新增场景    --> 在已有文档中追加新段落(同一功能新增场景,直接加在原文档后面)
MODIFIED-修改场景 --> 替换已有段落的内容(假设修改这个功能,那直接修改这段文字,换成最新的描述)
~~~


## OpenSpec项目设计原理
### Skill/CLI/配置文件的关系
> OpenSpec并非一堆Skill或者Command文件组成, 而是将***Skill / CLI /配置文件 相互之间解耦合*** Skill/l只是维护基本的工作流程, 根本没有记录要写什么文档, 也不记录文档要怎么写, 后端程序自己从各个文件中组合出相关的信息, 动态生成文档的撰写要求.
~~~
Skill:    只负责工作流程,不和任何规格文档绑定,负责定义AI的执行步骤顺序
CLI:      动态读取配置,解析依赖关系,返回JSON组合指令
配置文件:  这里才定义要什么文档,怎么写,按什么顺序生成
改配置 = 改文档体系,不需要动Skill,也不需要动CLI
~~~


### schema.yaml
在各个配置文件当中,最为重要的是一个名为shema.yaml的配置文件, **schema.yaml 是 OpenSpec 工作流的总控文件.** 它不直接写业务需求，而是规定“规格文档应该如何被生成”
~~~
1. 定义工作流名称和版本
2. 定义 artifacts：要生成哪些文档
3. 定义 template：文档使用什么模板
4. 定义 instruction：文档应该怎么写
5. 定义 requires：文档依赖关系
~~~

~~~
name: spec-driven
version: 1
description: Default OpenSpec workflow - proposal → specs → design → tasks
artifacts:       # artifacts决定了需要生成哪些文件,每个id对应一个文件
  - id: proposal 
    
  - id: specs    # 每个文件也有自己的配置项,此处以specs为例
    generates: "specs/**/*.md"
	description: Detailed specifications for the change
	template: spec.md   # template 表示文档的模板,默认存储在与schema同级的template文件夹中,可以按照自己的需求进行修改
	instruction: |      # instruction 表示如何撰写这个文档的指令
	    Create specification files that define WHAT the system should do.
		Create one spec file per capability listed in the proposal's Capabilities:
	    - New capabilities: use the exact kebab-case name from the proposal.
	    - Modified capabilities: use the existing spec folder name from openspec/specs/...
		spec at specs/<capability>/spec.md.

	    Delta operations (use ## headers):
	    - **ADDED Requirements**: New capabilities
	    - **MODIFIED Requirements**: Changed behavior - MUST include full...
	    - **REMOVED Requirements**: Deprecated features - MUST include **...
	    - **RENAMED Requirements**: Name changes only - use FROM:/TO: format

	    Format requirements:
	    - Each requirement: `### Requirement: <name>` followed by description
	    - Use SHALL/MUST for normative requirements (avoid should/may)
	    - Each scenario: `#### Scenario: <name>` with WHEN/THEN format
	    - **CRITICAL**: Scenarios MUST use exactly 4 hashtags (`####`).
	    - Every requirement MUST have at least one scenario.

	    Common pitfall: Using MODIFIED with...
	    If adding new concerns without changing existing behavior, use ADDED...
	    
	requires:    # requires 说明这个文档的依赖文档,通常撰写文档是有顺序的
	- proposal
	  
  - id: design
  - id: tasks

apply:
  requires: [tasks]
  tracks: tasks.md
  instruction: |
    Read context files, work through pending tasks, mark complete as you go.
    Pause if you hit blockers or need clarification.

~~~
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260513175451983.png?imageSlim)

### OpenSpec 完整执行流程 --> 以/propose指令执行为例
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260513175607423.png?imageSlim)
~~~
以 /propose 指令为例，它的本质是：
把一段用户提示词交给模型，让模型按照 OpenSpec 的流程要求逐步生成规格文档

大致流程如下：

1. 创建变更目录
Agent 首先执行：
openspec new change "build-ai-chatbot"
OpenSpec 会创建一个新的变更目录
其中，name 通常由 AI 根据当前需求自动命名

2. 读取变更状态
接着，Agent 执行：
openspec status --change "build-ai-chatbot"
后端程序会解析 schema 文件，并返回一个 JSON
这个 JSON 会告诉 Agent：
当前需要创建哪些文档、文档之间有什么依赖关系、应该按什么顺序生成

3. 生成第一个文档
然后，Agent 会根据用户需求执行：
openspec instructions proposal --change "build-ai-chatbot"
后端程序会读取 schema、config、templates 等相关文件，
再返回一段用于生成 proposal 的结构化指令
模型拿到这段指令后，就知道：
这个文档要写什么、要参考哪些前置文档、要套用哪个模板、以及有哪些注意事项


4. 继续生成后续文档
第一个文档完成后，Agent 会继续读取下一步文档的撰写要求，
按照 schema 中定义的顺序依次生成 specs、design、tasks 等文件


这个过程会不断重复，直到当前变更所需的所有文档都创建完成
~~~

## OpenSpec:创建自己的文档体系 
> 大部分人可能没有这个需求, 毕竟官方的文档体系已经很能打了


大多数人其实不需要自定义文档体系, 官方默认流程已经足够覆盖常见的软件开发场景

如果你的项目有特殊流程，或者想让 AI 按自己的文档规范工作，可以通过自定义 schema 和 templates 来扩展 OpenSpec
~~~
1. fork默认schema
2. 改 schema.yaml (文档清单 + 依赖)
3. 改 templates/  (章节模板)
4. 改 config.yaml (指向新 schema)
~~~
 
**schema.yaml配置项**

| 配置项            | 位置      | 含义             | 示例              | 怎么改                   |
| -------------- | ------- | -------------- | --------------- | --------------------- |
| name           | 顶层      | schema 名称，用于标识 | spec-driven     | 改成你自己的名字              |
| artifacts      | 顶层      | 文档列表，数组形式      | 4 个artifacts    | 删掉不想要的，新增想要的          |
| id             | 每个工作    | 文档标识，命令引用用     | proposal        | kebab-case 命名         |
| generates      | 每个工作    | 输出文件路径         | proposal.md     | 支持通配符，如 specs/**/*.md |
| template       | 每个工作    | 模板文件名          | proposal.md     | 对应 templates/ 下的文件    |
| instruction    | 每个工作    | 撰写指令，AI 的行动指南  | 多行文本            | 告诉 AI 这份文档要写什么        |
| requires       | 每个工作    | 前置依赖，控制文档创建顺序  | [specs, design] | 调整依赖关系                |
| apply.requires | apply 节 | apply 前必须完成的工作 | [tasks]         | 通常设为最后一个工作            |
| apply.tracks   | apply 节 | 进度追踪文件         | tasks.md        | 解析 - [ ] 复选框          |


## 面试问题
**Q1:你知道什么是SDD吗?**

A:
**(介绍概念)** SDD 是 Spec-Driven Development，也就是“规格驱动开发”。它的核心思想是：不要一上来就写代码，而是先把需求、边界、接口、验收标准和任务拆分写成清晰的规格文档，再让人或 AI 按这个规格去实现

**(展开对比传统开发)** 在传统开发里，很多问题来自“需求说不清”，开发只能边猜边做；在 AI 编程里，这个问题会被放大，因为 AI 很容易根据模糊提示生成看似能跑、但实际偏离目标的代码。SDD 的价值就是把“聊天里的想法”沉淀成可版本管理、可审查、可复用的 spec，让实现过程有依据

(**引入TDD**) 在一个完整的 Vibe Coding 开发流水线里边，SDD 和 TDD 可以结合使用。SDD 是在入口处进行约束，要求先把需求、边界、设计和验收标准定义清楚，避免 AI 一开始就理解跑偏；TDD 是在出口处进行管控，它通过测试用例约束代码实现，确保 AI 生成的结果能被严格验证。所以可以理解为：SDD 负责让 AI “做对方向”，TDD 负责验证 AI “做得正确"



**Q2:OpenSpec是什么?**

A:
**(OpenSpec是什么?)** OpenSpec 是一个面向 AI 编程的 SDD 工具。它的作用是把一次功能变更先整理成 proposal、design、tasks 和 specs 这类项目文档，再让 AI 按这些规格去实现代码
**(OpenSpec的作用?)** 它解决的是 AI 编程里“需求容易跑偏、上下文容易丢、实现过程不好追踪”的问题。普通 Vibe Coding 往往是直接把需求丢给 AI，让它马上写代码；OpenSpec 更像是先把施工图纸画出来，再让 AI 按图施工
**(详细说一说OpenSpec好在哪里?)** 



**Q3:你个人的项目开发是如何应用OpenSpec的?(或是让你谈你使用OpenSpec开发的个人经验 / 如何使用这个OpenSpec进行提效 )**
A:


## 参考资料
**视频资料**
[Bili_费曼学徒冬瓜_精讲OpenSpec，从操作到原理，吃透这个AI编程提效的神器](【精讲OpenSpec，从操作到原理，吃透这个AI编程提效的神器】 https://www.bilibili.com/video/BV1eU5A6MERk/?share_source=copy_web&vd_source=dc8f2072fd27e51a96ee746a2b28f64a)
