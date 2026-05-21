---
title: 百度面试官：如何赋予 LLM 规划能力？
source: https://mp.weixin.qq.com/s/ltPy7qddnrhaS_KcMcX3ow
author:
  - "[[小林coding]]"
published:
created: 2026-05-16
description:
tags:
  - clippings
---
小林哥 *2026年4月1日 09:36*

👔百度面试官：（推了推眼镜，语气严肃）来，说说核心问题： **如何赋予 LLM 规划能力？**

🙋♂️我：（脑子一懵，瞎凑答案）呃…规划能力？不就是让它多思考一会儿嘛，给它多加点时间，让它慢慢想，就能规划了呗！

👔百度面试官：（语气瞬间拔高，当场怒斥）这叫什么回答？完全没说到点子上！LLM的规划能力是靠具体方法实现的，不是靠“慢慢想”，别瞎糊弄，好好说专业的！

🙋♂️我：（慌得手心冒汗，连忙认错）对不起面试官，我错了！我混淆了思路，现在就结合具体方法，好好跟您说清楚怎么赋予LLM规划能力！

> 面试踩雷预警！瞎答只会被面试官当场怼，这道百度高频真题，核心是吃透CoT、ToT、GoT三种核心方法，下面拆解每种方法的原理、用法和工程选型。

## 💡 简要回答

CoT、ToT、GoT 这三种我都了解过，给 LLM 加规划能力主要靠这几种思路。CoT 是让 LLM 把推理步骤写出来，线性地一步步推导到答案；ToT 是让它同时探索多条推理路径，选最优的继续深入；GoT 是图结构推理，推理节点可以复用和合并，适合更复杂的任务。工程上我用 CoT 最多，因为实现成本最低，就是改个 prompt；ToT 效果更好但调用次数多，成本大概是 3 到 5 倍；GoT 目前还比较学术，生产环境我没见过有人真正落地用的。

## 📝 详细解析

要理解为什么需要规划能力，先看 LLM 在没有任何规划机制时是怎么运作的。

普通的问答模式下，LLM 接到一个问题，就直接「一口气」生成答案，中间没有任何推理过程。这对简单问题没啥大问题，但遇到需要多步推导的任务就很容易翻车。比如让它做一道需要 3 步推导的逻辑题，如果直接让它给答案，出错概率会远高于让它把每步都写出来。

![图片](https://mmbiz.qpic.cn/sz_mmbiz_png/zLRM1IicjS8iaR7UXAHGTpE1QIUCvoj8VBKyOOpML7pHPicMTDYA4tmg3lqfxNvWzzJSJ6ReO1KBgUb4yr7GpZyKZUPzqmwPrF9vEU1Q2J6KcI/640?wx_fmt=png&from=appmsg&watermark=1&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=0)

背后的原因是 Transformer 的 next-token 预测机制，每个 token 是基于前面所有 token 生成的，推理链越长、隐式的跳步越多，误差就越容易在中间某一步悄悄累积，最后给出一个看起来很自信但其实是错的答案。

「规划能力」要解决的就是这个问题：把 LLM 隐式的推理过程显式化，让它不再是「一步跳到答案」，而是「一步一步推到答案」，每步都有迹可循。

CoT、ToT、GoT 是这个方向上依次演进的三种方案，每一个都在解决前一个的局限性。

### CoT：最简单的激活方式，加一句话就够了

CoT 的全称是 Chain of Thought（思维链），核心思路极其简单：在 prompt 里加一句「请一步步思考」，LLM 就会把推理过程逐步写出来，而不是直接蹦出答案。

为什么这么简单的改变就有效？

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

本质是因为 LLM 的输出是顺序生成的，当它先输出推理步骤，这些推理内容会进入上下文，影响下一个 token 的生成。换句话说，「写下来的推理过程」本身就成为了后续生成的依据，帮助 LLM 不跳步、不乱想。就好比你在纸上演算数学题，把每一步写出来之后，下一步出错的概率会比在脑子里算要低得多，原理是一样的。

CoT 有两种触发方式。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

- 第一种叫 Zero-shot CoT，就是直接在 prompt 末尾加「让我们一步步思考」，LLM 自己展开推理，不需要额外例子；
- 第二种叫 Few-shot CoT，给几个带有完整推理过程的例子，让 LLM 模仿这种推理格式来回答新问题，效果通常更稳定。

CoT 的局限很明显：它只有「一条推理路径」。如果一开始走错了方向，整条链就歪了，没有任何纠偏机制。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

### ToT：从「一条链」到「一棵树」，解决走错方向的问题

ToT 的全称是 Tree of Thoughts（思维树），针对的正是 CoT「一旦走错就全错」的问题。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

核心改变是把「生成一条推理链」变成「同时探索多条推理路径，边探索边剪枝，最终选出最优路径」。用一个生活类比来理解：CoT 像你做题时只想了一个解法，一路做到底；ToT 像你先想了三种可能的解题思路，评估了一下哪种最靠谱，选了最好的那条继续深入，另外两条直接放弃。

ToT 的执行流程可以分三步来理解。首先是生成多个候选思路，让 LLM 针对同一个问题给出 3 个不同的初步方向，而不是只走一条路。然后是评估每个思路的可行性，用另一个 LLM 调用（或同一个 LLM 带上评估 prompt）给每个思路打分，判断哪个最有希望。最后是选优继续深入、剪掉差的，只保留分数高的思路，再展开下一层推理，反复循环直到得出最终答案。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

这个「生成 -> 评估 -> 剪枝」的循环，让 LLM 不再是「一条道走到黑」，而是有了探索多条路、选好的走、发现走错了还能回头的能力。代价也很明显：原来 CoT 一次生成就搞定，ToT 需要多次 LLM 调用（多条路径 × 多层深度 × 每层还要评估），成本是 CoT 的 3-5 倍甚至更高。

### GoT：从「树」到「图」，解决推理结果不能复用的问题

GoT 的全称是 Graph of Thoughts（思维图），是在 ToT 基础上再进一步的进化。

![图片](data:image/svg+xml,%3C%3Fxml version='1.0' encoding='UTF-8'%3F%3E%3Csvg width='1px' height='1px' viewBox='0 0 1 1' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'%3E%3Ctitle%3E%3C/title%3E%3Cg stroke='none' stroke-width='1' fill='none' fill-rule='evenodd' fill-opacity='0'%3E%3Cg transform='translate(-249.000000, -126.000000)' fill='%23FFFFFF'%3E%3Crect x='249' y='126' width='1' height='1'%3E%3C/rect%3E%3C/g%3E%3C/g%3E%3C/svg%3E)

ToT 虽然引入了多路径探索，但它是树形结构，不同分支之间完全独立，两条推理路径上的中间结论无法互相借用。

GoT 把推理结构换成了图，允许不同路径的中间结果合并、复用，也就是说一个推理节点可以接收来自多个前置节点的输出作为输入。

举个具体例子：如果任务是「分别研究竞品 A 和竞品 B，然后做综合对比分析」。

ToT 里研究 A 和研究 B 是两条独立的路径，各自得出结论；但「综合对比分析」这一步需要同时用到两条路径的结论，在树形结构里很难自然表达，因为树的每个节点只有一个父节点。

GoT 的图结构允许把「研究 A 的节点」和「研究 B 的节点」的输出，汇聚到「综合对比分析节点」，这种「多个中间结论合并输入到下一步」的操作在图里是一等公民，表达起来非常自然。

GoT 能建模的推理模式比 ToT 更丰富，也更接近人类实际处理复杂任务的思考方式。但落地复杂度很高，目前主要还是学术研究场景，生产环境里极少见到真正用起来的。

### 三者的演进关系

把这三者放在演进视角里看，逻辑非常清晰。

- CoT 解决了「要不要把推理显式化」的问题，答案是要，把过程写出来就能显著减少跳步出错。
- ToT 解决了「走错方向怎么办」的问题，答案是先多探索几条路，边走边评估边剪枝。
- GoT 解决了「不同推理路径的中间结论能不能复用」的问题，答案是把结构从树换成图，自然支持结论汇聚与复用。每一步都是在前一步的基础上发现局限、针对性改进。

工程上怎么选？

- CoT 几乎是所有任务的标配，加一句话、零成本，直接加到 system prompt 里就行。
- ToT 在准确率要求很高、任务比较复杂的场景值得考虑，但要做好调用成本增加 3-5 倍的心理准备。
- GoT 目前工程落地不成熟，主要了解它的思想即可，真实项目里不必强行引入。

推荐阅读：

[美团面试官：“既然大模型已经这么强了，为什么还要做 Agent？”，我给出了满分回答，他眼睛亮了。](https://mp.weixin.qq.com/s?__biz=MzY4NTE2NjU5MQ==&mid=2247483777&idx=1&sn=0fee73150fd3c92d666391a2e0797260&scene=21#wechat_redirect)

[小红书二面秒挂！问“Agent 核心组件有哪些”，我答“大模型+Prompt”，面试官冷笑...](https://mp.weixin.qq.com/s?__biz=MzY4NTE2NjU5MQ==&mid=2247483788&idx=1&sn=45c1ec9d5a578a689d27179f06833b14&scene=21#wechat_redirect)

[腾讯三面面试官刚想拿“Agent和Workflow 的区别”难倒我，我反手甩出一张架构对比图，他当场让我等 HR 面。](https://mp.weixin.qq.com/s?__biz=MzY4NTE2NjU5MQ==&mid=2247483898&idx=1&sn=90101573e94272a1f4ceb6f3b5596758&scene=21#wechat_redirect)

[阿里一面怒怼：“连 Tools、Workflow 和 Agent 三者区别都搞不清，也敢来面试？”，我当场尬住...](https://mp.weixin.qq.com/s?__biz=MzY4NTE2NjU5MQ==&mid=2247483901&idx=1&sn=5825bd451088770c732845c6342d3cc1&scene=21#wechat_redirect)

[快手面试官连环炮：“除了 ReAct，你还知道哪些 Agent 推理范式？”，还在死磕 Prompt 的我愣住了...](https://mp.weixin.qq.com/s?__biz=MzY4NTE2NjU5MQ==&mid=2247483902&idx=1&sn=0cf5ac123f30b3da3108a988811dff5a&scene=21#wechat_redirect)

[字节面试官：“Plan-and-Execute 比 ReAct 强在哪？”，我：“名字比较长，显得更高级？”，面试官：“门在那边，走好。”](https://mp.weixin.qq.com/s?__biz=MzY4NTE2NjU5MQ==&mid=2247483916&idx=1&sn=bf4830ee91d928a47a3e7124bb5bf174&scene=21#wechat_redirect)

[蚂蚁一面：“复杂任务怎么做拆解？”，我：“大模型上下文都 200 万了，直接全塞进去硬算啊”，面试官：“回去等通知吧。”](https://mp.weixin.qq.com/s?__biz=MzY4NTE2NjU5MQ==&mid=2247483931&idx=1&sn=32eaad0357bd0de5482cee788f940a64&scene=21#wechat_redirect)

[淘天面试官：你知道 Agent 的记忆机制吗？](https://mp.weixin.qq.com/s?__biz=MzY4NTE2NjU5MQ==&mid=2247484016&idx=1&sn=f7259c5c56ab87cdea2e1fd43f132240&scene=21#wechat_redirect)

[鹅厂面试官：Agent 的长短期记忆系统怎么做的？](https://mp.weixin.qq.com/s?__biz=MzY4NTE2NjU5MQ==&mid=2247484017&idx=1&sn=922dc203cf47c6d3f784cfd288955d8a&scene=21#wechat_redirect)

[京东面试官：单体 Agent 遇到瓶颈，Multi-Agent 方案怎么设计？](https://mp.weixin.qq.com/s?__biz=MzY4NTE2NjU5MQ==&mid=2247484019&idx=1&sn=df6eb76db9b88f3eb752766d10e03dc7&scene=21#wechat_redirect)

[腾讯面试官：Agent 记忆压缩通常有哪些方法？](https://mp.weixin.qq.com/s?__biz=MzY4NTE2NjU5MQ==&mid=2247484020&idx=1&sn=35116498bdcaf5d3584e6255e16184ca&scene=21#wechat_redirect)

AI Agent面试题 · 目录

阅读原文

继续滑动看下一个

小林面试笔记

向上滑动看下一个