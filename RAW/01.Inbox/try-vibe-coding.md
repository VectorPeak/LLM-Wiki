# 安装梯子以及Codex/Claude Code
## 网络访问与环境准备
### 安装代理工具/平台:
1. [Clash for Windows v0.20.39](https://github.com/clash-download/Clash-for-Windows/releases/tag/v0.20.39)
	- 个人判断黑马教室的交换机环境可能存在一定的网络过滤。在这套方案下，开启 TUN 模式后，通常可以正常访问外网
2. 备选方案请安装: [Clash Verge](https://www.clashverge.dev/install.html)
    -  需要注意的是，使用这套备选方案时，教室网络往往无法直接访问外网，通常需要切换到手机热点或使用手机流量才能正常联网
### 选择机场并获取订阅  
选择一个可用的机场服务，购买订阅中转流量的服务器。可参考以下站点：
1. [https://ca.gobitz.net/#/login](https://ca.gobitz.net/#/login)辰哥用的,大概23元/月
2. [https://balala.io/auth/login](https://balala.io/auth/login)稍微便宜量大一点,大概18元/月
3. 购买套餐后，找到对应的订阅链接，使用 Clash 或 Clash Verge 进行一键导入

### 进行联网测试  
1. 尝试访问 [https://www.google.com/](https://www.google.com/)   
2. 尝试访问 [https://www.youtube.com/](https://www.youtube.com/)
- **如果这两个网站都可以正常打开，说明外网访问基本配置成功**    

- **需要注意的是, 如果在后续开发过程中，如果遇到一些看起来比较奇怪的问题，比如：**
    - 某些网站始终打不开
	- 某些依赖无法下载
	- 某些端口服务起不来
	- 某些本地开发工具联网异常
	- **不要急着怀疑代码或环境本身，先优先检查是不是代理配置、网络切换，或者 TUN 模式导致的问题**

### 关于梯子的其他问题

**不同价格的梯子有什么区别?**
-  **便宜的**梯子，一般特点是：**服务器少、速度一般、容易拥堵、可用设备数有限，客服响应和隐私保障也比较弱**。
-  **贵一点的**梯子，通常会在这些方面做得更好：**速度更稳定、节点更加干净、支持流媒体、支持更多设备同时在线、功能更完整**。
-  整体来看，大多数常见梯子的订阅价格通常都在 10-30 元 / 月 这个区间。

**为什么不建议用免费的梯子？**
- 天下没有免费的午餐。海外流量中转本身就是有成本的，服务器、带宽、维护都要花钱，所以“免费”本身就值得警惕
- 你的所有海外访问流量，本质上都是经过梯子节点中转的。也就是说，你访问什么网站、发什么请求、传什么数据，理论上它都能看到
- 免费梯子之所以免费，往往只是因为它会从别的地方把钱赚回来，而那个代价通常不是你显性支付的金钱，而是你的**隐私、安全性和稳定性**

**如何判断梯子的节点是否干净？**
- 可以使用这个网站初步检查节点的干净程度和网络环境:- [https://ping0.cc/](https://ping0.cc/)
- **不要经常切换使用的节点**，如果你的IP经常发生异常变换，谷歌/OpenAI可能会对你进行封号

**面试时不要说自己没用过梯子**
- 在大模型应用开发这个赛道中，如果你直接说自己从来没用过梯子，等于你在告诉面试官：
	- 你几乎不使用 Github，甚至连从Github clone项目都不会
	- 你从未使用过 Claude Code/Codex 这类AI coding工具
	- 国外大模型平均领先国内模型6-7个月，不用梯子意味着你从未接触过较为先进的领先模型
	- 你对行业动态、开源热点、新工具的跟进能力是几乎没有

**作为程序员，可以不使用梯子吗？**
- **不可以，如果实在不想花钱去买梯子，联系宁姐进行退款，这一行确实不太适合你们（很严肃啊，不是开玩笑的）**



## Codex 与 Claude Code 安装
### 安装 Codex
- 整个教程是基于 Codex 进行教学的, 因为便宜大碗、量大管饱, `GPT-5.4` 模型能力比较强, 而 `Claude Opus4.6` 太贵。
- 选择 Codex 是综合考虑性价比最高的选择。
- 需要购买 1 个谷歌账号, 需要订阅 `ChatGPT Plus` 会员

### Codex 发行版本（强烈建议都安装）
- `Codex-desktop`（桌面应用）: [https://openai.com/zh-Hans-CN/codex/](https://openai.com/zh-Hans-CN/codex/)
- `Codex-cli`（命令行版本）: 
	- **https://www.runoob.com/codex/codex-install.html**
	- [https://developers.openai.com/codex/cli](https://developers.openai.com/codex/cli)
	
	- `PS`: 安装 codex 命令行版本前, 需要先安装 `node.js`(推荐版本 `Node.js 22.22.2 LTS`) 以及`Git`
	- node.js: [https://nodejs.org/en/download/](https://nodejs.org/en/download/)
	- Git: [https://git-scm.com/install/windows](https://git-scm.com/install/windows)
 
	- 如果实在不懂如何进行安装, 请先询问 AI

- `Codex-IDE-plugins`（IDE 内置插件）
	- `Pycharm` 安装 IDE 插件:
![PyCharm 安装 Codex 插件 1](https://vectorpeak-1318670795.cos.ap-guangzhou.myqcloud.com/vibe-coding/pycharm-codex-1.png)
![PyCharm 安装 Codex 插件 1](https://vectorpeak-1318670795.cos.ap-guangzhou.myqcloud.com/vibe-coding/pycharm-codex-1.png)
![PyCharm 安装 Codex 插件 3](https://vectorpeak-1318670795.cos.ap-guangzhou.myqcloud.com/vibe-coding/pycharm-codex-3.png)
- `VSCode` 安装 IDE 插件:
![VS Code 安装 Codex 插件](https://vectorpeak-1318670795.cos.ap-guangzhou.myqcloud.com/vibe-coding/vscode-codex.png)


###关于Codex的其他问题

**可不可以不安装Codex？或者不购买ChatGPT-plus会员?**
- AI coding一定是未来的趋势和方向，请务必接触最先进的AI coding工具
- 不可以, 在以后实际的工作中, 写代码可能有50~70%的时间都是要跟Claude Code/Codex打交道
- 我跟辰哥讨论过这件事，使用AI工具很重要，辰哥也在向领导申请给你们补一下这方面的课程
- 我个人对比了很多方案，帮你们进行了筛选。36元/月的GPT-plus已经是性价比最高的方案了.....如果你连这个小钱都舍不愿意花，那我也不说什么了，不干涉他人命运，尊重他人选择

**额度用不完?**
- 订阅了 AI coding 工具之后放在那里吃灰, 不知道怎么用, 你赔我钱
- 这是个人水平问题, 说明你的个人水平有待提高
- 我向我周围有基础的开发都推荐了 Codex, 进行了一波小范围的内部测试。大家普遍的反应都是额度不够用, 写代码正反馈非常强, 普遍提效在 80% 以上

**不愿意为工作提效付费**
- 我的建议是每个月至少拿出来 100 元的预算来强制性购买 AI 工具 / Token 额度, 借此强迫自己使用 AI 工具
- 学会投资自己, 这是一种思维


### 安装 Claude Code
#### Claude Code 安装前置依赖
同上 `Codex` 安装前置依赖，在前面已经安装过的同学就不必继续安装了:
- 需要安装 `node.js`（推荐版本 `Node.js 22.22.2 LTS`）以及 `Git`。
- node.js: [https://nodejs.org/en/download/](https://nodejs.org/en/download/)
- Git: [https://git-scm.com/install/windows](https://git-scm.com/install/windows)
    
- 如果实在不懂如何进行安装, 请先询问 AI。

#### Claude Code 安装前置（建议安装 CLI 以及 IDE 插件版本）
- `Claude-cli`（命令行版本）: [https://code.claude.com/docs/en/quickstart](https://code.claude.com/docs/en/quickstart)
- `Claude-IDE-plugins`（IDE 内置插件）
	- 建议参考上一章节 `Codex-IDE-plugins` 安装方式

#### 将国产大模型 API 接入 Claude Code
-  [https://m.runoob.com/claude-code/coding-plan.html](https://m.runoob.com/claude-code/coding-plan.html)

#### 注册ChatGPT账号全流程
1. 购买谷歌账号（或者你本身有谷歌账号也行）, 一定要去买几年以上的老账号, 不要贪图便宜去买新号, 容易被封 `ChatGPT` 账号（花费 `11.80 元 / 永久`）
2. 登陆谷歌账号, 修改谷歌账号密码以及其他信息/绑定手机号（可选，只是为了账号安全而已）
	- 在购买谷歌账号后, 会得到这样一串信息:
	-  `zelindroodu32ldo783@gmail.com`（谷歌账号）`----gtbsdfroin`（账号密码）`----tmeswpwgpkeq6kxbeyidadanmjzqdm`（2FA Secret）
	- ![2FA 示例图](https://vectorpeak-1318670795.cos.ap-guangzhou.myqcloud.com/vibe-coding/2fa.cn.png)

3. 用谷歌账户登陆 `ChatGPT`, 使用谷歌账号来 注册 `ChatGPT` 账号。
	- 注册 ChatGPT 账号: [https://chatgpt.com/auth/login](https://chatgpt.com/auth/login)

4. 下载 Codex 以及 ChatGPT（谷歌应用商店）
	- 下载 Codex: [https://openai.com/zh-Hans-CN/codex/](https://openai.com/zh-Hans-CN/codex/)
	- 下载 ChatGPT: [https://chatgpt.com/zh-Hans-CN/download/](https://chatgpt.com/zh-Hans-CN/download/)
	- 然后使用谷歌账号登陆 Codex 以及 ChatGPT

5. 前往海鲜市场, 搜索 **普拉斯**
	订阅特殊渠道的 `ChatGPT Plus`（花费 `36 元 / 月`, 有被封 ChatGPT 账号的风险）
	- **也可以选择这些网站进行直冲：**
		- https://pay.ldxp.cn/shop/C1V67W46
		- https://pay.ldxp.cn/shop/76Z1ZVTW
		- https://tundershop.shbs.club/
	- 没有ChatGPT账号的，也可以直接在这里购买Chat-GPT成品号->加号贩子QQ：515847796（大概是35元/月）
	- 我给你们推荐这个也是要担点风险了（这个班里面有很多应届生啊，以后真到了社会上了不推荐这么干了。因为给别人推荐某个好用的工具是没好处拿的，很多零基础的学员配错了还要来怪你，干好了没收益，干坏了全是惩罚），你们自己操作失误了买错账号/充错号了别找我......
	- ![fishmarket](https://vectorpeak-1318670795.cos.ap-guangzhou.myqcloud.com/vibe-coding/fishmarket.jpg)
7. 不差钱的可以选择从代充网站购买 `ChatGPT Plus`（花费 `179 元 / 月`）
	- [https://getgpt.pro/](https://getgpt.pro/)
	
8. 回到 ChatGPT 账号, 账号左下角出现 `Plus` 标识, 证明充值成功
	- ![Codex 截图 4](https://vectorpeak-1318670795.cos.ap-guangzhou.myqcloud.com/vibe-coding/codex-4.png)
## 玩一玩 Codex
### 初认Codex
- codex 界面一览:
![codex-overview-1](https://vectorpeak-1318670795.cos.ap-guangzhou.myqcloud.com/vibe-coding/codex-overview-1.png)

- 查看 Token 额度剩余用量:
![codex-overview-2](https://vectorpeak-1318670795.cos.ap-guangzhou.myqcloud.com/vibe-coding/codex-overview-2.png)

- 点击设置 / 进行个性化设置（自定义指令):
![codex-overview-3](https://vectorpeak-1318670795.cos.ap-guangzhou.myqcloud.com/vibe-coding/codex-overview-3.png)

- Plugins / MCP / Skills-->直接去插件看就行了
### 玩一玩 Codex
- **清理 C 盘中多余的文件**
    
    - **提示词**: 我的 C 盘太满了。帮我清理磁盘空间, 优先保证安全, 不要一上来直接删除文件。最好给我一个列表, 列出占用空间较大的文件 / 应用, 同时告知我这些应用的用途, 然后我会进一步告诉你应该删除哪些文件。
        
    - `P.S.` 如果你是零基础的同学, 不要去清理 C 盘里面的东西。把提示词中的 `C 盘` 改成 `E 盘`, 我是真怕你们把操作系统给搞废了。
        
- **生成贪吃蛇游戏**
    
    - **提示词**: 在 `Desktop` 创建一个文件夹。然后生成一个贪吃蛇游戏（非常简单的练手本地项目）, 使用计划模式, 让我自行选择需要的技术栈。
        
- **整理黑马 markdown 文件**
    
    - **提示词**: 扫描整个电脑, 定位到 `02_大模型语言进阶` 文件夹。读取该文件夹下 `/03-笔记` 以及子文件夹下的所有 `md` 文件。提取这些 `md` 文件中的内容, 整合成一个 `md` 新文件。重命名为 `02_大模型语言进阶笔记.md`, 新生成的 `md` 文件请放到 `Desktop` 桌面。
        
- **写一个辅助学习 skill**
    
    - **提示词**: 请生成一个 skill, 名为 `learning-assistant`。你是我的计算机学习辅助助手: 输入的内容通常是 `Redis`、模板元编程、链表、操作系统、网络、数据库这类 CS 概念。请你从工程化和写代码的角度帮我学习。输出包括:
        1. 这个概念是做什么的
        2. 核心原理
        3. 在实际开发中的作用
        4. 常见代码场景或使用方式
        5. 容易犯错的点
        6. 面试会怎么问
        7. 用通俗的话帮我复述一遍
            
- 在以后的开发过程中：如果有不懂的、不会的东西, 或者配置环境出了问题, 直接截图 / 扔给 codex 处理就行了

---

# Vibe Coding
## 1.AI应用开发行业通用素养

行业素养可以作为一个考察的方向，其实非常重要。这是在我不断面试的时候才慢慢总结出来的。他不是硬知识，问你专业问题。而是一种素养/隐型知识。比如面试官问题：你使用过什么 AI Coding 工具呀？你有没有了解过 Openclaw 啊？你平时怎么用 AI 工具的呀？你看过哪些论文吗？

这些问题看似不经意间对吧，如果有面试官问我们用什么 AI Coding 工具，有没有用过 Claude Code？Codex？Cursor？Open Code？你回答我只用过豆包，那面试不就废了？

其实这些问题很重要，体现你的行业素养。比如用什么 AI 工具，怎么用的？平时一个月能在 AI工具/Token额度 这件事上花多少钱？这是体现你有没有积极拥抱 AI，用 AI 的技巧。比如你使用 codex、claude code，他们可能各有优势，你有没有了解他们的优势？他们的进阶用法？没有的话，说明你这个使用 AI 的技巧不行。

你有没有了解 Openclaw？如果你没了解，说明你没有关注行业动态。他作为 Agent 行业爆款应用，他有哪些特点值得学习？你竟然没去看吗？面试官觉得你会了解行业动态。

包括论文，大模型这个行业需要读论文的，即使是开发，原因我在论文章节提了。

所以我把这些归为行业素养，但他同样很重要，在面试中考察频率很高。

这块怎么学习，与时俱进吧，抓住动态。当然我自己一直在总结，比如新的东西，Openclaw 的架构，SKILL，论文。 一起讨论，一起更新。

---
## 2. 追热点/技术敏感度
### 2.1 追热点

- **这个方向技术栈更新速度非常快，可以说是对“追热点”要求最高的方向，没有之一**。在前端开发最鼎盛的时期，几乎是一年换一套框架，但是更新速度似乎还不及这个方向

- 你很难像传统开发那样，学完一套稳定技术栈就吃很多年。大模型、Agent、工具链、工作流、框架形态都在快速变化，很多新东西几个月前还没人提，几个月后就已经变成面试话题、项目卖点，甚至岗位要求

- 只看最近这一段时间，自 2026.3.1 以来，至少就有这些方向值得持续关注：
	- Harness Engineering
	- OpenClaw
	- Kimi 注意力残差
	- Claude Code 源码泄露

### 2.2 技术敏感度

- 本质上是对技术变化的**察觉能力**和**判断能力** 当一个新技术，新工具，新范式出现的时候，你必须快速判断：它到底有没有用，它会不会火，它可能哪些岗位、哪些工作流、哪些技术栈

- **判断自己的技术敏感度：** 
	- 几个程序员围在一起聊天，如果别人提到某个新技术、新工具，而你完全没听过，这时候至少要有一个基本反应：先记下来，回头立刻去查
	- 现场你可以先顺着听，不一定非要立刻暴露“完全不知道”，但转过头一定要马上用 AI、搜索、论文或者文档把它搞清楚。
	- **不能长期停留在不懂**。**别人已经开始讨论的东西，如果你过几天还是不知道，那技术敏感度就明显偏弱了**

- **产品思维：** 
	- **判断一个技术会不会火、会影响什么，往往需要一点产品思维** 因为很多技术问题，最后不只是技术问题，还和市场、用户需求、商业条件、硬件基础、落地成本有关。你不能只看“这个技术听起来厉不厉害”，还得看它有没有真正大规模落地的土壤
	- 元宇宙在 2023 年非常火，甚至facebook都改名成了meta。但如果当时稍微多想一步，就会发现它高度依赖 AR/VR 设备的普及。问题是，相关硬件在成本、体验、普及率上都没有真正成熟，所以最后虽然概念很热，但并没有形成足够广泛、稳定的需求，更多像是一波概念驱动的热潮
	- AI 应用开发（RAG + Agent）从 2025 年下半年开始需求明显爆发。这个时候如果你有一点市场感知，就会发现：连黑马这样的线下培训机构都已经开始围绕这个方向开班培训了。这本身就是一个很强的市场信号。大家需要清楚这类机构招收的平均学员素质是什么样的，培训机构开始为零基础小白进行系统化教学，往往意味着市场上已经有足够明显的岗位需求和招聘热度 

> [!info]
> 1.**不需要抢着做第一个知道新技术的人** 但如果大家都已经在讨论了，你就一定要尽快搞清楚它是什么
> 
> 2.**也不用把“追热点”理解成每天强行刷一堆资讯** 不需要把大量精力专门砸在这件事上，因为真正重要的信息、真正有影响力的成果，**最后一定会通过各种渠道被推送到你面前**：朋友圈、GitHub、X、公众号、技术群、面试题、课程、AI 总结、同事讨论，都会不断把信号送过来
> 
> 3.重要的是获取到这些信息之后进行**认真判断、快速理解、及时跟进** 。也不用焦虑到每个模型每个工具都及时弄通
> 

### 2.3 推荐信息来源
- **推荐信息来源**（后续会继续进行更新）
    - **微信公众号:（"AI 中文三大顶会", 强烈推荐）**
        - **机器之心**
        - **量子位**
        - **新智元**
    - 微信公众号:（技术大佬, **偏向 Vibecoding 实战**）
        - AI 编程实验室
        - 放之
        - 硅基鹿鸣
    - Bilibili:（UP 主推荐, **偏科普向, 初学者入门**）
        - [马克的技术工坊](https://space.bilibili.com/1815948385?spm_id_from=333.1387.follow.user_card.click)
    - Bilibili:（UP 主推荐, **偏 AI 应用开发**）
        - [骑猪撞宝马71](https://space.bilibili.com/1625561074/?spm_id_from=333.788.upinfo.detail.click)
        - [xhyovo](https://space.bilibili.com/152686439?spm_id_from=333.788.upinfo.detail.click)
        - [我是健健哥](https://space.bilibili.com/383749418?spm_id_from=333.788.upinfo.detail.click)   
    - Bilibili:（UP 主推荐, **偏 AI 算法 / 底层**）
        - [五道口纳什](https://space.bilibili.com/59807853?spm_id_from=333.1387.follow.user_card.click)
        - [东川路第一可爱猫猫虫](https://space.bilibili.com/675505667)
        - [海安雨](https://space.bilibili.com/2071007724/upload/video)
        - [王玉蝉](https://space.bilibili.com/291665445?spm_id_from=333.788.upinfo.detail.click)
    - Bilibili:（UP 主推荐, **偏 AI 算法 / 底层**）
        - [邓了个登](https://space.bilibili.com/3494377292827436)
        
---
## 3. Vibe Coding
### 3.1 vibe coding 简介

**什么是 vibe coding（氛围编程）？**
	**就是用自然语言描述需求, 让 AI 写代码**。你也可以称之为 AI coding
	
>[!info] 题外话
>- 总说AI一天，人间一年。但是这个方向的很多东西其实也没那么新，只是新瓶装旧酒，吹牛逼不说人话， 然后你们就又可以焦虑一轮了
>- 比如MCP，听着很唬人，其实本质上就是给AI定义了一个统一的工具调用协议，就跟USB接口一样，可以让不同的工具通过统一的方式接入大模型
>- 再比如Skills，就是把提示词和工具打包成一个可复用的模块（说白了就是预制菜啊，把做菜的步骤提前封装好）
>- 很多产品主打AI记忆，长期记忆，Insights.听起来很前沿。实际上就是把历史对话和个人偏好存下来，下一次对话的时候，直接调出来用，和之前的什么用户画像是一回事。所以其实也用不着这么焦虑，很多东西万变不离其宗
>- 大家只需要明白，都是半路转进来的水货。如果一个东西真的晦涩难懂，不可能有很高的传播度

**为什么vibe coding重要？**
- **从面试的角度来看：** 很多面试官都会问你 vibe coding 的相关经验，比如你最喜欢用哪个 Vibe Coding 工具、平时怎么用 AI 编程工具、有没有自己的使用方法论。这些问题看起来不像传统的硬知识考点，但本质上是在考察你有没有跟上新的开发范式。因为在新的时代里，拿AI写代码是绝对的趋势，如何高效地做 vibe coding、如何聪明地使用 AI 工具，已经成了企业会关注的能力。所以这类问题虽然不是标准八股，但绝对是面试中的热门话题，回答得好，一定会加分。

- **从个人成长的角度来看：** 现在谁还完全不用 AI 工具写代码呢？大家多多少少都会聊到自己是怎么使用 AI 工具的。学会高效使用 vibe coding，对个人成长是非常有帮助的。它不仅仅是提效工具，也是很强的学习工具。你怎么描述需求、怎么和 AI 协作、怎么审查 AI 的结果，这些都会直接影响你的工作效率和成长速度。以后在企业当中，可能有50-70%的时间，大家都是在用AI工具写代码的，我个人提出一条判断标准---如果你使用AI工具写代码的时间占比不足50%，那你的工作就很危险了。


**一个月花多少钱在vibecoding工具上是合适的？**
- **投入与收入正相关：** 厉害的人一定会用最好的工具，一个开发者在 Token 和 AI 工具上的投入，往往和收入水平有一定正相关。愿意持续投入 AI 工具的人，通常也更容易获得更高的效率和更强的竞争力，最后这种效率优势会慢慢反映到收入上。当然，这不是绝对因果，不是说“花得多就一定赚得多”，但至少说明一个问题：高产出的人，通常不会排斥为高效率工具付费

- 如果真的一分钱都不愿意花，那坦白说，不适合这个行业。因为这个行业本身就非常强调效率，而 AI 工具正在越来越快地变成基础生产力工具

- 投资自己的思维方式：要学会投资自己，对我们来说，很多投入本质上都不应该只看“花了多少钱”，而应该看“换回来了多少效率、多少成长、多少机会”

>[!info]
>**1.迎接变化：** 不管 AI 现在到底能做什么、能做到什么程度，只要老板看到了一个能快速生成的 Demo，就一定会开始思考：这件事能不能提效，团队能不能缩编，哪些岗位能不能按比例减少。未来三年，很可能会是整个计算机行业变化最剧烈、淘汰最残酷的三年，真的可以说是腥风血雨
>
>**2.正确看待Vibe Coding：** vibe coding工具，对高手来说是效率放大器，是生产力杠杆；但对基础不牢，内功不好，半瓶水晃荡的人来说，很可能是毒药
>
>**3.持续学习：** 未来能够立身的根本一定是持续学习和适应的能力
>

---
## 3.2 vibe coding 工具
### 3.2.1 Claude Code
- Claude Code 是 Anthropic 推出的 AI 编程 Agent。以对话的方式帮助开发者构建、调试、重构代码，以及构建自动化工作流。它不同于传统的代码补全工具（如 GitHub Copilot），而是一个可以自主规划、执行任务、**调用外部工具的智能代理**

-  Codex 本质上也是一个通用编程 Agent。它的核心价值不在于“补全几行代码”，而在于能够围绕真实开发任务展开工作，例如阅读项目、修改文件、运行命令、检查结果、再根据反馈继续迭代。某种意义上，它更像一个能协作的工程助手，而不是单纯的代码提示器

- 可以把 **Claude Code** 理解成“机器人本体”，而各类大模型（例如 Claude Opus 4.7、DeepSeek-V3、Qwen-3、GPT-5.4）更像是这个机器人的“大脑”  也就是说，Claude Code 提供的是工作方式、工具调用和交互框架，而真正决定推理和编码质量的，是背后接入的模型。

#### 3.2.2 Claude Code接入国产大模型方案
- 如果单看能力上限，Claude Code + Claude Opus 4.7 依然是目前市场上**性能最强、使用体验最好**的组合之一。但问题也很明显：**贵**，如果放开让它高强度跑代码、跑任务、跑工作流，一晚上花掉一百块并不夸张，只推荐给家里面五套房的同学们使用

- 由于 Anthropic 自家的高端模型价格确实比较高，所以更推荐把 Claude Code 当成一个工具平台，再按预算接入更便宜的国产模型使用 
- 推荐用 Claude Code 外接国产的 Coding Plan API，整体思路是：**便宜、量大、适合长期高频使用**
	-  [AI Coding Plan 对比](https://z4crk6mg95.coze.site/)
	-  [国内 LLM Coding Plan 订阅套餐对比](https://zhuanlan.zhihu.com/p/2006431542428315931)
	
	- 截止 2026-04-16，国产模型里表现最强的一档通常会提到 GLM-5.1，社区里也有不少人认为它已经接近 Claude Opus4.6 的能力上限
	- 但智谱的 Coding Plan 近期使用人数太多，高峰期限流问题比较明显，社区反馈并不好，现阶段不太推荐。
	- 相比之下，更建议优先选择支持 MiniMax 2.7 或 GLM-5.0 的 Coding Plan，整体体验和稳定性会更均衡一些
### 3.2.2 Codex
- Codex 是 OpenAI 推出的 AI 编程 Agent。它通过对话的方式帮助开发者完成代码编写、调试、重构，以及自动化开发任务的执行。它不只是传统意义上的代码补全工具，而是一个能够理解需求、规划步骤、调用工具并持续推进任务的智能编程代理

- 从能力形态上看，Codex 和 Claude Code、OpenCode 这类产品属于同一代工具：它们都在把“AI 写几行代码”推进到“AI 参与完整开发流程”。所以学习 Codex，不只是学一个产品本身，更是在学习一种新的开发方式。掌握了这种 Agent 式编程思路，再去理解同类工具，迁移成本通常会很低

- 我们基于Codex + GPT5.4进行教学，原因也非常简单：因为这套方案非常便宜。从日常高频使用的角度看，它的性价比非常高。如果你不是一味追求最贵、最顶的模型体验，而是希望在成本、稳定性和能力之间找一个更平衡的方案，那 Codex 会是一个非常合适的选择

- Codex更加适合进行**代码 Review**，Bug定位于修复以及偏工程化的修改任务。同时截止2026.4.16，用Codex写前端就是一坨屎
### 3.2.3 Cursor
- Cursor 是一个以 AI 为核心的代码编辑器，定位更接近“带 Agent 能力的 AI IDE”，而不只是代码补全插件。它主打几类能力：基于代码库上下文回答问题、用自然语言编辑代码、Tab 补全、Agent/后台 Agent，以及与 MCP、skills、hooks 等工作流能力集成

- 可以把它理解成“VS Code 风格的开发体验 + 更深度集成的 AI 编程工作流”。相比传统补全工具，Cursor 更强调：
	- 直接基于整个代码库理解上下文
	- 用自然语言批量修改函数、类、文件
	- 让 Agent 持续执行多步任务
	- 保留熟悉的编辑器体验，支持导入扩展、主题和快捷键
	
- Cursor没有自研大模型的能力，它的商业模型就是粘粑粑，背后主要接入的是 OpenAI、Anthropic 等模型 API。因为 Cursor 在 2024 年前后抢先吸引了一大批用户，很多人后来出于使用惯性、生态习惯和团队协作成本，继续留在了 Cursor 体系里

- 如果你的目标是**更稳定、更高频地使用 Claude 系模型**，那 Cursor 其实仍然是一个不错的选择。它在产品层把很多能力整合得比较顺手，对一部分用户来说，整体体验依然是比较成熟的。所以即使不谈技术理想，只从“拿来就用”和“量大管饱”的角度看，Cursor 仍然有它的现实价值

### 3.2.4 Gemini
- Gemini 是 Google 推出的 **AI Code Agent / AI 编程助手**，对应的开发工具体系主要包括 Gemini CLI 和 Gemini Code Assist（IDE 插件）。官方文档见：[Gemini CLI](https://developers.google.com/gemini-code-assist/docs/gemini-cli) 、[Gemini Code Assist](https://codeassist.google/)

- Gemini适合用来写前端，从社区口碑来看，Gemini 在**前端生成**这类任务上评价普遍不错，尤其是页面结构、样式铺设和偏 UI 的代码起稿，经常会给人“比较会写前端”的感觉

- Gemini的订阅门槛相对友好，在海鲜市场大概售价25元/月。订阅了Google AI Pro会员后，还可以使用Google 整个 AI 套件里的其他产品：
	- Nano Banana Pro：最强大的文生图模型之一
	- NotebookLM：最强大的PPT制作软件
	- 官方信息见：[Google AI Plans](https://one.google.com/about/ai-premium/)

### 3.2.5 国产vibe coding工具
- 个人强烈不建议把国产vibe coding工具作为主力工具

- 从整体产品成熟度、工作流完整性、稳定性和社区生态来看，主流国产方案和国外头部工具相比，通常还有一段差距。大概在5-6个月

**目前常见的国产vibe coding工具包括：**
	- Trae（字节系）：[官网](https://www.trae.ai/)
	- WorkBuddy / CodeBuddy Work（腾讯系）：[官网](https://www.codebuddy.cn/work/)
	- Qoder（阿里系）：[官网](https://qoder.com/)
**为什么现阶段不太推荐作为主力使用？**
	**第一.使用体验普遍不够稳定**：
		- 很多国产 Vibe Coding 工具前期看起来“免费”或者“门槛很低”，但一旦个人使用量上来，或者到了高峰时段，就容易出现限速、排队、降质、响应不稳定等问题。
		- 这类工具在轻度尝鲜时问题不大，但一旦进入高频、重度、工程化使用阶段，体验上的波动就会非常明显。
		- 最后用户往往还是得通过额外付费、内购加速或者更高套餐来解决问题
	**第二.它们的商业体验更像“基础免费 + 频繁限流 + 付费提速”的模式**
		- 一些国产工具更像是**网游内购制**，先让你进来玩，再通过限额、限速、功能差异来推动付费
		- 而国外不少工具更接近**付费买断 / 明确订阅制**，你先接受成本，然后换来更稳定、更可预期的使用体验
		- 两种模式没有绝对对错，但如果目标是拿来长期高频生产，后者通常更省心
	**第三.普遍不太支持 Harness Engineering**
		- 尤其是当你开始关注长任务、多步骤自动化、上下文管理、子代理协作、可恢复执行、工具调度这些更“工程化”的能力时，就会发现很多国产方案目前还停留在“能用”阶段，离“稳定可依赖地跑复杂任务”还有距离
**什么是 Harness Engineering?**
- **Harness Engineering**，可以理解成：围绕 AI 模型去构建一整套**运行环境、调度机制、权限控制、状态管理和执行基础设施**的工程实践。它关注的重点不是“让模型更聪明”，而是**让 AI Agent 在长时间、复杂、多步骤的真实任务里，依然能稳定、可靠、可控地运行下去**

- **说人话版本**: 你把一个产品的设计规范 SPEC、API 文档、数据库表结构、上下文规则一股脑交给 Agent。你去睡一觉，睡醒之后agent已经把大部分代码、脚手架、接口、测试甚至文档都跑出来了

---
### 3.3 vibe coding 技巧
### 3.3.1 vibe coding通用技巧


