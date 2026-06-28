# CC_runtime_08.Prompt 详解---直接控制 query_loop 行为的四段 Prompt

> 前面几篇我们已经把 system prompt 的拼装流程和 `query_loop` 的代码结构拆开看过了。这一篇换一个角度：不是“代码怎么驱动 prompt”，而是“prompt 怎么反过来约束代码里的循环行为”。
>
> 在 Claude Code 的运行链路里，有几段 prompt 并不是在定义模型“是什么”，而是在约束模型“在 loop 里应该怎么做事”。这四段 prompt 分别作用在不同阶段，但组合起来，几乎直接控制了 `query_loop` 的整体行为边界。

## 1. 先把六个阶段和四段 Prompt 对上

从 `query_loop` 的执行过程看，可以先粗分成 6 个阶段：

```text
Phase 1  消息准备
  -> 如果接近上下文上限，触发 compact
  -> 这里受 COMPACT_SYSTEM_PROMPT 影响

Phase 2  模型调用
  -> 模型拿到 system prompt 和 messages，决定“怎么做任务”
  -> 这里最核心的是 doing_tasks

Phase 3  错误恢复
  -> 如果调用失败、解析失败或工具异常，代码层负责恢复
  -> 这一层没有独立 prompt，主要是代码逻辑

Phase 4  构建消息
  -> 把工具结果重新组织回消息流
  -> 这里 SUMMARIZE_TOOL_RESULTS 会提醒模型“记下关键信息”

Phase 5  工具执行
  -> 真正执行工具
  -> 这一层更多受工具定义和工具提示影响，放到后续章节看

Phase 6  循环 / 返回
  -> 判断是继续循环、重试，还是结束返回
  -> 这里 again 会被 doing_tasks 里的行为规则间接影响
```

这一篇重点看四段：

- `get_doing_tasks_section()`：直接约束“怎么做任务”
- `COMPACT_SYSTEM_PROMPT`：约束“压缩时保留什么”
- `SUMMARIZE_TOOL_RESULTS`：约束“工具结果要不要先写回响应里”
- `DEFAULT_AGENT_PROMPT`：约束“子 Agent 用什么精简行为规则”

它们共同决定的不是模型知识，而是 loop 里的行为方式。

## 2. `get_doing_tasks_section()`：任务执行的行为边界

源码位置：`cc/prompts/sections.py:66-86`

这段 prompt 是主 system prompt 里非常关键的一块。它主要作用在：

- Phase 2：模型刚拿到任务，决定采用什么执行策略
- Phase 6：模型在一轮工具执行后，决定继续、诊断、收敛，还是结束

### 2.1 英文原文

```text
You should:
- Act as a software engineering assistant working on a codebase.
- Interpret ambiguous instructions in the most sensible engineering context.
- Read relevant code before proposing or making changes.
- Prefer editing existing files over creating new ones unless a new file is necessary.
- Avoid giving time estimates.
- If an approach fails, diagnose why before switching tactics.
- Be careful not to introduce security vulnerabilities, including command injection, XSS, SQL injection, or other OWASP Top 10 style issues.
- Don't add features, refactors, or improvements beyond what the user asked for.
- Don't add docstrings, comments, or type annotations to code that doesn't need to be touched for the task.
- Don't add error handling, fallbacks, or validation for impossible scenarios; trust internal guarantees and validate at system boundaries.
- Don't use feature flags or backward-compatibility shims when the code can just be changed directly.
- Don't create helpers, utilities, or abstractions for one-off operations; don't design for hypothetical future needs.
- Avoid backward-compatibility hacks such as renaming unused vars, re-exporting types, or restoring removed comments unless they are actually required.

If the user is asking for help or feedback:
- /help
- report issue at https://github.com/anthropics/claude-code/issues
```

### 2.2 中文翻译

可把这段理解成一组“工程行为准则”：

- 你是一个在代码库里工作的软件工程助手
- 遇到模糊指令，要按最合理的工程语境理解
- 在提建议或改代码前，先读相关代码
- 除非确实需要，否则优先修改已有文件，而不是新建文件
- 不要随便给时间预估
- 如果当前方法失败，先诊断原因，再切换路线
- 注意不要引入安全漏洞，比如命令注入、XSS、SQL 注入，以及 OWASP Top 10 一类问题
- 不要顺手加需求外功能、额外重构或“顺便优化”
- 不要给没必要改动的代码顺手补 docstring、注释、类型标注
- 不要为了不可能发生的场景补一堆 fallback、校验、错误处理；内部链路信任内部保证，边界处再做校验
- 如果代码能直接改，就不要上 feature flag 或兼容垫片
- 一次性操作不要抽 helper / utility / abstraction，也不要为假想未来过度设计
- 避免做兼容性小动作，比如改未使用变量名、重新导出类型、补回旧注释，除非任务真的需要

如果用户是在问帮助或反馈渠道，则提示：

- `/help`
- 到 `https://github.com/anthropics/claude-code/issues` 提 issue

### 2.3 逐条分析

这组规则大致可以分成四层：

#### 2.3.1 操作纪律

- 先读代码，再提方案
- 优先改老文件，不轻易起新文件
- 模糊需求按工程上下文理解
- 不乱给时间预估
- 不扩任务边界

这一层的意义是：让模型像一个真正进仓库做事的工程师，而不是像一个空口给建议的聊天机器人。

#### 2.3.2 失败策略

“方案失败先诊断，再切换策略”这一条非常关键。

它会直接影响 `query_loop` 在多轮中的风格：不是一失败就换一个完全不同的方法，而是先把失败原因说清楚，再决定下一步。这会让 loop 更稳定，也更像真实排障过程。

#### 2.3.3 安全底线

把命令注入、XSS、SQL 注入、OWASP Top 10 明确写进 prompt，等于在代码生成前先给模型套上一层最低安全边界。

这不是完整安全体系，但它会直接影响模型在改代码时的默认警觉性。

#### 2.3.4 复杂度控制

后半段大量规则都在压制“过度工程”：

- 不顺手重构
- 不补无关注释 / 类型
- 不加假设性 fallback
- 不搞 feature flag
- 不为一次性事情抽象
- 不做假兼容

这说明 Claude Code 的设计目标不是“生成看起来很完美的工程作品”，而是“在当前任务边界内完成必要改动”。

### 2.4 这些规则的本质

`doing_tasks` 本质上在做三件事：

1. 给模型设定工程人格
2. 给模型划定复杂度上限
3. 给模型规定失败后的诊断路径

所以它不是一般意义上的“风格提示”，而是主 loop 的行为约束器。

## 3. `COMPACT_SYSTEM_PROMPT`：压缩时到底保留什么

源码位置：`cc/compact/compact.py:42-49`

这段 prompt 在平时不直接参与每轮任务，但一旦上下文接近上限、`should_auto_compact()` 被触发，它就立刻变成关键角色。

也就是说，它主要作用在 Phase 1。

### 3.1 英文原文

```text
Preserve:
- Key decisions and outcomes
- Important file paths, function names, and code changes
- Current state of the task
- Any unresolved issues or next steps

Be factual and specific. Include exact file paths, line numbers, and code identifiers where useful.
Do not editorialize or add opinions.
Output only the summary text.
```

### 3.2 中文翻译

压缩总结时，必须保留：

- 关键决策和结果
- 重要文件路径、函数名、代码改动
- 当前任务进行到了什么状态
- 还没解决的问题，以及下一步要做什么

而且：

- 必须客观、具体
- 能写精确路径、行号、代码标识符时，就尽量写精确
- 不要夹带评论和主观看法
- 输出只保留摘要正文

### 3.3 逐项分析

#### 3.3.1 为什么强调“关键决策和结果”

因为 compact 不是普通摘要，它承担的是“旧上下文被清掉以后，模型还能不能继续干活”的职责。

如果只写“前面讨论了数据库配置”，那几乎没用；真正有用的是“已经决定使用 PostgreSQL，连接参数在某文件里，并且某方案被否决了”。

#### 3.3.2 为什么要保留精确路径、函数名、代码改动

路径和标识符是后续续接工作的锚点。

例如：

- 文件路径告诉模型去哪里继续看
- 函数名告诉模型应该从哪个实现点接上
- 具体改动告诉模型哪些地方已经动过，哪些不要重复做

所以这里强调“exact file paths, line numbers, and code identifiers”，本质上是在保留可执行上下文，而不是保留聊天纪要。

#### 3.3.3 为什么“当前状态”必须写清

如果只保留历史结论，不保留“当前做到哪一步”，那压缩后模型会丢失工作进度感。

比如：

- 已经写完但没验证
- 已经定位到 bug 但还没修
- 已经生成部分文档但仍待补图

这些都属于“当前状态”，少了它，模型就很容易重复劳动或者在错误阶段继续推进。

#### 3.3.4 为什么“未解决问题 / 下一步”也必须保留

因为压缩的目标不是复盘，而是续跑。

如果 unresolved issues 和 next steps 丢了，压缩后虽然知道“做过什么”，但不知道“接下来该做什么”。

### 3.4 压缩质量为什么重要

在 `compact.py` 里，近期几轮原始消息会被保留，但更早的上下文会依赖 compact 结果继续存活。截图里提到一个关键细节：

```text
POST_COMPACT_KEEP_TURNS = 4
```

这意味着：压缩后的摘要质量，直接决定 4 轮之前的大部分上下文还能否被继承。

如果这个 summary 写虚了，后面的 loop 再聪明也只能在坏记忆上继续跑。

## 4. `SUMMARIZE_TOOL_RESULTS`：上下文丢失前的前置保险

源码位置：`cc/prompts/sections.py:162`

这是一条非常短的 prompt，但作用非常关键。它主要影响的是 Phase 4，也就是“工具结果回写消息流”的时候。

### 4.1 英文原文

```text
When working with tool results, write down any important information you might need later in your response, as the original tool result may be cleared later.
```

### 4.2 中文翻译

当你处理工具结果时，把后面可能还需要的重要信息先写进你的回复里，因为原始工具结果之后可能会被清掉。

### 4.3 为什么需要这条

工具输出天然是“易失”的。

模型看过工具结果，不代表这些结果会永久留在上下文里。后续一旦 compact，或者消息被裁剪，原始工具结果就可能消失。

所以这条 prompt 的目的不是让模型重复工具输出，而是让它主动把“未来还要用的信息”抽出来，写进更持久的 assistant 响应。

例如：

错误写法：

```text
我已经看过配置文件了。
```

更对的写法：

```text
我确认配置里使用的是 PostgreSQL，database.host = localhost:5432，pool_size = 10。
```

这样即使原始工具结果没了，关键信息也还留在对话文本里。

### 4.4 这是一个 meta-prompt

这条 prompt 不是在告诉模型“怎么完成任务”，而是在提醒模型：

- 工具结果不一定可靠持久
- 要主动把关键结果写回响应
- 回答不只是给用户看，也是在给未来轮次留记忆

所以它更像一个“上下文保全提醒器”。

### 4.5 与 `COMPACT_SYSTEM_PROMPT` 的互补关系

这两者刚好是一前一后两层保险：

- `SUMMARIZE_TOOL_RESULTS`：前置防线，先把重要信息写进 assistant 文本
- `COMPACT_SYSTEM_PROMPT`：后置防线，在压缩时把这些信息保留下来

前者解决“别让关键信息只存在于 tool result 里”，后者解决“压缩时别把已经写出来的关键信息再丢掉”。

理想状态是两层都生效。

## 5. `DEFAULT_AGENT_PROMPT`：子 Agent 的精简版指令

源码位置：`cc/prompts/sections.py:35`

这段 prompt 不属于主 Agent 的完整 system prompt，而是专门给 AgentTool 拉起的子 Agent 使用。

### 5.1 英文原文

```text
You are an agent for Claude Code, Anthropic's official CLI for Claude. Given the user's message,
you should use the tools available to complete the task. Complete the task fully - don't gold-plate,
but don't leave it half-done. When you complete the task, respond with a concise report covering
what was done and any key findings - the caller will relay this to the user, so it only needs the essentials.
```

### 5.2 中文翻译

你是 Claude Code 的一个 agent。拿到用户消息后，应该使用手头可用的工具来完成任务。

任务要做完整，但不要过度发挥；也不要做一半就停。

完成后，要返回一份简洁报告，说明做了什么、发现了什么重点。因为这份结果还会由调用方转述给用户，所以只保留最必要的信息即可。

### 5.3 与主 system prompt 的对比

主 Agent 的 system prompt 是拼装出来的一整套结构，截图里提到 builder 侧大致会包含 11 段内容，例如：

- `Intro`
- `System`
- `Doing tasks`
- `Actions`
- `Using tools`
- `Tone and style`
- `Output efficiency`
- `Environment`
- `SUMMARIZE_TOOL_RESULTS`
- `Memory`
- `CLAUDE.md`

整体量级是数千 token。

而子 Agent 的 `DEFAULT_AGENT_PROMPT` 明显被大幅压缩了，没有把这些都完整带进去。

截图中明确点到，子 Agent 省掉的内容包括：

- Memory 系统相关指令
- `CLAUDE.md` 级别的项目约束
- Actions / 风险评估一类规则
- 完整的输出格式约束

### 5.4 关键分析

这一小段 prompt 里，每句都很有针对性：

#### 5.4.1 `Complete the task fully`

给子 Agent 设定了完成度下限：不能只做一半，也不能只做分析不落地。

#### 5.4.2 `don't gold-plate`

给子 Agent 设定了复杂度上限：不要超出子任务边界做花活。

#### 5.4.3 `but don't leave it half-done`

这是在“别过度工程”和“别半拉子工程”之间画平衡线。

#### 5.4.4 `respond with a concise report`

子 Agent 的输出不是直接面向最终用户，而是面向父 Agent。

所以重点不是优美叙述，而是：

- 做了什么
- 发现了什么
- 有没有关键结论

### 5.5 为什么子 Agent 用精简版

主要有两个原因：

#### 5.5.1 token 效率

如果每个子 Agent 都继承主 Agent 的完整 prompt，成本会非常高。

#### 5.5.2 子任务通常更窄

子 Agent 处理的是一个被拆出来的局部任务，不需要完整继承主 Agent 的所有行为层、记忆层和项目层约束。

所以这里的设计不是“功能缩水”，而是“把最小可用行为规则抽出来”。

## 6. 四段 Prompt 的协作关系

把它们串起来看，会发现这四段 prompt 几乎覆盖了 `query_loop` 里最核心的行为控制面：

1. 模型第一次决定怎么做任务时，先受 `doing_tasks` 约束  
   它决定默认工程姿态、复杂度边界、失败后的诊断方式。

2. 工具执行完以后，`SUMMARIZE_TOOL_RESULTS` 会提醒模型把关键结果先写进响应  
   这样重要信息不会只停留在工具输出里。

3. 当 token 接近上限时，`COMPACT_SYSTEM_PROMPT` 再接手  
   它决定压缩后哪些信息能继续活下来。

4. 如果主 Agent 通过 AgentTool 拆出子任务，子 Agent 则运行在 `DEFAULT_AGENT_PROMPT` 下  
   它保证子任务能以较低成本、较稳定的方式完成。

所以这四段 prompt 分别在管：

- 怎么干活：`doing_tasks`
- 怎么保上下文：`SUMMARIZE_TOOL_RESULTS` + `COMPACT_SYSTEM_PROMPT`
- 怎么拆子任务：`DEFAULT_AGENT_PROMPT`

少任何一段，loop 的稳定性都会下降：

- 没有 `doing_tasks`，任务行为会发散
- 没有 `SUMMARIZE_TOOL_RESULTS`，工具关键信息容易蒸发
- 没有 `COMPACT_SYSTEM_PROMPT`，压缩后上下文会失真
- 没有 `DEFAULT_AGENT_PROMPT`，子 Agent 成本和行为都更难控

## 7. 结论

这四段 prompt 看起来都不长，但它们控制的其实不是“语言风格”，而是 `query_loop` 的运行习惯：

- 任务如何起手
- 失败后如何诊断
- 工具结果如何沉淀
- 上下文如何跨压缩保活
- 子 Agent 如何低成本执行

从这个角度看，Claude Code 不是先有 loop 再随便塞几个 prompt，而是把 prompt 当成 loop 的行为约束层来设计的。

## 8. OCR 不确定处

- `get_doing_tasks_section()` 的英文原文在截图中分布在两张图里，个别标点和首句措辞可能存在轻微 OCR 偏差，但条目含义清晰。
- `COMPACT_SYSTEM_PROMPT` 的英文原文截图没有完整拍全，当前版本按可见内容重建了核心保留项与约束语义。
- `DEFAULT_AGENT_PROMPT` 英文原文为两张截图拼接，内容主体清晰，换行位置可能与源码略有不同。
- 本篇没有使用 Mermaid；截图内容以 prompt 原文、分段分析和代码位置说明为主，Markdown 表达更稳。
