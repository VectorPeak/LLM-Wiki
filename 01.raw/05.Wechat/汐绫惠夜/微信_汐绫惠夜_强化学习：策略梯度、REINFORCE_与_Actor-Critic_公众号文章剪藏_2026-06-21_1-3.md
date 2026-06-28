---
title: "微信_汐绫惠夜_强化学习：策略梯度、REINFORCE 与 Actor-Critic_公众号文章剪藏_2026-06-21_1-3"
source: "/api/v1/wechat_mp/web/fetch_mp_article_detail_html"
author:
  - "汐绫惠夜"
published: "2026-06-03"
created: 2026-06-21
description: "TikHub 命中的微信公众号文章候选，共 3 条，本文档收录 3 条"
tags:
  - "clippings"
  - "wechat"
  - "汐绫惠夜"
---

## 0x01. 十三：强化学习：策略梯度、REINFORCE 与 Actor-Critic
> 发布日期：2026-06-03  
> 原文链接：[十三：强化学习：策略梯度、REINFORCE 与 Actor-Critic](https://mp.weixin.qq.com/s/4AIGHAqgh2QIpAMrPJZUPg)

### 1. 学习定位
 前几天主要学习值函数方法：Sarsa、Q-learning、DQN。它们的核心是先学习 Q(s,a)，再通过 argmax 选择动作。策略梯度方法则直接优化策略参数：
```text
pi_theta(a|s)
```
策略梯度是理解 PPO、RLHF-PPO、GRPO 的前置知识。大模型 RLHF 中，语言模型本身就是一个随机策略：给定上下文，输出下一个 token 的概率分布。因此策略梯度与 NLP 场景关系非常直接。

 本日知识链路：
```text
policy-based methods
-> objective J(theta)
-> trajectory probability
-> log-derivative trick
-> policy gradient theorem
-> REINFORCE
-> baseline and advantage
-> Actor-Critic
-> TD critic / GAE
-> entropy regularization
-> TRPO trust region
```
### 2. 值函数方法与策略方法
 值函数方法：
```text
learn Q(s,a)
act by argmax_a Q(s,a)
```
策略方法：
```text
learn pi_theta(a|s) directly
sample or choose action from pi_theta
```
```text
代表算法：REINFORCE、A2C、PPO、DDPG (混合)
```
策略方法的优势：

 可以自然表示随机策略。

 适合连续动作空间。

 对高维动作分布更直接。

 与可微神经网络输出概率分布天然匹配。

 局限：

 梯度估计方差高。

 样本效率通常较低。

 训练稳定性依赖 baseline、advantage、trust region 等技术。

### 3. 随机策略参数化
 离散动作策略通常用 softmax：
```text
pi_theta(a|s) = softmax(f_theta(s))[a]
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkiaUME1s3tiaf58zxibL0BeKsgOAXbvsXhAJEPpS3vP4DKJ3ezj8FiaqDKUib8VP1Enk4SAia49UMCHEmMoR9OGJ30Siabn7g5x4N0KQs/640?wx_fmt=png&from=appmsg)
 连续动作策略常用高斯分布：
```text
a ~ N(mu_theta(s), sigma_theta(s)^2)
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkjC1aBt09hZ7gn7UAO2Fk73pgcLJicdKtuMQmzg1KUXQano0kibx139iczicBLyKvWyvISWSnQQPIRBrAnxibicBqsKJyNkK86m8uo6Y/640?wx_fmt=png&from=appmsg)
 在 LLM 中，策略是词表分布：
```text
pi_theta(token_t | prompt, token_<t)
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkgibh3XXsFsfrIL3Od56RQic5wiaaf6Zu6JktnEMzkT6mHS8GPKegcdK8iaWarwKMiaOubLVic6QibxAiacIspPxxnIEfpNDzZoX43yl7c/640?wx_fmt=png&from=appmsg)
 轨迹概率由每步策略概率和环境转移共同决定：
```text
P_theta(tau)
= rho_0(s_0) product_t pi_theta(a_t|s_t) P(s_{t+1}|s_t,a_t)
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkhaVH7N4LQ6cB3wulms225WyWIIialibTicL5Hclia1G5fnmgEyIXXaibTFbLaDYNhMcRrqicwFfMUiaqwx25q6aOLUj16xiaAkejVgafI/640?wx_fmt=png&from=appmsg)
 环境转移不依赖 theta，策略梯度主要作用在 pi_theta 上。

### 4. 策略目标函数
 策略优化目标通常写成期望回报：
```text
J(theta) = E_{tau ~ pi_theta}[G_0]
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkjGlkJfZ03aRYa5PhRYYpjg3ILR6cIulIcmIicFsibicbLM6I4G4fXbcceBKXtqS6BuH3rtu8qGQb8XXuAOtueKSWtZCnGI7NM2c4/640?wx_fmt=png&from=appmsg)
 也可以写成：
```text
J(theta) = E_{s ~ d^pi, a ~ pi_theta}[Q^pi(s,a)]
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkj5S2n6EB3cnuy9AOPMsvWvqGjicKPKBWRVWknE400eUvBLadf0sHmA5qLbldlcgsaCwwoGRnxRw3FiaqO374lBYwwMQicYrt12DA/640?wx_fmt=png&from=appmsg)
 其中 d^pi 是策略诱导的状态访问分布。策略梯度的目标是计算或估计：
```text
grad_theta J(theta)
```
然后用梯度上升提升期望回报：
```text
theta <- theta + alpha grad_theta J(theta)
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkiaP7Rj4EjgWcV6MAIMVaFVq3wtD8WdR3HgwKGObdwwSfibfOKMCknRx175yK2GvfdtKQsDfC94KEKEiaEIDsctsRHXSqnxvlNZRg/640?wx_fmt=png&from=appmsg)
 深度学习框架通常默认做梯度下降，因此实际代码里会最小化负目标。

### 5. Log-derivative Trick
 策略梯度推导的关键是 log-derivative trick：
```text
grad_theta p_theta(x)
= p_theta(x) grad_theta log p_theta(x)
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkia4hRjeDNbgUic8XWwLlUQHdFyvFaY1RL9ialh4icXVZ1oYRWR7NzKhGANOGn0DGvHU3hXY4VvzR6tJTc55xBtELh4Jql6tncREXg/640?wx_fmt=png&from=appmsg)
 把对概率的梯度，变成 “概率 × 对数概率的梯度”

 于是：
```text
grad_theta E_{x ~ p_theta}[f(x)]
= E_{x ~ p_theta}[f(x) grad_theta log p_theta(x)]
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkhtbfI0sHT16x1p3T0bowvSy83mrW9zVp38mTqxH8wDapGOpjI3syy2PCAoG6yHbrlO7yqy2leau7InwavS6RxUWGmVDAMLKC8/640?wx_fmt=png&from=appmsg)
 原来没法求导的 **期望梯度** -
 现在变成了可以 **采样估算** 的表达式！

 对轨迹分布使用这个技巧：
```text
grad_theta J(theta)
= E_tau [G_0 grad_theta log P_theta(tau)]
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkgPQajr66UiacDSMEBr6Wl82c07LuicaNX6lrKoo3ibxy3Yt2q4j4bsTEXMcWS8fR7Zu8CCrDofNwAHnmZAIXBn465pU0h2azdoFo/640?wx_fmt=png&from=appmsg)
 由于环境转移不依赖策略参数：
```javascript
log P_theta(tau)
= const + sum_t log pi_theta(a_t|s_t)
```
得到：
```text
grad_theta J(theta)
= E_tau [G_0 sum_t grad_theta log pi_theta(a_t|s_t)]
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkgnRjAQW2kRTcibpBLbaIJrfVSMDL9TAmxGpISicNic6bgSnt3J7xEic1tNm2bjnsHTV3xNrhf1d9VVPHvKDfQHujCtCOc7yQYNuKY/640?wx_fmt=png&from=appmsg)
 用整条轨迹的总收益 \(G_0\)，去缩放整条轨迹所有动作的梯度。

- G_0>0(整局赚了正奖励)：权重为正 → 顺着梯度更新，

 **放大所有动作概率，鼓励复现本轨迹的全部行为**；

- G_0<0(整局亏损、负奖励)：权重为负 → 梯度反向，

 **压低轨迹里所有动作概率，避免再踩同样操作**。

 这就是 REINFORCE 的基础。

### 6. Policy Gradient Theorem
 更常用的策略梯度形式是：
```text
grad_theta J(theta)
∝ E_{s ~ d^pi, a ~ pi_theta}
  [grad_theta log pi_theta(a|s) Q^pi(s,a)]
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkhY3q0Vo1yA0YYwnTOrBcNwHRvIes5kJQR63ZYL8plyFEaM8F3HfLm4PkxDQFFrt41PibmncXbbD1XYSzqCYeMqz4BoaJZMR7SU/640?wx_fmt=png&from=appmsg)
 直觉：
```text
如果某动作的长期价值 Q 高，就增加它的 log probability。
如果某动作的长期价值低，就降低它的 log probability。
```
策略梯度不需要对环境转移概率求导，因此可以用于未知环境，只需要采样轨迹。

### 7. REINFORCE 算法
 REINFORCE 是最基础的 Monte Carlo policy gradient 方法。

 更新方向：
```text
grad_theta log pi_theta(A_t|S_t) * G_t
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkjYneLbZEZ5hJfeot0TIib09NCecz14u9UJFicyp0X7AEsjLQMB5LxH9355LVp0IHUBbga6eibwjUDOOkBAnxJxdghG5mjicmuMnic8/640?wx_fmt=png&from=appmsg)
 算法流程：
```python
for each episode:
  generate trajectory using pi_theta
  compute return G_t for each timestep
  update theta by:
    theta <- theta + alpha *sum_t grad log pi_theta(A_t|S_t)* G_t
```
在损失函数形式中：
```text
loss = - sum_t log pi_theta(A_t|S_t) * G_t
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkhQJ1EjBjXVBxIdVDMAjO01cbLPwzvHL9m4gwibYB0RibwtXUYPXnCia73nibYMIWJp76fxgJGojD8hoQicGNggVlK7n8YGTwNV7vP8/640?wx_fmt=png&from=appmsg)
 最小化这个 loss 等价于最大化期望回报。

### 8. Baseline
 REINFORCE 方差高。可以减去一个不依赖动作的 baseline：
```text
grad J = E[grad log pi(a|s) * (G_t - b(s))]
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkges5Q5ZmfPXrEQCH4ZmqR302hK8C5ZqUkGyFkmqvTPuR1EMuVub6asQukMd7mrktEuhajHL5FpaKa3X5dSeZ79nsZVnfdGR7o/640?wx_fmt=png&from=appmsg)
 常用 baseline 是状态价值函数：
```text
b(s) = V^pi(s)
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkiaL807HCnK45BVfJk3dOlurNn18asT6R9t84VhRyLUjQBNHDTA9nPdQCXGupUOUCFTLCu2dm2CoUWc8mY336Q49uewktvDb0K0/640?wx_fmt=png&from=appmsg)
 减 baseline 不改变梯度期望，但可以显著降低方差。原因是：
```text
E_{a ~ pi}[grad log pi(a|s) b(s)] = 0
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkiaCfLpLoiceymDGAaVibnibqm0mnyFbaEohpyK4EoUicGHhEIiaZrSmicHKwdKn9PDzDwtjqhdGwofsu3gADTnTNOIPmxFyQmsoaYxhQ/640?wx_fmt=png&from=appmsg)
 减去 Baseline 不改变梯度方向，只降低波动！

 前提是 b(s) 不依赖当前动作 a。

### 9. Advantage Function
 当 baseline 取 V^pi(s) 时：
```text
A^pi(s,a) = Q^pi(s,a) - V^pi(s)
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkjOVicb8G92puIdfnUIM6w0UuDsCqfjvU4fsvkWyhuxtJeDznpTv4iaXPJDza0lxMiarFD3OPjK6kJBj8ZKPQwfgjB4icTgLqtx2icc/640?wx_fmt=png&from=appmsg)
 策略梯度变成：
```text
grad J ∝ E[grad log pi(a|s) A^pi(s,a)]
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkghN8Wj367XiaomvTiagjU2iaqFalXzTjNvfPhdeLfSJiantFjJVMgtG8ZsIhUEAOyvmgvibcw4SVnoEMZicFcvIN4giatcehvtibMqGfY/640?wx_fmt=png&from=appmsg)
 优势函数表示动作相对该状态平均动作的好坏：

- A > 0：增加该动作概率。
- A < 0：降低该动作概率。

 优势比原始回报更适合训练，因为它去掉了状态本身好坏造成的公共偏移。

### 10. Reward-to-go
 原始 REINFORCE 可用整条轨迹回报 G_0 乘所有动作的 log prob。但某个动作不应该为它发生之前的奖励负责。因此常用 reward-to-go：
```text
G_t = R_{t+1} + gamma R_{t+2} + ...
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkgQfb3VtnT8g0jwr67UnIy8MgLg09CYmDCHesmHZXtFT3YNNI6eeLMAgolMrgF4xzV17RpdAnsBBfjdbjIjodDAJic05fQx3nfY/640?wx_fmt=png&from=appmsg)
 当前动作，只对未来奖励负责，不对过去的奖励负责！

 更新：
```text
sum_t grad log pi(A_t|S_t) * G_t
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkgEgaSYgQCsjwqTJOJlibgWCXqcps04SMs4HwJ3D3R7UIWZNbiadB9wzicqcevcTd5JNyoZiase11DZs1OLhCkHdT2XbsdEKhE5V9k/640?wx_fmt=png&from=appmsg)
 这减少了无关奖励带来的方差。

### 11. Actor-Critic
 Actor-Critic 同时学习：
```javascript
Actor: policy pi_theta(a|s) 负责学动作
Critic: value function V_w(s) or Q_w(s,a)  负责打分
```
Actor 用 critic 提供的价值或优势来更新策略：
```text
grad_theta log pi_theta(a|s) * advantage
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkhQTIEHBD3dEPPbPdK3rhwhoLeRGFbib0J8IuFasa6yeudGk0CE6biabAl8Zeh6LYzuFyTVqPfcoAKfF3Fc5JkMzJpWu9yzg1Yxw/640?wx_fmt=png&from=appmsg)
 Critic 用 TD target 更新价值：
```text
delta_t = R_{t+1} + gamma V_w(S_{t+1}) - V_w(S_t)
```
![image](https://mmbiz.qpic.cn/sz_mmbiz_png/DyOpPS8WAkhBdko1nsX2hiar1MSd49hQTke07BLm3o8VyyxqgNwdFI1iaum22B69CSEwKqQD3JC6CDjSR968cEvu6I63ibz3OJhR84uTbLlHgA/640?wx_fmt=png&from=appmsg)
 常见 actor update：
```text
theta <- theta + alpha *grad log pi_theta(A_t|S_t)* delta_t
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkj82n6UQ0MttW9cDeyibDfpSocCAom4x7LCo0h0eCuIWSRKzXHxt4gp6fTDWoBv9NvCqibticBBIHA52ictTuJoGGvcb60HzdxnBM8/640?wx_fmt=png&from=appmsg)
 其中 TD error 可以作为 advantage 的估计。

### 12. A2C 与 A3C
 A2C(Advantage Actor-Critic)通常指同步采样多个环境，计算 advantage 后更新 actor 和 critic。

 A3C(Asynchronous Advantage Actor-Critic)使用多个 worker 异步与环境交互并更新全局参数。它通过并行采样降低样本相关性。

 二者的核心都是：
```text
policy loss: -log pi(a|s) * advantage
value loss:  value prediction 与 return/TD target 的差
entropy loss: 鼓励探索
```
### 13. GAE
 GAE(Generalized Advantage Estimation)用多步 TD error 加权估计 advantage：
```text
delta_t = r_t + gamma V(s_{t+1}) - V(s_t)

A_t^GAE
= delta_t + gamma lambda delta_{t+1}
  + (gamma lambda)^2 delta_{t+2} + ...
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkjZHFk7EAF0icO3tPgKqiaUCopRhxtHmZEWOfCQSGtpZcibTuaPaLpDBl8hdEBO4Vc33LHzuCEAd5q3AE1c0yUv6PkfoEdHFjd2ls/640?wx_fmt=png&from=appmsg)
 lambda 控制 bias-variance 权衡：

- lambda=0
 接近一步 TD，方差低但 bias 高。

- lambda=1
 接近 Monte Carlo，bias 低但方差高。

 GAE 是 PPO 等算法中非常常见的 advantage 估计方法。

- **gamma 折扣因子只管reward远近价值**
- **GAE的lambda则负责：要不要把后面几步的 TD 误差拿来一起估算 A** ### 14. Entropy Regularization

 策略梯度训练可能过早收敛到确定性策略，探索不足。熵正则鼓励策略保持一定随机性：
```text
H(pi(.|s)) = - sum_a pi(a|s) log pi(a|s)
```
![image](https://mmbiz.qpic.cn/mmbiz_png/DyOpPS8WAkjKdJ0ciaWMQ5XjBzguhchmbkIbySR0vI1CDTj479TVXf2IFh99ms9JufhNcCpGsKFia6qwiagPRKQnH0DYuGcfcTpwMw0hSegfkM/640?wx_fmt=png&from=appmsg)
 常见目标：
```text
policy_objective + beta * entropy
```
```text
最终目标 = 原本的策略目标 + β * 熵
```
在 loss 中通常写为：
```text
loss = policy_loss + value_loss - beta * entropy
```
熵系数太大，策略会过度随机；太小，探索不足。

### 15. TRPO 的信赖域思想
 普通策略梯度如果步子太大，策略分布会剧烈变化，导致性能崩坏。TRPO(Trust Region Policy Optimization)限制新旧策略之间的 KL 散度：
```text
maximize surrogate objective
subject to E[KL(pi_old(.|s), pi_new(.|s))] <= delta
```
核心直觉：
```text
策略每次只能在可信区域内更新，避免单次更新过大。
```
TRPO 理论优雅但实现复杂，涉及二阶近似和共轭梯度。PPO 后续用 clipping 或 KL penalty 近似 TRPO 的信赖域思想。

### 16. 实现细节
 离散动作策略常见实现：
```text
logits = policy_net(states)
dist = Categorical(logits=logits)
actions = dist.sample()
log_probs = dist.log_prob(actions)
entropy = dist.entropy()
```
Actor loss：
```text
policy_loss = -(log_probs * advantages.detach()).mean()
```
Critic loss：
```text
value_loss = mse(V(states), returns)
```
常见注意点：

 advantage 通常 detach，避免 actor loss 反向更新 critic。

 advantage 常做 normalization。

 return/advantage 的时间维索引要正确。

 log prob 必须对应采样时的动作。

 连续动作要正确计算高斯分布 log probability。

### 17. 策略梯度的优缺点
 优点：

 直接优化策略。

 适合随机策略和连续动作。

 能与深度网络自然结合。

 与 LLM token 分布形式一致。

 缺点：

 样本效率低。

 梯度方差高。

 对 reward scale、advantage 估计、学习率敏感。

 更新过大可能导致策略崩坏。

### 18. 与 LLM、RLHF 的联系
 LLM 的生成过程可以看成策略：
```text
pi_theta(token_t | context_t)
```
一条输出序列是 trajectory。奖励可以来自人类偏好、奖励模型、规则判分或任务结果。策略梯度更新的核心形式仍然是：
```text
grad log pi_theta(action|state) * advantage
```
PPO、RLHF-PPO、GRPO 都是在这个基础上加入 KL 约束、ratio clipping、group advantage 等稳定化设计。

### 19. 常见误区
 误区一：策略梯度需要知道环境转移概率。 实际推导中环境转移项不依赖策略参数，不需要对其求导。

 误区二：baseline 会改变最优策略。 只要 baseline 不依赖动作，它不改变梯度期望，只降低方差。

 误区三：REINFORCE 和 Actor-Critic 没有关系。 Actor-Critic 可以看成用 critic 估计 return/advantage 的策略梯度方法。

 误区四：advantage 越大越好。 advantage 尺度过大可能导致更新过猛，通常需要归一化或裁剪。

 误区五：TRPO/PPO 是完全不同于策略梯度的算法。 它们仍是策略梯度思想，只是限制策略更新幅度。

### 20. 核心总结
 第十三天需要掌握的最小闭环：
```yaml
Policy:
  pi_theta(a|s)

Objective:
  J(theta) = E_tau[G_0]

Log-derivative trick:
  grad p = p grad log p

Policy gradient:
  grad J ∝ E[grad log pi(a|s) Q^pi(s,a)]

REINFORCE:
  loss = -log pi(a|s) * G_t

Baseline:
  G_t - V(s)

Advantage:
  A(s,a) = Q(s,a) - V(s)

Actor-Critic:
  actor updates policy
  critic estimates value/advantage

TRPO:
  restrict policy update by KL trust region
```
### 21. 参考资料
 CSDN：策略梯度和 REINFORCE 算法：https://blog.csdn.net/qq_64671439/article/details/137026601

 CSDN：多种 Actor-Critic 讲解：https://blog.csdn.net/qq_64671439/article/details/137611583

 动手学强化学习：策略梯度算法：http://hrl.boyuai.com/chapter/2/%E7%AD%96%E7%95%A5%E6%A2%AF%E5%BA%A6%E7%AE%97%E6%B3%95/

 动手学强化学习：Actor-Critic 算法：http://hrl.boyuai.com/chapter/2/actor-critic%E7%AE%97%E6%B3%95/

 动手学强化学习：TRPO 算法：http://hrl.boyuai.com/chapter/2/trpo%E7%AE%97%E6%B3%95/

 Williams, REINFORCE algorithm：https://link.springer.com/article/10.1007/BF00992696

 Sutton and Barto, Reinforcement Learning: An Introduction, Chapter 13：http://incompleteideas.net/book/RLbook2020.pdf

 Trust Region Policy Optimization：https://arxiv.org/abs/1502.05477

 High-Dimensional Continuous Control Using Generalized Advantage Estimation：https://arxiv.org/abs/1506.02438

## 0x02. 十三：强化学习：策略梯度、REINFORCE 与 Actor-Critic自测题
> 发布日期：2026-06-03  
> 原文链接：[十三：强化学习：策略梯度、REINFORCE 与 Actor-Critic自测题](https://mp.weixin.qq.com/s/bGjTXxh1762JF446798q_A)

### 覆盖范围
 策略方法与值函数方法对比

 随机策略、轨迹概率、策略目标

 log-derivative trick 与 policy gradient theorem

 REINFORCE、reward-to-go、baseline、advantage

 Actor-Critic、A2C/A3C、GAE、entropy regularization

 TRPO 信赖域思想

 策略梯度实现细节和 LLM/RLHF 联系

### 使用方式
 先阅读 day13_policy_gradient_actor_critic_learning.md，再闭卷回答本文件中的题目。答题时尽量写出公式推导、算法流程、优缺点和工程注意点。完成后再看答案文件。

### 一、策略方法基础
 策略梯度方法和基于值函数的方法有什么核心区别？

 为什么策略方法适合连续动作空间？

 什么是随机策略 pi_theta(a|s)？

 离散动作策略通常如何参数化？

 连续动作策略通常如何参数化？

 为什么 LLM 生成可以看作一个随机策略？

 策略方法相比 Q-learning/DQN 的优势是什么？

 策略方法的主要缺点是什么？

### 二、策略目标与轨迹概率
 策略优化目标 J(theta) 通常如何定义？

 一条轨迹 tau 的概率如何分解？

 为什么环境转移概率在策略梯度中不需要求导？

 什么是状态访问分布 d^pi？

 策略梯度为什么通常做梯度上升？

 在深度学习框架中，为什么常把策略梯度目标写成 loss 的负号？

 策略分布变化为什么会导致训练数据分布变化？

 为什么策略梯度通常是 on-policy 的？

### 三、Log-derivative Trick 与策略梯度定理
 请写出 log-derivative trick。

 log-derivative trick 如何用于对期望求梯度？

 请写出基于轨迹回报的 REINFORCE 梯度形式。

 请写出 policy gradient theorem 的常见形式。

- grad log pi(a|s)
 的直觉含义是什么？

- Q^pi(s,a)
 在策略梯度中扮演什么角色？

 为什么高回报动作的概率会被增加？

 策略梯度是否需要对 argmax 求导？这和 DQN 有什么不同？

### 四、REINFORCE
 REINFORCE 是什么类型的算法？

 请写出 REINFORCE 的更新方向。

 请写出 REINFORCE 常见 loss 形式。

 REINFORCE 为什么通常要等 episode 结束？

 什么是 reward-to-go？

 reward-to-go 相比整条轨迹回报有什么好处？

 REINFORCE 的主要方差来源是什么？

 REINFORCE 在长 horizon 任务中为什么难训练？

### 五、Baseline 与 Advantage
 为什么要在策略梯度中引入 baseline？

 baseline 为什么不能依赖当前动作？

 为什么减去不依赖动作的 baseline 不改变梯度期望？

 最常用的 baseline 是什么？

 什么是 advantage function？

- A(s,a)>0
 和 A(s,a)<0 分别对策略更新意味着什么？

 为什么 advantage 比原始 return 更适合更新策略？

 Advantage normalization 有什么作用？

### 六、Actor-Critic 与 GAE
 Actor-Critic 中 Actor 和 Critic 分别是什么？

 Critic 通常学习什么函数？

 Actor 如何使用 Critic 的输出更新策略？

 请写出 TD error 作为 advantage 估计的公式。

 Actor-Critic 相比 REINFORCE 的优势是什么？

 Actor-Critic 的潜在风险是什么？

 A2C 和 A3C 的区别是什么？

 Actor-Critic 的常见 loss 由哪几部分组成？

 什么是 GAE？

 GAE 中 lambda 控制什么？

- lambda=0
 和 lambda=1 分别接近什么？

 为什么 PPO 中常用 GAE？

### 七、探索、TRPO 与实现细节
 熵正则在策略梯度中有什么作用？

 熵系数过大或过小分别会怎样？

 策略梯度中为什么要限制单次策略更新幅度？

 TRPO 的核心约束是什么？

 TRPO 为什么被称为信赖域方法？

 TRPO 的主要工程缺点是什么？

 为什么 PPO 可以看作对 TRPO 思想的简化？

 采样动作时保存 log probability 有什么用？

 为什么 actor loss 中 advantage 通常要 detach？

 连续动作策略中 log probability 计算容易出什么错？

 策略梯度训练中 reward scale 会产生什么影响？

 如果策略 entropy 很快降到接近 0，说明什么问题？

### 八、LLM/RLHF 场景
 在 LLM 中，state、action、policy 可以分别对应什么？

 LLM 序列生成中一条 trajectory 如何定义？

 为什么 RLHF 可以看成策略梯度问题？

 在 LLM 策略梯度中，token-level log probability 为什么重要？

 KL 约束在后续 PPO/RLHF 中为什么重要？

 请完整比较 REINFORCE、Actor-Critic、TRPO、PPO 的核心目标、优缺点和稳定化手段。

## 0x03. 十三：强化学习：策略梯度、REINFORCE 与 Actor-Critic自测题答案
> 发布日期：2026-06-03  
> 原文链接：[十三：强化学习：策略梯度、REINFORCE 与 Actor-Critic自测题答案](https://mp.weixin.qq.com/s/GavlEoZJV287_uAn0KiVlA)

### 参考资料
 CSDN：策略梯度和 REINFORCE 算法：https://blog.csdn.net/qq_64671439/article/details/137026601

 CSDN：多种 Actor-Critic 讲解：https://blog.csdn.net/qq_64671439/article/details/137611583

 动手学强化学习：策略梯度算法：http://hrl.boyuai.com/chapter/2/%E7%AD%96%E7%95%A5%E6%A2%AF%E5%BA%A6%E7%AE%97%E6%B3%95/

 动手学强化学习：Actor-Critic 算法：http://hrl.boyuai.com/chapter/2/actor-critic%E7%AE%97%E6%B3%95/

 动手学强化学习：TRPO 算法：http://hrl.boyuai.com/chapter/2/trpo%E7%AE%97%E6%B3%95/

 Williams, REINFORCE algorithm：https://link.springer.com/article/10.1007/BF00992696

 Sutton and Barto, Reinforcement Learning: An Introduction, Chapter 13：http://incompleteideas.net/book/RLbook2020.pdf

 Trust Region Policy Optimization：https://arxiv.org/abs/1502.05477

 High-Dimensional Continuous Control Using Generalized Advantage Estimation：https://arxiv.org/abs/1506.02438

### 评分标准
 合格：能写出策略目标、log-derivative trick、REINFORCE loss、baseline/advantage 的作用。

 良好：能解释 policy gradient theorem、Actor-Critic、GAE、entropy 和 TRPO。

 优秀：能把策略梯度迁移到 LLM/RLHF，能指出高方差、on-policy、KL 限制和实现细节风险。

### 一、策略方法基础
#### 1. 策略梯度方法和基于值函数的方法有什么核心区别？
 值函数方法先学习 V 或 Q，再通过贪心或采样选择动作。策略梯度直接参数化并优化策略 pi_theta(a|s)，用梯度让高回报动作概率增加。

#### 2. 为什么策略方法适合连续动作空间？
 连续动作空间无法枚举所有动作做 argmax_a Q(s,a)。策略方法可以直接输出高斯分布参数或动作值，避免在连续空间中显式最大化 Q。

#### 3. 什么是随机策略 pi_theta(a|s)？
 它是在状态 s 下选择动作 a 的概率分布，由参数 theta 控制。智能体从这个分布中采样动作。

#### 4. 离散动作策略通常如何参数化？
 通常用神经网络输出 logits，再经过 softmax 得到动作概率：
```text
pi_theta(a|s) = softmax(f_theta(s))[a]
```
#### 5. 连续动作策略通常如何参数化？
 常用高斯策略：
```text
a ~ N(mu_theta(s), sigma_theta(s)^2)
```
网络输出均值和方差或 log standard deviation。

#### 6. 为什么 LLM 生成可以看作一个随机策略？
 给定上下文，LLM 输出词表上每个 token 的概率分布。采样下一个 token 就是在状态下选择动作，因此是随机策略。

#### 7. 策略方法相比 Q-learning/DQN 的优势是什么？
 能直接表示随机策略，适合连续动作和高维概率分布，不需要对动作做显式 argmax，与 LLM token 分布天然匹配。

#### 8. 策略方法的主要缺点是什么？
 梯度估计方差高、样本效率低、on-policy 数据成本高、对奖励尺度和学习率敏感，更新过大时策略可能崩坏。

### 二、策略目标与轨迹概率
#### 9. 策略优化目标 J(theta) 通常如何定义？
 常见定义是期望回报：
```text
J(theta) = E_{tau ~ pi_theta}[G_0]
```
目标是最大化该值。

#### 10. 一条轨迹 tau 的概率如何分解？
```text
P_theta(tau)
= rho_0(s_0) product_t pi_theta(a_t|s_t) P(s_{t+1}|s_t,a_t)
```
其中只有策略项直接依赖 theta。

#### 11. 为什么环境转移概率在策略梯度中不需要求导？
 环境转移 P(s'|s,a) 通常不由策略参数控制，对 theta 的梯度为 0。策略梯度只需要对 pi_theta(a|s) 求导。

#### 12. 什么是状态访问分布 d^pi？
 它表示在策略 pi 下各状态被访问的概率或折扣访问频率。策略改变会改变该分布。

#### 13. 策略梯度为什么通常做梯度上升？
 因为目标是最大化期望回报 J(theta)，所以参数沿 grad J 方向更新。实现中若使用 loss，则最小化 -J。

#### 14. 在深度学习框架中，为什么常把策略梯度目标写成 loss 的负号？
 优化器默认最小化 loss。将目标取负，例如：
```text
loss = -log pi(a|s) * advantage
```
最小化 loss 等价于最大化策略目标。

#### 15. 策略分布变化为什么会导致训练数据分布变化？
 策略决定动作，动作影响后续状态和轨迹。策略一变，访问到的状态、动作和奖励分布也会改变。

#### 16. 为什么策略梯度通常是 on-policy 的？
 标准策略梯度要求数据来自当前策略 pi_theta，否则梯度估计对应的是旧策略分布。off-policy 需要重要性采样或其他修正。

### 三、Log-derivative Trick 与策略梯度定理
#### 17. 请写出 log-derivative trick。
```text
grad_theta p_theta(x)
= p_theta(x) grad_theta log p_theta(x)
```
#### 18. log-derivative trick 如何用于对期望求梯度？
```text
grad E_{x~p_theta}[f(x)]
= E_{x~p_theta}[f(x) grad log p_theta(x)]
```
它把对分布的梯度转化为对 log probability 的梯度。

#### 19. 请写出基于轨迹回报的 REINFORCE 梯度形式。
```text
grad J(theta)
= E_tau [G_0 sum_t grad log pi_theta(A_t|S_t)]
```
更常用 reward-to-go：
```text
E[sum_t grad log pi(A_t|S_t) G_t]
```
#### 20. 请写出 policy gradient theorem 的常见形式。
```text
grad J(theta)
∝ E_{s~d^pi,a~pi}[grad log pi_theta(a|s) Q^pi(s,a)]
```
也常用 advantage 替代 Q。

#### 21. grad log pi(a|s) 的直觉含义是什么？
 它表示如何改变参数才能增加当前动作在当前状态下的概率。

#### 22. Q^pi(s,a) 在策略梯度中扮演什么角色？
 它是权重或信用分配信号。高 Q 动作的 log probability 应增加，低 Q 动作应降低。

#### 23. 为什么高回报动作的概率会被增加？
 梯度项是 grad log pi(a|s) * return/advantage。当权重为正时，梯度上升会提高该动作概率。

#### 24. 策略梯度是否需要对 argmax 求导？这和 DQN 有什么不同？
 不需要。策略梯度直接对采样动作的 log probability 求导。DQN 通过 argmax 选动作，但 Q-learning 的更新本身不是对 argmax 策略端到端求导。

### 四、REINFORCE
#### 25. REINFORCE 是什么类型的算法？
 REINFORCE 是 Monte Carlo policy gradient 算法。它用完整采样回报估计策略梯度。

#### 26. 请写出 REINFORCE 的更新方向。
```text
sum_t grad log pi_theta(A_t|S_t) * G_t
```
#### 27. 请写出 REINFORCE 常见 loss 形式。
```text
loss = - sum_t log pi_theta(A_t|S_t) * G_t
```
加入 baseline 后：
```text
loss = - sum_t log pi(A_t|S_t) * (G_t - b(S_t))
```
#### 28. REINFORCE 为什么通常要等 episode 结束？
 因为它使用 Monte Carlo return，需要知道从当前时刻到 episode 结束的完整未来奖励。

#### 29. 什么是 reward-to-go？
 从时刻 t 之后开始的回报：
```text
G_t = R_{t+1} + gamma R_{t+2} + ...
```
#### 30. reward-to-go 相比整条轨迹回报有什么好处？
 它避免让动作对发生在自己之前的奖励负责，减少无关噪声，降低梯度方差。

#### 31. REINFORCE 的主要方差来源是什么？
 轨迹采样随机性、环境转移随机性、长 horizon 累计奖励、稀疏奖励和策略采样都会带来高方差。

#### 32. REINFORCE 在长 horizon 任务中为什么难训练？
 奖励延迟长、信用分配困难、回报方差大，需要大量 episode 才能得到可靠梯度估计。

### 五、Baseline 与 Advantage
#### 33. 为什么要在策略梯度中引入 baseline？
 baseline 用来降低梯度估计方差，让更新关注动作相对当前状态平均水平的好坏。

#### 34. baseline 为什么不能依赖当前动作？
 如果 baseline 依赖动作，会改变不同动作的相对梯度权重，从而引入偏差。只依赖状态的 baseline 不改变梯度期望。

#### 35. 为什么减去不依赖动作的 baseline 不改变梯度期望？
 因为：
```text
E_a[grad log pi(a|s) b(s)]
= b(s) grad sum_a pi(a|s)
= b(s) grad 1
= 0
```
#### 36. 最常用的 baseline 是什么？
 状态价值函数：
```text
b(s) = V^pi(s)
```
#### 37. 什么是 advantage function？
```text
A^pi(s,a) = Q^pi(s,a) - V^pi(s)
```
它表示动作比当前状态平均动作好多少。

#### 38. A(s,a)>0 和 A(s,a)<0 分别对策略更新意味着什么？
 A>0 增加该动作概率， A<0 降低该动作概率。

#### 39. 为什么 advantage 比原始 return 更适合更新策略？
 它去掉状态本身好坏的公共偏移，只保留动作相对好坏，方差更低，更新方向更清晰。

#### 40. Advantage normalization 有什么作用？
 把 advantage 标准化到较稳定尺度，降低 reward scale 对更新幅度的影响，使训练更稳定。

### 六、Actor-Critic 与 GAE
#### 41. Actor-Critic 中 Actor 和 Critic 分别是什么？
 Actor 是策略网络，负责选择动作。Critic 是价值网络，负责估计 V 、 Q 或 advantage，为 actor 提供学习信号。

#### 42. Critic 通常学习什么函数？
 常见是状态价值 V_w(s)，也可以学习动作价值 Q_w(s,a)。

#### 43. Actor 如何使用 Critic 的输出更新策略？
 Actor 用 critic 估计的 advantage 作为权重：
```text
loss_actor = -log pi(a|s) * advantage
```
#### 44. 请写出 TD error 作为 advantage 估计的公式。
```text
delta_t = R_{t+1} + gamma V(S_{t+1}) - V(S_t)
```
这个 TD error 可以作为一步 advantage 估计。

#### 45. Actor-Critic 相比 REINFORCE 的优势是什么？
 可以在线或短轨迹更新，不必等完整 episode；用 critic bootstrap 降低方差；样本效率通常更高。

#### 46. Actor-Critic 的潜在风险是什么？
 critic 估计有偏会误导 actor；actor 和 critic 同时学习可能不稳定；value loss 和 policy loss 的权重需要调节。

#### 47. A2C 和 A3C 的区别是什么？
 A2C 是同步 Advantage Actor-Critic。A3C 是异步多 worker 更新。A3C 通过异步并行减少样本相关性，A2C 更易实现和复现。

#### 48. Actor-Critic 的常见 loss 由哪几部分组成？
 通常包括 policy loss、value loss 和 entropy bonus：
```text
loss = policy_loss + c1 *value_loss - c2* entropy
```
#### 49. 什么是 GAE？
 GAE 是 Generalized Advantage Estimation，用多步 TD error 的指数加权和估计 advantage：
```text
A_t = sum_l (gamma lambda)^l delta_{t+l}
```
#### 50. GAE 中 lambda 控制什么？
 控制 bias-variance 权衡。 lambda 越大，越接近 Monte Carlo，bias 低方差高；越小，越接近一步 TD，方差低但 bias 高。

#### 51. lambda=0 和 lambda=1 分别接近什么？
 lambda=0 接近一步 TD advantage。 lambda=1 接近 Monte Carlo advantage。

#### 52. 为什么 PPO 中常用 GAE？
 PPO 需要稳定、低方差且不过度有偏的 advantage 估计。GAE 提供了可调的折中。

### 七、探索、TRPO 与实现细节
#### 53. 熵正则在策略梯度中有什么作用？
 鼓励策略保持随机性，防止过早塌缩到单一动作，提高探索。

#### 54. 熵系数过大或过小分别会怎样？
 过大使策略长期过于随机，难以利用高价值动作。过小可能导致探索不足和早熟收敛。

#### 55. 策略梯度中为什么要限制单次策略更新幅度？
 策略更新过大会让数据分布剧烈变化，旧样本失效，性能可能突然崩坏。限制更新能提高稳定性。

#### 56. TRPO 的核心约束是什么？
 最大化 surrogate objective，同时约束新旧策略 KL：
```text
E[KL(pi_old(.|s), pi_new(.|s))] <= delta
```
#### 57. TRPO 为什么被称为信赖域方法？
 因为它只允许策略在 KL 定义的可信区域内变化，避免单次更新离旧策略太远。

#### 58. TRPO 的主要工程缺点是什么？
 实现复杂，涉及二阶近似、Fisher-vector product、共轭梯度和 line search，调试成本较高。

#### 59. 为什么 PPO 可以看作对 TRPO 思想的简化？
 PPO 用 ratio clipping 或 KL penalty 限制策略变化，不需要复杂二阶优化，以更简单方式近似 trust region。

#### 60. 采样动作时保存 log probability 有什么用？
 后续计算 policy loss、importance ratio 和 PPO ratio 时需要旧策略下该动作的 log probability。

#### 61. 为什么 actor loss 中 advantage 通常要 detach？
 避免 actor loss 的梯度反向更新 critic 或 advantage 估计网络。critic 应由 value loss 更新。

#### 62. 连续动作策略中 log probability 计算容易出什么错？
 常见错误包括方差参数未约束为正、动作维度求和错误、tanh squash 后漏掉 log-prob 修正、采样动作和 log prob 不匹配。

#### 63. 策略梯度训练中 reward scale 会产生什么影响？
 reward scale 直接影响 advantage 尺度，从而影响策略更新步长。过大可能更新爆炸，过小学习慢。

#### 64. 如果策略 entropy 很快降到接近 0，说明什么问题？
 说明策略过快变得确定，探索不足，可能陷入局部最优。可增大 entropy bonus、降低学习率或调整 reward scale。

### 八、LLM/RLHF 场景
#### 65. 在 LLM 中，state、action、policy 可以分别对应什么？
 state 是当前 prompt、历史 token 和上下文；action 是下一个 token 或高层回复动作；policy 是 LLM 给出的 token 概率分布。

#### 66. LLM 序列生成中一条 trajectory 如何定义？
 从 prompt 开始，逐 token 生成直到 EOS 或最大长度，整个 token 序列加最终奖励构成 trajectory。

#### 67. 为什么 RLHF 可以看成策略梯度问题？
 RLHF 用奖励模型或人类偏好给生成结果打分，再更新语言模型策略，使高奖励输出概率上升。核心仍是 grad log pi * advantage/reward。

#### 68. 在 LLM 策略梯度中，token-level log probability 为什么重要？
 每个生成 token 的 log probability 决定该 token 动作的策略梯度。PPO/RLHF 还需要新旧 log prob 计算 ratio 和 KL。

#### 69. KL 约束在后续 PPO/RLHF 中为什么重要？
 限制新策略偏离 SFT/reference model 过远，防止语言质量崩坏、奖励模型过优化和安全行为丢失。

#### 70. 请完整比较 REINFORCE、Actor-Critic、TRPO、PPO 的核心目标、优缺点和稳定化手段。
 REINFORCE 用完整回报做 Monte Carlo 策略梯度，简单但方差高。Actor-Critic 用 critic 估计价值或 advantage，降低方差、可在线更新，但 critic 偏差会影响 actor。TRPO 用 KL trust region 限制策略更新，稳定但实现复杂。PPO 用 clipping/KL penalty 近似 TRPO，工程简单、稳定性好，是后续 RLHF 的重要基础。
