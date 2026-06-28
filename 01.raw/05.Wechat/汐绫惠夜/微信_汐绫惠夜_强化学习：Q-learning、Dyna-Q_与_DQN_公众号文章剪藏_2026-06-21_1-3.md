---
title: "微信_汐绫惠夜_强化学习：Q-learning、Dyna-Q 与 DQN_公众号文章剪藏_2026-06-21_1-3"
source: "/api/v1/wechat_mp/web/fetch_mp_article_detail_html"
author:
  - "汐绫惠夜"
published: "2026-06-02"
created: 2026-06-21
description: "TikHub 命中的微信公众号文章候选，共 3 条，本文档收录 3 条"
tags:
  - "clippings"
  - "wechat"
  - "汐绫惠夜"
---

## 0x01. 十二：强化学习：Q-learning、Dyna-Q 与 DQN
> 发布日期：2026-06-02  
> 原文链接：[十二：强化学习：Q-learning、Dyna-Q 与 DQN](https://mp.weixin.qq.com/s/aItWi7Qosf4p6YjczDLgaw)

### 1. 学习定位
 第十一天已经学习了 Sarsa 与多步 Sarsa。第十二天继续强化学习值函数方法，从表格型 Q-learning 过渡到函数近似，再进入 DQN(Deep Q-Network)。

 本日知识链路：
```javascript
Sarsa: on-policy TD control
-> Q-learning: off-policy TD control
-> Dyna-Q: real experience + learned model planning
-> function approximation: 用参数模型近似 Q(s,a)
-> DQN: 用深度神经网络近似 Q 函数
-> experience replay + target network 稳定训练
-> Double DQN / Dueling DQN / PER / Rainbow 等改进
```
DQN 是深度强化学习的标志性方法之一。面试中通常不会只问“公式是什么”，还会追问：为什么直接把 Q-learning 接上神经网络会不稳定，experience replay 和 target network 分别解决什么问题，DQN 的输入输出怎么设计，以及 Double DQN、Dueling DQN、优先经验回放等改进的动机。

### 2. Q-learning
 Q-learning 是 off-policy TD control。它用行为策略采样数据，但学习目标是贪心目标策略。

 更新公式：
```text
Q(S_t,A_t) <- Q(S_t,A_t)
  + alpha [R_{t+1} + gamma max_a Q(S_{t+1},a) - Q(S_t,A_t)]
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkg3AsNFa1eBRNDNqBCG8UKLaIz4NiavnhFHIiaXGnicdYkhI7k8TcjApmS8z0Kr6mGb0CticOetNFSmQ24r8y3NY55SIzJZbhWn6eQ/640?wx_fmt=png&from=appmsg)
 TD target：
```text
y_t = R_{t+1} + gamma max_a Q(S_{t+1},a)
```
TD error：
```text
delta_t = y_t - Q(S_t,A_t)
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkjE04weM8ibyGkKty9UKRciasRNNMDZoZoUdMUBEd19NZCHJlVCRooR1XbfXyMGgJ3qaIQ9ibhmO9hUicicEeVgvkFmnbhIJziblSCuA/640?wx_fmt=png&from=appmsg)
 Sarsa 与 Q-learning 的关键区别：
```text
Sarsa target:
  R + gamma Q(S', A')
  A' 是行为策略实际采样动作

Q-learning target:
  R + gamma max_a Q(S', a)
  使用下一状态的贪心动作
```
因此 Sarsa 是 on-policy，Q-learning 是 off-policy。

| 算法 | TD 目标形式 | 下一动作来源 | 策略类型 | 特点 |
| :--- | :--- | :--- | :--- | :--- |
| Sarsa | R + γ Q ( S ′ , A ′ ) | 实际采样 A ′ | on-policy | 保守、规避危险路径 |
| Q-learning | R + γ max a Q ( S ′ , a ) | 全局最优贪心动作 | off-policy | 激进，直接学最优策略 |

### 3. Dyna-Q 的基本思想
 Dyna-Q 把 model-free learning 和 model-based planning 结合起来。智能体每次真实交互后，做两件事：
```text
1. 用真实 transition 更新 Q。
2. 用真实 transition 更新环境模型。
3. 从模型中采样过去的 state-action，生成模拟 transition，再额外更新 Q。
```
简化流程：
```text
observe real transition (S,A,R,S')
Q-learning update using real transition
Model(S,A) <- (R,S')

repeat n times:
  sample previously observed (S,A)
  get simulated (R,S') from Model
  Q-learning update using simulated transition
```
Dyna-Q 的意义是：真实环境交互昂贵时，利用学习到的模型做 planning，提高样本效率。

- **真实交互更新 Q 和模型**
- **模型生成虚拟经验加速学习** ### 4. 表格方法(代表算法：Q-learning、Sarsa、Dyna-Q)的局限

 表格型方法为每个状态动作对存一个数：
```text
Q table shape = [num_states, num_actions]
```
局限：

 状态空间巨大时无法存储。

 连续状态无法直接查表。

 从未访问过的状态动作对没有泛化能力。

 图像、文本、传感器数据等高维观测不能直接作为表格索引。

 因此需要函数近似：
```text
Q(s,a) ≈ Q(s,a; w)
```
其中 w 是可学习参数，可以是线性模型、决策树、神经网络或深度网络。

### 5. 函数近似的 Q 学习
 用参数模型近似 Q 函数后，一次 TD 更新可以写成监督学习形式：
```text
target y = r + gamma max_a' Q(s',a'; w)
prediction = Q(s,a; w)
loss = 1/2 * (y - prediction)^2
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkia0kicTnW71uL5ZyGJtAGp5SHGEvBVqBbu1W7oqwNLzfHwcEOAEesK6WyORgNoicF1VFtiaSxSyWueMmwPw054x1dib87c2eNkFIA4/640?wx_fmt=png&from=appmsg)
 半梯度更新：
```text
w <- w + alpha [y - Q(s,a;w)] grad_w Q(s,a;w)
```
称为 semi-gradient，是因为 target 里也含有当前参数 w，但更新时通常只对 prediction 求梯度，不对 target 反传。
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkgbEMDsV1u5glJj0iagicIPuonU3nicJ1bq5vQrcIXFlR8ZkXS82D7nufwdcicpay1iaSckZSITJmh17zsjNFaicvQKAGdibpaFRqSwg8/640?wx_fmt=png&from=appmsg)
 函数近似带来泛化能力，但也带来不稳定性。尤其是 off-policy、bootstrapping、function approximation 同时出现时，训练可能发散，这被称为 deadly triad。

### 6. DQN 的核心定义
 DQN 用深度神经网络近似动作价值函数：
```text
Q(s,a; theta)
```
经典 Atari DQN 中：
```yaml
input:
  多帧游戏画面堆叠，例如 84 x 84 x 4

network:
  CNN feature extractor + MLP

output:
  每个离散动作对应一个 Q 值
  shape = [num_actions]
```
DQN 适合离散动作空间。如果动作连续，不能直接对所有动作取 max_a Q(s,a)，通常需要 DDPG、SAC 等连续控制算法。

### 7. DQN 损失函数
 DQN 的目标是最小化 TD target 和当前 Q 预测之间的差。

 使用 target network theta^- 时：
```text
y = r + gamma * max_a' Q(s', a'; theta^-)
```
如果 done=True：
```text
y = r
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkhSOibhMiaAQmv6HQub4aXrCx4iaILbveLnvwUFHEFLBVWEicmxu8KhJ6PCvKH8afuyDJPlk0iagfoEBKKGNDkztTmXhoX4PZu5A6Oc/640?wx_fmt=png&from=appmsg)
 损失函数：
```text
L(theta) = E[(y - Q(s,a;theta))^2]
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkhXgNVpGHibdJw5pBLSAxbyX9AIKwQJdF9icnjKKRiaH3wwK8hqGrhCmDU6DcHCYSicugr7fN7rgfVonQEFf57K7iaC7SicibWruFFp8s/640?wx_fmt=png&from=appmsg)
 这就是 **均方误差损失(MSE)**。 常用 Huber loss 替代 MSE，以降低异常 TD error 对训练的冲击。

### 8. Experience Replay经验回放
 Experience replay 维护一个 replay buffer：
```text
D = {(s,a,r,s',done)}
```
每次和环境交互得到的经验 **先存起来**， 训练时不只用最新 transition，而是从 buffer 中随机采样 minibatch 更新网络。

 作用：

 打破连续样本之间的强相关性。

 提高样本利用率。

 让训练数据分布更平滑。

 Replay buffer 也有代价：样本可能过旧，off-policy 偏差更明显；buffer 太小会相关性强，太大可能包含过时策略数据。

### 9. Target Network
 如果 target 和 prediction 都使用同一个网络，target 会随着参数更新同时移动，训练容易震荡：
```text
y = r + gamma max_a' Q(s',a';theta)
```
DQN 使用 target network：
```text
online network: theta
target network: theta^-
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkia4BNePWFALpic6KvmRGbOYecuUiaibibOWSRcjKib8TFdX8EHlKRgkJ40mFWV5KkCPK8rXvySWic0pOYy4VfeqUYTYVmNFVsKDOQYUE/640?wx_fmt=png&from=appmsg)
 target network 每隔若干步从 online network 复制参数：
```text
theta^- <- theta
```
或者使用 soft update：
```text
theta^- <- tau theta + (1 - tau) theta^-
```
作用是让 TD target 更稳定。

### 10. DQN 训练流程
 典型流程：
```text
initialize online Q network theta
initialize target Q network theta^- = theta
initialize replay buffer D

for each environment step:
  choose action using epsilon-greedy(Q_theta)
  execute action, observe r, s', done
  store (s,a,r,s',done) in D

  sample minibatch from D
  y = r + gamma *(1-done)* max_a' Q(s',a';theta^-)
  minimize loss (y - Q(s,a;theta))^2

  periodically update theta^- <- theta
```
实际训练还会使用 frame stacking、reward clipping、gradient clipping、learning rate schedule、epsilon schedule 等工程设置。

### 11. DQN 与监督学习的关系
 DQN 的单步更新看起来像监督学习：
```yaml
input: state s
label: TD target y
prediction: Q(s,a;theta)
loss: prediction 与 y 的差
```
但它不是普通监督学习，原因是：

 label 是 bootstrap target，由模型自身估计生成。

 数据分布由当前策略和 replay buffer 决定。

 target 会随参数和策略变化而变化。

 探索策略会影响训练数据覆盖。

 因此 DQN 的训练稳定性比普通监督学习更敏感。

### 12. Double DQN
 标准 DQN 的 target 使用同一个 target network 完成动作选择和动作评估：
```text
y = r + gamma max_a Q(s',a;theta^-)
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkgEjjK492F7DBlbBR55ZpPAS9IaRWOsEdZO9NQ9FycnSxx3jnsa2SCoXWeS6Y79e4J2396xuJ3mu6SlGuQW891RpNdWtESfOVI/640?wx_fmt=png&from=appmsg)
 max 操作容易带来过估计，因为噪声较大的动作可能被选中。

 Double DQN 解耦动作选择和动作评估：
```text
a* = argmax_a Q(s',a;theta)
y = r + gamma Q(s',a*;theta^-)
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkiahmmfaicDfnfVKVVv2IqGTWtmXp1Pz7ib0XLeULjApbwvViaetOn0lrO9vyws1E1sBcMsFI8xxKmzZMthH5kJePzozTVDTSvmzBs/640?wx_fmt=png&from=appmsg)
 online network 选择动作，target network 评估该动作，从而缓解 Q 值过估计。

### 13. Dueling DQN
 Dueling DQN 把 Q 值拆成状态价值和优势函数：
```text
Q(s,a) = V(s) + A(s,a)
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkg0NYMHKak6mXibGuSuuicT3DpSt1LT1icCN55o6KGogVMlcdIczAUGD8FFsFV7UBKicwwicOzxDYvvxkbicicImcxKa4QjnyIBvBbsDs/640?wx_fmt=png&from=appmsg)
 为了避免 V 和 A 不可辨识，常用聚合方式：
```text
Q(s,a) = V(s) + A(s,a) - mean_a A(s,a)
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkjahqJIc9h1YJRBQulAYtSa01tt1cp8pgw07Kfj4CtXCvxg0acB9vrxoDWm0g7vmDoqiaXHbm2wicqcd86SQz9AtFd8eISRlIPlM/640?wx_fmt=png&from=appmsg)
 直觉：在很多状态下，知道“这个状态整体好不好”比精细区分每个动作更重要。Dueling 结构可以更有效地学习状态价值，尤其在动作之间差异不明显时有帮助。

### 14. Prioritized Experience Replay PER 优先回放
 普通 replay buffer 均匀采样。Prioritized Experience Replay(PER)让 TD error 大的样本更可能被采样：
```text
p_i ∝ |delta_i| + epsilon
P(i) = p_i^alpha / sum_k p_k^alpha
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkjiaGNR0ykT0RPBmjRaQDWb6MLUGkC8HV6c2syGEODGMXoloJmdEyaMIN3tJKE3By8ibB0OaPwvTibEZyQuJPNhPvta5Q4mgz4I40/640?wx_fmt=png&from=appmsg)
 为了修正非均匀采样带来的偏差，使用 importance sampling weight：
```text
w_i = (1 / (N * P(i)))^beta
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkjR2eXntwHriaEaXrHBPgEEYOrBL90wlzcfFwEGnyCxQFwsOPicibfekBM5BLKJlqBrBL8uYYM5ibiauGXxziaqBjlzhYzic9rT5kwS1g/640?wx_fmt=png&from=appmsg)
 PER 能更频繁学习“当前模型误差大”的样本，但也可能放大噪声样本。

### 15. Rainbow DQN 的常见组件
 Rainbow DQN 把多种 DQN 改进组合起来：

 Double DQN：减少过估计。

 Dueling network：分离状态价值和优势。

 Prioritized replay：优先学习高 TD error 样本。

 Multi-step return：加快奖励传播。

 Distributional RL：学习回报分布而不只是期望。

 Noisy Nets：用参数噪声改进探索。

 面试中不一定要推导 Rainbow，但要能说出每个组件解决的问题。

### 16. 实现细节与排错
 常见实现要点：
```text
Q_values = q_net(states)             # [batch, num_actions]
Q_sa = Q_values.gather(1, actions)   # [batch, 1]

with no_grad:
  next_Q = target_net(next_states).max(dim=1)
  y = rewards + gamma *(1-dones)* next_Q
```
容易出错的地方：

- done=True
 时没有去掉 bootstrap。

- actions
 shape 不对， gather 取错维度。

 target network 没有冻结梯度。

 replay buffer 初始样本太少就训练。

 epsilon 衰减过快导致探索不足。

 Q 值尺度爆炸导致 loss 不稳定。

 evaluation 时仍然使用高 epsilon。

### 17. DQN 的局限
 DQN 的局限包括：

 主要适合离散动作空间。

 对超参数和奖励尺度敏感。

 样本效率仍然不高。

 off-policy + bootstrapping + function approximation 组合可能不稳定。

 对部分可观测任务，需要帧堆叠、RNN 或记忆机制。

 在复杂文本/Agent 场景中，动作空间和状态空间远超 Atari。

### 18. 与 LLM、RLHF、Agent 的联系
 DQN 本身不是 LLM RLHF 的主流算法，但它提供了重要思想：

 用神经网络近似价值函数。

 用 replay buffer 提高样本利用率。

 用 target network 稳定 bootstrap target。

 用 Double/Dueling/PER 等技术处理估计偏差和训练效率。

 在 Agent 场景中，如果高层动作是有限工具集合，理论上可以用 DQN 类方法学习工具选择策略。但真实系统通常还要处理巨大状态、非平稳用户、稀疏奖励和安全约束。

### 19. 核心总结
 第十二天需要掌握的最小闭环：
```yaml
Q-learning:
  target = r + gamma max_a Q(s',a)
  off-policy TD control

Dyna-Q:
  real experience update + learned model planning update

Function Approximation:
  Q(s,a) ≈ Q(s,a;theta)

DQN:
  neural network approximates Q
  output one Q value per discrete action
  loss = TD target - Q prediction

Stabilization:
  experience replay: reduce sample correlation, reuse data
  target network: stabilize bootstrap target

Improvements:
  Double DQN: reduce overestimation
  Dueling DQN: V/A decomposition
  PER: sample important transitions more often
  Rainbow: combine major DQN improvements
```
### 20. 参考资料
 CSDN：函数估计的强化学习方法讲解：https://blog.csdn.net/qq_64671439/article/details/136629758

 动手学强化学习：Dyna-Q 算法：http://hrl.boyuai.com/chapter/1/dyna-q%E7%AE%97%E6%B3%95/

 动手学强化学习：DQN 算法：http://hrl.boyuai.com/chapter/2/dqn%E7%AE%97%E6%B3%95/

 动手学强化学习：DQN 改进算法：http://hrl.boyuai.com/chapter/2/dqn%E6%94%B9%E8%BF%9B%E7%AE%97%E6%B3%95/

 Playing Atari with Deep Reinforcement Learning：https://arxiv.org/abs/1312.5602

 Human-level control through deep reinforcement learning：https://www.nature.com/articles/nature14236

 Deep Reinforcement Learning with Double Q-learning：https://arxiv.org/abs/1509.06461

 Prioritized Experience Replay：https://arxiv.org/abs/1511.05952

 Dueling Network Architectures for Deep Reinforcement Learning：https://arxiv.org/abs/1511.06581

 Rainbow: Combining Improvements in Deep Reinforcement Learning：https://arxiv.org/abs/1710.02298

## 0x02. 十二：强化学习：Q-learning、Dyna-Q 与 DQN自测题
> 发布日期：2026-06-21  
> 原文链接：[十二：强化学习：Q-learning、Dyna-Q 与 DQN自测题](https://mp.weixin.qq.com/s/RiA-VdNrfBeaR8kiytNskg)

覆盖范围

- Q-learning 与 Sarsa 的区别
- Dyna-Q 的 learning + planning 框架
- 表格方法局限与函数近似
- DQN 的输入输出、loss、TD target、训练流程
- Experience replay 与 target network
- Double DQN、Dueling DQN、PER、Rainbow
- DQN 工程实现、排错和评估
### 一、Q-learning 基础
Q-learning 的核心目标是什么？
请写出表格型 Q-learning 的更新公式。
Q-learning 的 TD target 是什么？
Q-learning 的 TD error 是什么？
为什么 Q-learning 是 off-policy 算法？
Q-learning 和 Sarsa 的 target 有什么核心区别？
在 Cliff Walking 中，Q-learning 和 Sarsa 的行为差异通常是什么？
Q-learning 的收敛依赖哪些直觉条件？
### 二、Dyna-Q
Dyna-Q 想解决什么问题？
Dyna-Q 中 learning 和 planning 分别指什么？
Dyna-Q 的环境模型通常存储什么？
请描述 Dyna-Q 一次真实交互后的完整更新流程。
Dyna-Q 中 planning step 的数量会影响什么？
Dyna-Q 和纯 Q-learning 相比，样本效率为什么可能更高？
Dyna-Q 的主要风险是什么？
如果环境发生变化，Dyna-Q 的旧模型可能造成什么问题？
### 三、函数近似
表格型 Q 方法为什么难以处理大规模状态空间？
什么是函数近似的 Q 函数？
用函数近似做 Q-learning 时，监督学习式的 target 和 prediction 分别是什么？
什么是 semi-gradient？为什么 Q-learning 中常用半梯度？
什么是 deadly triad？
为什么 off-policy、bootstrapping 和 function approximation 同时出现会带来不稳定性？
线性函数近似和深度神经网络函数近似有什么区别？
为什么函数近似既带来泛化，也带来误差传播风险？
### 四、DQN 核心机制
DQN 的全称是什么？它解决了什么问题？
DQN 中神经网络近似的是什么函数？
对离散动作空间，DQN 网络通常输出什么？
经典 Atari DQN 的输入通常如何处理？
请写出 DQN 使用 target network 时的 TD target。
请写出 DQN 的损失函数。
为什么 DQN 常用 Huber loss？
DQN 为什么主要适合离散动作空间？
如果动作空间是连续的，DQN 会遇到什么困难？
DQN 与普通监督学习的相似点和关键区别是什么？
### 五、Experience Replay 与 Target Network
Experience replay 是什么？
Replay buffer 中通常存储哪些字段？
Experience replay 为什么能降低样本相关性？
Experience replay 如何提高样本利用率？
Replay buffer 太小或太大分别可能有什么问题？
Target network 是什么？
Target network 为什么能稳定训练？
Hard update 和 soft update 有什么区别？
为什么 target network 更新太频繁或太慢都可能有问题？
为什么 target 计算时通常要no_grad？
### 六、DQN 训练流程与实现
请描述 DQN 的完整训练流程。
DQN 中 epsilon-greedy 如何用于探索？
为什么训练前通常需要 replay buffer 预填充？
在 PyTorch 中为什么要用gather取Q(s,a)？
的 transition 在 target 中应该如何处理？
Reward clipping 在 DQN 中有什么作用和副作用？
Gradient clipping 解决什么问题？
Evaluation 时为什么要区别训练 epsilon 和评估 epsilon？
### 七、DQN 改进算法
标准 DQN 为什么容易过估计 Q 值？
Double DQN 的核心思想是什么？
请写出 Double DQN 的 target。
Dueling DQN 把 Q 函数拆成哪两部分？
Dueling DQN 为什么需要对 advantage 做 mean subtraction？
Dueling DQN 适合什么样的场景？
Prioritized Experience Replay 的采样依据是什么？
PER 为什么需要 importance sampling weight？
Multi-step return 对 DQN 有什么帮助？
Noisy Nets 相比 epsilon-greedy 的探索差异是什么？
Distributional RL 与普通 DQN 学习目标有什么区别？
Rainbow DQN 主要组合了哪些改进？
### 八、工程排错与应用
如果 DQN loss 爆炸，可能有哪些原因？
如果 DQN 训练 reward 长期不上升，应该排查哪些问题？
如果 Q 值整体越来越大但策略没有变好，可能是什么问题？
DQN 在部分可观测环境中为什么可能表现差？如何改进？
DQN 思想如何迁移到工具调用 Agent 的有限动作选择？
请完整比较 Q-learning、Dyna-Q、DQN、Double DQN、Dueling DQN 和 Rainbow 的核心目标与解决的问题。

## 0x03. 十二：强化学习：Q-learning、Dyna-Q 与 DQN自测题答案
> 发布日期：2026-06-21  
> 原文链接：[十二：强化学习：Q-learning、Dyna-Q 与 DQN自测题答案](https://mp.weixin.qq.com/s/6y_Q9kaBNNPy086hhD_wDg)

参考资料

\##CSDN：函数估计的强化学习方法讲解：https://blog.csdn.net/qq_64671439/article/details/136629758
\##动手学强化学习：Dyna-Q 算法：http://hrl.boyuai.com/chapter/1/dyna-q%E7%AE%97%E6%B3%95/
\##动手学强化学习：DQN 算法：http://hrl.boyuai.com/chapter/2/dqn%E7%AE%97%E6%B3%95/
\##动手学强化学习：DQN 改进算法：http://hrl.boyuai.com/chapter/2/dqn%E6%94%B9%E8%BF%9B%E7%AE%97%E6%B3%95/
\##Playing Atari with Deep Reinforcement Learning：https://arxiv.org/abs/1312.5602
\##Human-level control through deep reinforcement learning：https://www.nature.com/articles/nature14236
\##Deep Reinforcement Learning with Double Q-learning：https://arxiv.org/abs/1509.06461
\##Prioritized Experience Replay：https://arxiv.org/abs/1511.05952
\##Dueling Network Architectures for Deep Reinforcement Learning：https://arxiv.org/abs/1511.06581
\##Rainbow: Combining Improvements in Deep Reinforcement Learning：https://arxiv.org/abs/1710.02298
评分标准

\##合格：能写出 Q-learning 和 DQN target，知道 replay buffer、target network 的作用。
\##良好：能解释 Dyna-Q、函数近似、deadly triad、Double/Dueling/PER 的动机。
\##优秀：能从实现细节、训练稳定性、Q 值过估计、评估方式和 Agent 迁移角度完整回答。
### 一、Q-learning 基础
#### 1. Q-learning 的核心目标是什么？
Q-learning 的目标是在不知道完整环境模型的情况下学习最优动作价值函数Q*，并通过argmax_a Q(s,a)导出最优或近似最优策略。

#### 2. 请写出表格型 Q-learning 的更新公式。
#### 3. Q-learning 的 TD target 是什么？
如果下一状态终止，则y_t = R_{t+1}。

#### 4. Q-learning 的 TD error 是什么？
它表示当前 Q 估计与 bootstrap target 的差距。

#### 5. 为什么 Q-learning 是 off-policy 算法？
因为行为策略可以是 epsilon-greedy 或其他探索策略，但更新 target 使用下一状态的贪心动作max_a Q(S',a)。采样策略和学习的目标策略不同。

#### 6. Q-learning 和 Sarsa 的 target 有什么核心区别？
Sarsa 使用实际采样的下一个动作：

Q-learning 使用贪心动作：

#### 7. 在 Cliff Walking 中，Q-learning 和 Sarsa 的行为差异通常是什么？
Sarsa 会考虑探索动作可能掉下悬崖，因此更保守；Q-learning 学贪心最优路径，可能贴近悬崖，因为它的 target 不考虑实际探索风险。

#### 8. Q-learning 的收敛依赖哪些直觉条件？
表格情况下需要充分探索所有状态动作对、学习率合适衰减、奖励有界、MDP 稳定。在函数近似情况下收敛更复杂，不能简单套用表格收敛结论。

### 二、Dyna-Q
#### 9. Dyna-Q 想解决什么问题？
Dyna-Q 想提高样本效率。真实环境交互昂贵时，它用已学到的环境模型生成模拟经验，在真实经验之外做额外 planning 更新。

#### 10. Dyna-Q 中 learning 和 planning 分别指什么？
Learning 指用真实交互 transition 更新 Q 和模型。Planning 指从模型中采样模拟 transition，再用类似 Q-learning 的方式更新 Q。

#### 11. Dyna-Q 的环境模型通常存储什么？
最简单形式存储每个已见过的(s,a)对应的奖励和下一状态：

随机环境中可存转移分布或采样模型。

#### 12. 请描述 Dyna-Q 一次真实交互
后的完整更新流程。
先在环境中执行动作得到(s,a,r,s')；用这个真实 transition 做一次 Q-learning 更新；把(r,s')写入模型；然后重复若干次，从模型中抽取过去的(s,a)，生成模拟 transition，再更新 Q。

#### 13. Dyna-Q 中 planning step 的数量会影响什么？
planning step 越多，每次真实交互后模型模拟更新越多，样本效率可能更高，但计算量更大，也更依赖模型准确性。

#### 14. Dyna-Q 和纯 Q-learning 相比，样本效率为什么可能更高？
纯 Q-learning 每个真实 transition 通常更新一次。Dyna-Q 可以把历史经验通过模型反复用于 planning，使价值信息传播更快。

#### 15. Dyna-Q 的主要风险是什么？
风险来自模型误差。如果 learned model 错误，planning 会用错误 transition 反复更新 Q，导致偏差放大。

#### 16. 如果环境发生变化，Dyna-Q 的旧模型可能造成什么问题？
旧模型会继续生成过时的模拟经验，使策略适应变慢，甚至坚持已经无效的路径。需要模型更新、遗忘机制或探索奖励。

### 三、函数近似
#### 17. 表格型 Q 方法为什么难以处理大规模状态空间？
表格方法需要为每个状态动作对存一个值。状态巨大或连续时，无法枚举和存储，也不能对未见状态泛化。

#### 18. 什么是函数近似的 Q 函数？
用参数模型近似动作价值函数：

参数theta可以来自线性模型或神经网络。

#### 19. 用函数近似做 Q-learning 时，监督学习式的 target 和 prediction 分别是什么？
prediction 是Q(s,a;theta)。target 通常是：

DQN 中通常用 target network 参数theta^-来计算 target。

#### 20. 什么是 semi-gradient？为什么 Q-learning 中常用半梯度？
Semi-gradient 更新只对当前预测Q(s,a;theta)求梯度，不对 target 里的 Q 值反向传播。这样实现简单，也符合 TD target 被视为固定目标的近似。

#### 21. 什么是 deadly triad？
Deadly triad 指 function approximation、bootstrapping、off-policy learning 三者同时出现时，强化学习训练容易不稳定甚至发散。

#### 22. 为什么 off-policy、bootstrapping 和 function approximation 同时出现会带来不稳定性？
off-policy 带来数据分布偏移，bootstrapping 让 target 依赖自身估计，函数近似会把局部误差泛化到其他状态动作。三者叠加会形成反馈环，放大估计误差。

#### 23. 线性函数近似和深度神经网络函数近似有什么区别？
线性近似表达能力有限、理论分析相对容易。深度网络表达能力强，能处理图像等高维输入，但训练非凸、稳定性和调参更困难。

#### 24. 为什么函数近似既带来泛化，也带来误差传播风险？
相似状态共享参数，因此未访问状态也能得到估计，这是泛化。反过来，一个样本的错误更新也会影响其他状态动作的预测，造成误差传播。

### 四、DQN 核心机制
#### 25. DQN 的全称是什么？它解决了什么问题？
DQN 是 Deep Q-Network。它用深度神经网络近似 Q 函数，使 Q-learning 能处理高维观测，例如 Atari 图像。

#### 26. DQN 中神经网络近似的是什么函数？
近似动作价值函数：

表示状态s下执行动作a的长期期望回报。

#### 27. 对离散动作空间，DQN 网络通常输出什么？
通常输入一个状态，输出每个离散动作的 Q 值：

#### 28. 经典 Atari DQN 的输入通常如何处理？
通常把游戏画面灰度化、缩放到固定尺寸，并堆叠最近多帧，例如84 x 84 x 4，以提供运动信息。

#### 29. 请写出 DQN 使用 target network 时的 TD target。
theta^-是 target network 参数。

#### 30. 请写出 DQN 的损失函数。
常见 MSE 形式：

也可用 Huber loss。

#### 31. 为什么 DQN 常用 Huber loss？
Huber loss 在误差小时像 MSE，误差大时像 MAE，能降低异常 TD error 对梯度的冲击，使训练更稳定。

#### 32. DQN 为什么主要适合离散动作空间？
DQN 需要对下一状态所有动作取最大值。离散动作可以枚举，连续动作无法直接枚举max_a Q(s,a)，优化会变得困难。

#### 33. 如果动作空间是连续的，DQN 会遇到什么困难？
需要在连续动作空间求argmax_a Q(s,a)，这本身是复杂优化问题。因此连续控制通常使用 actor-critic 方法，由 actor 直接输出动作。

#### 34. DQN 与普通监督学习的相似点和关键区别是什么？
相似点是都用网络预测、target 和 loss 更新。区别是 DQN 的 target 来自 bootstrap 和当前网络/目标网络，数据分布由策略生成，target 非平稳，探索会影响训练数据。

### 五、Experience Replay 与 Target Network
#### 35. Experience replay 是什么？
它是把历史 transition 存入 replay buffer，并在训练时随机采样 minibatch 进行更新的方法。

#### 36. Replay buffer 中通常存储哪些字段？
通常存储：

有时还存 priority、log prob、episode id 等辅助信息。

#### 37. Experience replay 为什么能降低样本相关性？
环境连续交互产生的相邻样本高度相关。随机从 buffer 中采样可以混合不同时刻的经验，减少 minibatch 内样本相关性。

#### 38. Experience replay 如何提高样本利用率？
同一条真实 transition 可以被多次采样训练，而不是用完即丢，从而提高每次环境交互的利用率。

#### 39. Replay buffer 太小或太大分别可能有什么问题？
太小会样本相关性强、覆盖不足。太大可能包含过旧策略的数据，数据分布滞后，尤其在非平稳环境中影响学习。

#### 40. Target network 是什么？
Target network 是 online Q network 的延迟副本，用于计算 TD target。它的参数theta^-更新频率低于 online network。

#### 41. Target network 为什么能稳定训练？
它让 target 在一段时间内相对固定，避免 prediction 和 target 同时快速变化，降低 bootstrap target 的非平稳性。

#### 42. Hard update 和 soft update 有什么区别？
Hard update 每隔固定步数复制参数：

Soft update 每步缓慢混合：

#### 43. 为什么 target network 更新太频繁或太慢都可能有问题？
太频繁会接近没有 target network，target 不稳定。太慢会 target 过旧，学习滞后，影响收敛速度。

#### 44. 为什么 target 计算时通常要no_grad？
target 被视为固定监督信号，不应让梯度穿过 target network 或下一状态 Q。否则会改变优化目标并增加不稳定性。

### 六、DQN 训练流程与实现
#### 45. 请描述 DQN 的完整训练流程。
初始化 online/target 网络和 replay buffer；用 epsilon-greedy 与环境交互；存储 transition；从 buffer 采样 minibatch；计算 target；最小化 TD loss 更新 online 网络；周期性更新 target network；循环直到训练结束。

#### 46. DQN 中 epsilon-greedy 如何用于探索？
以epsilon概率随机动作，以1-epsilon概率选择当前 Q 最大动作。训练中通常让 epsilon 从大到小衰减。

#### 47. 为什么训练前通常需要 replay buffer 预填充？
如果 buffer 太空就训练，样本高度相关且覆盖很差，容易导致网络过拟合早期轨迹或训练不稳定。

#### 48. 在 PyTorch 中为什么要用gather取Q(s,a)？
DQN 网络输出所有动作的 Q 值，但 loss 只更新实际执行动作对应的Q(s,a)。gather用 action index 从[batch, num_actions]中取对应列。

49. done=True的 transition 在 target 中应该如何处理？
终止状态没有未来价值：

实现中常写：

#### 50. Reward clipping 在 DQN 中有什么作用和副作用？
作用是控制奖励尺度，稳定不同游戏上的训练。副作用是丢失奖励大小信息，可能改变任务最优策略。

#### 51. Gradient clipping 解决什么问题？
限制梯度范数或梯度值，防止 TD error 大、Q 值爆炸或异常样本导致参数更新过猛。

#### 52. Evaluation 时为什么要区别训练 epsilon 和评估 epsilon？
训练需要探索，评估要衡量当前策略质量。如果评估仍用高 epsilon，会把随机探索带来的差表现算进策略能力，评估不准确。

### 七、DQN 改进算法
#### 53. 标准 DQN 为什么容易过估计 Q 值？
max操作倾向选择估计噪声中偏大的动作，因此 target 会系统性偏高，造成过估计。

#### 54. Double DQN 的核心思想是什么？
把动作选择和动作评估解耦。online network 选择下一状态最优动作，target network 评估该动作的 Q 值。

#### 55. 请写出 Double DQN 的 target。
#### 56. Dueling DQN 把 Q 函数拆成哪两部分？
拆成状态价值V(s)和优势函数A(s,a)：

#### 57. Dueling DQN 为什么需要对 advantage 做 mean subtraction？
因为V和A存在不可辨识性：给V加常数、给A减常数，Q 不变。常用：

来固定分解。

#### 58. Dueling DQN 适合什么样的场景？
适合很多动作价值差异不明显、状态本身好坏很重要的场景。它能更有效地学习状态价值。

#### 59. Prioritized Experience Replay 的采样依据是什么？
通常依据 TD error 的绝对值：

误差大的样本更容易被采样。

#### 60. PER 为什么需要 importance sampling weight？
非均匀采样改变了训练分布，会引入偏差。importance sampling weight 用来降低这种偏差，使更新更接近原目标。

#### 61. Multi-step return 对 DQN 有什么帮助？
多步回报能更快传播远期奖励，减少一步 bootstrap 的偏差。但步数越大，target 方差通常越高。

#### 62. Noisy Nets 相比 epsilon-greedy 的探索差异是什么？
Noisy Nets 在网络参数中注入可学习噪声，探索具有状态依赖性和时间一致性；epsilon-greedy 是简单随机动作探索。

#### 63. Distributional RL 与普通 DQN 学习目标有什么区别？
普通 DQN 学习回报期望Q(s,a)。Distributional RL 学习回报分布，能表达不确定性和分布形状。

#### 64. Rainbow DQN 主要组合了哪些改进？
通常包括 Double DQN、Dueling network、Prioritized replay、multi-step return、distributional RL 和 Noisy Nets。

### 八、工程排错与应用
#### 65. 如果 DQN loss 爆炸，可能有哪些原因？
学习率过大、奖励尺度过大、没有 target network、target 没有 detach、done 处理错误、Q 值过估计、梯度未裁剪、replay buffer 样本异常。

#### 66. 如果 DQN 训练 reward 长期不上升，应该排查哪些问题？
排查环境交互、动作映射、奖励符号、epsilon 衰减、buffer 预填充、target 更新频率、网络输出维度、gather维度、done mask 和评估方式。

#### 67. 如果 Q 值整体越来越大但策略没有变好，可能是什么问题？
可能是 Q 值过估计、bootstrap target 错误、终止状态仍加未来价值、奖励尺度异常或 target network 更新设置不当。

#### 68. DQN 在部分可观测环境中为什么可能表现差？如何改进？
单帧状态不包含完整信息，Q 网络无法判断真实状态。可用帧堆叠、RNN/DRQN、记忆机制或 belief state 改进。

#### 69. DQN 思想如何迁移到工具调用 Agent 的有限动作选择？
如果高层动作是有限集合，例如检索、调用工具、追问、总结，可以用网络估计每个动作的 Q 值。状态是对话历史和工具结果，奖励是任务成功、成本和安全指标。

70. 请完整比较 Q-learning、Dyna-Q、DQN、Double DQN、Dueling DQN 和 Rainbow 的核心目标与解决的问题。
Q-learning 是表格 off-policy TD control，学习Q*。Dyna-Q 在 Q-learning 上加入 learned model 和 planning，提高样本效率。DQN 用深度网络近似 Q，处理高维状态。Double DQN 解耦动作选择和评估，缓解过估计。Dueling DQN 分离状态价值和优势，提高价值学习效率。Rainbow 组合多种改进，系统提升 DQN 的稳定性和性能。
