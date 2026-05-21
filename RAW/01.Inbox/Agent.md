



~~~
Q1:Agent架构包括哪些部分?


A:
教科书答案-7大组件:1.感知与输入处理 2.推理引擎 3.记忆系统 4.工具使用 5.编排与状态管理 6.Mutli-Agent协作 7.安全与治理

2.推理引擎:ReAct 与Plan-and-Execute

核心架构:while+tool call(模型调用+工具列表, 有tool call就执行, 没有就结束循环)
ReAct = loop +显式思考步骤
Plan-and-Execute ->生产中是使用todo文件做"软规划"->在生产中并非严格的先规划再执行
Reflection/ToT = 可选增强,非基础架构

Agent的实现往往很简单---就是LLM在循环中基于反馈调用工具
最成功的实现不用复杂框架,而是用最简单的可组合的模型

Loop虽然简单,但是真正决定Agent好坏的是工程细节,工具怎么编排,上下文怎么设计/管理.


工具设计五大原则:1.选对工具(为Agent重新设计) 2.命名空间化 3.返回语义化信息(name而非uuid) 4.优化Token效率 5.精心编写工具描述(最有效方法之一) Manus不删工具->保护KV cache 而是在解码时使用logit masking遮蔽不可用工具的Token-->前缀预填

~~~



~~~
Q2:如何设计Agent上下文维护方案?

A:
为什么不能简单压缩? -> 因为Context Rot:
Context越长,会导致所有模型都会变蠢 只要还是Transformer架构就绕不过去
1.context越长 -> attention budget 被越多token稀释
2.Transformer架构的数学必然(n**2) -> 每个token要跟其他token算关系


四象限 + Conpress横评 + 三阵营 + 4层防御

本质：有限 attention budget 维持 coherence
框架：Write / Select / Compress / Isolate（LangChain）
优先级（综合实践）：Select > Write > Compress > Isolate
2026 信号：Agent Skills / Letta Context Repositories / Graphiti / Task Budgets


~~~




~~~
Q3:线上Agent翻车了,怎么查根因?


A:
传统开发的Bug是崩给你看,LLM的Bug是给错答案.
这种没有报错日志的场景是最难受的...

1.分类:分四桶 Triage
	Reliability: TTFT尖峰,JSON错,provider 429
	Quality: 幻觉,RAG没召回,lost in middle
	Safety: jailbreak,PII,越权调用
	Cost: retry放大,token爆炸
	成本和延迟看TPM限流,Cost,KV cache命中率.安全看guardrail日志
	
2.定位:定位到span
最先遇到的错才是根因.

Drill顺序(不可乱):
1.实际Prompt -> 2.retrieved docs -> 3.原始model output -> 4.tool call args/result -> 5.finish_reason
3.复现:

4.修:

5.防回归:
~~~

~~~
Q4:Agent有几种类型


A:
这个要看分类的出发点/分类维度了,按编排架构,决策行为,应用角色
最实用的分类是Anthropic三层架构分类:
1.Augmented LLM(LLM+检索+工具+记忆)
2.Work
~~~
