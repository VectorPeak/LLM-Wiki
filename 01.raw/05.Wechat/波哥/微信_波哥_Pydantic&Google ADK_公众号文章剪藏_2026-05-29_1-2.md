---
title: "微信_波哥_Agent_公众号文章剪藏_2026-05-29_1-2"
source: "/api/v1/wechat_mp/web/fetch_mp_article_detail_html"
author:
  - "波哥"
published: "2026-05-28"
created: 2026-05-29
description: "TikHub 命中的微信公众号文章候选，共 2 条，本文档收录 2 条"
tags:
  - "clippings"
  - "wechat"
  - "波哥"
---

## 0x01. Agent 工程师需要了解的开发技术栈——Pydantic 与数据校验
> 发布日期：2026-05-28  
> 原文链接：[Agent 工程师需要了解的开发技术栈——Pydantic 与数据校验](https://mp.weixin.qq.com/s/tA8iL8P_TLBt8A1hETgV0g)

这是一期新连载，记录Agent工程师需要了解的开发技术栈

### 写在前面：这篇文章想讲清楚什么
 前两篇我们搭好了服务(FastAPI)、让它跑得快(异步)。但有一个贯穿始终却没被正面拆开的东西，一直藏在背后——上一篇 FastAPI 里那些 class ItemIn(BaseModel)，正是这一篇的主角： **Pydantic**。

 对 Agent 工程师来说，Pydantic 的分量比它表面看起来重得多。Agent 的本质，是把大模型的自然语言输出变成程序能 **可靠执行** 的动作。而这中间最脆弱的一环，恰恰是"模型吐出来的一段文本"和"代码需要的、类型正确、字段齐全的结构化数据"之间的鸿沟。模型可能漏字段、给错类型、把数字写成字符串、编造出不存在的枚举值。没有一道校验关卡，这些脏数据会一路渗进你的业务逻辑，在最意想不到的地方炸开。

 Pydantic 就是缝合这道鸿沟的工具。它既是 FastAPI 的地基，又是当下几乎所有"LLM 结构化输出""工具调用""函数调用"功能的底层校验引擎。

 这篇文章只围绕一条主线展开：

 **怎么让"不可信的外部数据"——尤其是大模型的输出——安全地变成"程序可以放心使用的结构化对象"？** 顺着这条线，我们依次回答：

 为什么需要它？——手写校验的痛，和 Pydantic 的解法

 怎么定义一个数据模型？—— BaseModel 与类型注解

 校验到底在什么时候、怎么发生？——实例化即校验，与类型强制

 内置规则不够用怎么办？——字段约束与自定义校验器

 数据是嵌套的、复杂的怎么办？——嵌套模型与组合类型

 校验完怎么把它送出去？——序列化与 model_dump

 把它用在刀刃上——给大模型的输出套一道结构化护栏

 读完你应该建立这样一个心智模型： **Pydantic 模型是一道"类型安全的关卡"——任何数据想变成对象，必须先通过这道关卡的校验；通过了，你就能像信任自己写的代码一样信任这份数据。**

### 1. 为什么需要它：手写校验的痛

 **要解决的问题**：从外部拿到的数据(API 请求、配置文件、大模型输出)都是不可信的。怎么确保它字段齐全、类型正确，再交给业务逻辑？

 设想一个最普通的需求：接收一份用户数据 {"name": ..., "age": ..., "email": ...}，要求 name 是字符串、age 是正整数、email 格式合法。不用任何工具，手写校验会是这样：
```python
def validate_user(data: dict):
    if "name" not in data or not isinstance(data["name"], str):
        raise ValueError("name 必须是字符串")
    if "age" not in data or not isinstance(data["age"], int) or data["age"] <= 0:
        raise ValueError("age 必须是正整数")
    if "email" not in data or"@" not in data["email"]:
        raise ValueError("email 格式错误")
    # ……每多一个字段，就多一段 if
    return data
```
这段代码的问题不在于难写，而在于： **它会随着字段增多而无限膨胀，校验逻辑和数据结构定义是割裂的，而且没有任何类型提示** ——你拿到 data["age"] 时，IDE 并不知道它是 int。

 Pydantic 把这一切压缩成一次"声明"：你只描述 **数据应该长什么样**，校验逻辑由它自动生成。
```python
from pydantic import BaseModel, EmailStr, PositiveInt

class User(BaseModel):
    name: str
    age: PositiveInt        # 自带"正整数"约束
    email: EmailStr         # 自带邮箱格式校验

### 校验、类型转换、报错，全自动
user = User(name="Alice", age=30, email="alice@example.com")
print(user.age)             # 30，而且 IDE 知道它是 int
```
核心思想的转变： **从"写一段一段的校验代码"，变成"声明一个数据的形状"**。形状定义好了，校验是免费附赠的。

 **承上启下**：上面那个 class User(BaseModel) 就是 Pydantic 的全部入口。它凭什么只靠几行类型注解就完成了校验？先得看清楚"定义一个模型"到底定义了什么。

### 2. 怎么定义模型：BaseModel 与类型注解
 **要解决的问题**：怎么用最少的代码，把"数据应该长什么样"完整地描述清楚？

 答案是： **继承** **BaseModel，然后用类型注解逐个声明字段**。Pydantic 会把这些注解读出来，自动构建出校验逻辑。
```python
from pydantic import BaseModel

class Product(BaseModel):
    name: str                      # 必填，字符串
    price: float                   # 必填，浮点数
    in_stock: bool = True          # 可选，有默认值
    tags: list[str] = []           # 可选，默认空列表
```
这里有三种字段形态，对应三种"必填性"：

| 写法 | 含义 |
| :--- | :--- |
| name: str | 必填字段。实例化时不给就报错 |
| in_stock: bool = True | 可选字段，缺省时用默认值 |
| tags: list[str] = [] | 带默认值的容器字段(Pydantic 会安全处理可变默认值，不会有 Python 那个经典的"可变默认参数"坑) |

 实例化方式很自然，也支持直接从字典展开(这正是 API 收到 JSON 后的典型用法)：
```text
### 直接传参
p1 = Product(name="键盘", price=199.0)

### 从字典展开——API 场景最常见
raw = {"name": "鼠标", "price": 89.0, "tags": ["办公", "外设"]}
p2 = Product(**raw)

print(p2.name, p2.tags)    # 鼠标 ['办公', '外设']
```
定义模型时，你脑子里要建立的画面是： **这个类不是普通的数据容器，而是一张"准入标准"** ——它规定了什么样的数据才配变成一个 Product 对象。

 **承上启下**：定义清楚了。但"校验"这个动作究竟在哪一刻发生？是定义类的时候，还是实例化的时候？理解这个时机，是用好 Pydantic 的关键。

#### 2.3 校验何时发生：实例化即校验
 **要解决的问题**：我定义了模型，但校验到底在什么时候触发？如果数据类型对不上，是直接报错，还是会尝试转换？

 记住一句话： **Pydantic 在"实例化模型"的那一刻进行校验**。也就是说，只要你成功拿到了一个模型对象，就意味着里面的数据已经全部通过了校验——这是 Pydantic 给你的核心保证。
```python
from pydantic import BaseModel, ValidationError

class User(BaseModel):
    name: str
    age: int

### 情况一：数据合法 → 成功创建，数据已可信
u = User(name="Bob", age=25)

### 情况二：数据非法 → 实例化当场抛出 ValidationError
try:
    User(name="Bob", age="二十五")    # age 无法变成 int
except ValidationError as e:
    print(e)        # 清晰列出哪个字段、错在哪
```
#### 类型强制：智能转换，而非死板拒绝
 一个常被误解的点：Pydantic 默认 **不是** "类型不完全匹配就报错"，而是会尝试 **合理的类型转换**。比如字符串 "25" 会被转成整数 25 ——这在处理来自网络的数据(一切皆字符串)时非常实用：
```python
class Item(BaseModel):
    count: int
    price: float

item = Item(count="25", price="9.9")    # 字符串被智能转换
print(item.count, type(item.count))      # 25 <class 'int'>
print(item.price, type(item.price))      # 9.9 <class 'float'>
```
但"合理"是有边界的—— "二十五" 无法变成 int，就会老老实实报错。如果你希望严格按类型匹配、拒绝任何转换，可以开启严格模式( Strict 类型或 model_config 配置)。

 心智模型：实例化 = 过关卡。过了，对象里的数据就是干净、类型正确的；没过，当场拦下并告诉你哪里不对。

 **承上启下**：内置的类型校验和类型转换覆盖了大量情况。但业务规则往往更刁钻——"密码至少 8 位""折扣必须在 0 到 1 之间""结束时间必须晚于开始时间"。这些怎么表达？

#### 2.4 规则不够用：字段约束与自定义校验器
 **要解决的问题**：类型对了不代表值合理。怎么表达"年龄要在 0~150 之间""用户名长度有限制""两个字段之间要满足某种关系"这类业务规则？

 Pydantic 提供了两个层次的工具： **轻量约束用** **Field，复杂逻辑用校验器装饰器**。

#### 第一层：用 Field 加约束
 对于"范围、长度、正则"这类常见限制，用 Field 一行搞定：
```python
from pydantic import BaseModel, Field

class Account(BaseModel):
    username: str = Field(min_length=3, max_length=20)
    age: int = Field(ge=0, le=150)              # ge=大于等于, le=小于等于
    discount: float = Field(default=0.0, ge=0, le=1)
    bio: str = Field(default="", max_length=200)
```
常用约束一览： gt / ge / lt / le (大于、大于等于、小于、小于等于)、 min_length / max_length (长度)、 pattern (正则)。

#### 第二层：用校验器写自定义逻辑
 当规则无法用简单约束表达时——比如"密码必须同时含字母和数字"，或"结束时间必须晚于开始时间"——就用校验器。

 **字段校验器** ( field_validator)针对单个字段：
```python
from pydantic import BaseModel, field_validator

class User(BaseModel):
    password: str

    @field_validator("password")
    @classmethod
    def password_strength(cls, v: str) -> str:
        if not any(c.isdigit() for c in v):
            raise ValueError("密码必须包含数字")
        if not any(c.isalpha() for c in v):
            raise ValueError("密码必须包含字母")
        return v        # 校验通过必须把值返回
```
**模型校验器** ( model_validator)针对"字段之间的关系"——这是单字段校验器做不到的：
```python
from pydantic import BaseModel, model_validator

class Event(BaseModel):
    start: int      # 简化为时间戳
    end: int

    @model_validator(mode="after")
    def check_order(self):
        if self.end <= self.start:
            raise ValueError("结束时间必须晚于开始时间")
        return self
```
选择原则：单个字段的范围/格式 → Field；单字段的复杂逻辑 → field_validator；跨字段的关系 → model_validator。

 **承上启下**：现实里的数据很少是扁平的一层。一个订单里嵌着多个商品，每个商品又有自己的属性。Pydantic 怎么处理这种层层嵌套的结构？

#### 2.5 复杂结构：嵌套模型与组合类型
 **要解决的问题**：真实数据是嵌套的——订单里有商品列表，商品里有规格，用户里有地址。怎么对这种多层结构做校验？

 Pydantic 的优雅之处在于： **模型可以作为另一个模型的字段类型**。嵌套校验会自动逐层递归进行，你不用写任何额外代码。
```python
from pydantic import BaseModel

class Address(BaseModel):
    city: str
    street: str

class Item(BaseModel):
    name: str
    price: float
    quantity: int = 1

class Order(BaseModel):
    order_id: str
    address: Address          # 嵌套一个模型
    items: list[Item]         # 嵌套一个模型的列表

### 一份嵌套的原始数据(典型的 API/LLM JSON 输出)
raw = {
    "order_id": "A001",
    "address": {"city": "上海", "street": "南京路 100 号"},
    "items": [
        {"name": "键盘", "price": 199, "quantity": 2},
        {"name": "鼠标", "price": 89},
    ],
}

order = Order(**raw)          # 一次调用，逐层全部校验
print(order.address.city)     # 上海
print(order.items[0].name)    # 键盘——已是 Item 对象，可点出属性
```
最值得体会的一点： order.items[0] 不是普通字典，而是一个 **校验过的** **Item** **对象**。整棵数据树从外到内都被校验、都变成了类型安全的对象。任何一层有问题(比如某个 item 缺了 price)，都会在实例化时精确报出错在哪条路径上。

 此外还支持常见的组合类型来表达"可有可无""多选一"：
```python
from typing import Optional, Union

class Profile(BaseModel):
    nickname: Optional[str] = None       # 可以是 str 或 None
    contact: Union[str, int]             # 可以是字符串或整数
    role: str = "user"
```
心智模型：嵌套模型让校验"递归到底"——你只需描述每一层的形状，Pydantic 负责把整棵树都验一遍。

 **承上启下**：数据进来、校验、变成干净的对象——前半程完成了。但对象处理完，往往还要 **送出去**：返回给前端、写进数据库、再喂回给大模型。这就需要把对象变回 JSON。

#### 2.6 送出去：序列化与 model_dump
 **要解决的问题**：校验后的模型对象，怎么变回字典或 JSON，以便返回响应、存库、或传给下一个环节？

 这是校验的逆过程，叫 **序列化**。Pydantic 提供两个核心方法： model_dump() 转成字典， model_dump_json() 直接转成 JSON 字符串。
```python
from pydantic import BaseModel

class User(BaseModel):
    name: str
    age: int
    password: str

user = User(name="Alice", age=30, password="secret123")

user.model_dump()              # {'name': 'Alice', 'age': 30, 'password': 'secret123'}
user.model_dump_json()         # '{"name":"Alice","age":30,"password":"secret123"}'
```
实战中真正常用的是它的 **精细控制** 能力——比如对外返回时要藏起敏感字段、或只保留部分字段：
```text
### 排除敏感字段
user.model_dump(exclude={"password"})
### {'name': 'Alice', 'age': 30}
### 只包含指定字段
user.model_dump(include={"name"})
### {'name': 'Alice'}
### 排除值为 None 的字段(接口返回常用，让响应更干净)
user.model_dump(exclude_none=True)
```
至此，一份数据完成了它的完整旅程： **外部 JSON →** ** Model(\**data) ** **校验 → 干净的对象(业务逻辑放心使用)→** **model_dump()** **→ 送出去**。这正是上一篇 FastAPI 里 response_model 在背后默默做的事——它用的就是 model_dump。

 记忆：进来靠实例化(校验)，出去靠 model_dump (序列化)，一进一出闭环。

 **承上启下**：到这里，Pydantic 作为"数据校验工具"已经完整了。但对 Agent 工程师而言，它最有价值的用法还没登场——给那个最不可控的数据源，大模型的输出，套上一道护栏。

#### 2.7 用在刀刃上：给大模型输出套一道护栏
 **要解决的问题**：大模型返回的是自由文本，哪怕你要求它输出 JSON，它也可能漏字段、给错类型、编造枚举值。怎么保证拿到的输出一定是程序能安全消费的结构？

 这正是 Pydantic 在 Agent 工程里的核心价值。思路分三步： **用模型描述你想要的输出结构 → 把结构要求告诉模型 → 用模型校验模型的输出**。任何不合规的输出都会在校验关卡被当场拦下，而不是流进业务逻辑里。

 下面是一个完整的、可运行的最小示例：让大模型从一段用户评论里抽取结构化信息(情感、评分、关键词)，并用 Pydantic 兜底。
```python
from enum import Enum
from pydantic import BaseModel, Field, ValidationError

### 第一步：用模型精确描述"我要的输出长什么样"
class Sentiment(str, Enum):
    positive = "positive"
    neutral = "neutral"
    negative = "negative"

class ReviewAnalysis(BaseModel):
    sentiment: Sentiment                       # 必须是三个枚举值之一
    score: int = Field(ge=1, le=5)             # 评分必须在 1~5
    keywords: list[str] = Field(max_length=5)  # 最多 5 个关键词
    summary: str = Field(max_length=100)

### 第二步：把这个结构作为指令告诉模型(用 JSON Schema，模型最容易理解)
def build_prompt(review: str) -> str:
    schema = ReviewAnalysis.model_json_schema()    # 自动生成 JSON Schema！
    return (
        f"请分析下面这条评论，严格按此 JSON Schema 输出，不要多余文字：\n"
        f"{schema}\n\n评论：{review}")

### 第三步：拿到模型输出后，用 Pydantic 校验(这里用一段模拟的模型返回)
def parse_model_output(raw_json: str) -> ReviewAnalysis:
    try:
        # model_validate_json 直接吃 JSON 字符串并校验
        return ReviewAnalysis.model_validate_json(raw_json)
    except ValidationError as e:
        # 校验失败 → 这里可以触发重试、降级、或把错误反馈给模型让它修正
        print("模型输出不合规，需要重试。错误：", e)
        raise

### 模拟一次合规的模型返回
good = '{"sentiment": "positive", "score": 5, "keywords": ["好用", "快"], "summary": "整体体验很好"}'
result = parse_model_output(good)
print(result.sentiment, result.score)     # Sentiment.positive 5

### 模拟一次不合规的返回(score 超范围、sentiment 是编造的值)
bad = '{"sentiment": "very_good", "score": 10, "keywords": [], "summary": "x"}'
### parse_model_output(bad)   # 会被 ValidationError 当场拦下
```
这里有三个对 Agent 工程极其关键的细节：

 **model_json_schema()** **自动生成结构说明**。你不用手写"请按这个格式输出"的冗长描述，Pydantic 直接把模型转成标准 JSON Schema 喂给大模型——这也正是各家 LLM "结构化输出""工具调用"功能在底层所做的事。

 **model_validate_json()** **是模型与你代码之间的关卡**。模型输出无论多自由，只要想变成 ReviewAnalysis 对象，就必须满足所有约束：sentiment 不能是编造的值、score 不能越界、keywords 不能超过 5 个。

 **校验失败是一个可处理的信号，而非崩溃**。捕获到 ValidationError，你可以选择重试、把错误信息回传给模型让它自我修正、或降级处理。这道护栏把"模型可能犯错"这件不确定的事，变成了你流程里一个明确、可控的分支。

### 收尾：回到那条主线
 回到开头那个问题—— **怎么让不可信的外部数据安全地变成程序可以放心使用的结构化对象？** 现在可以完整作答：

 不用手写一长串 if 校验，而是 **声明数据的形状** ——继承 BaseModel 、用类型注解描述字段；

 校验在 **实例化那一刻** 自动发生，拿到对象就等于数据已可信，且会做合理的类型转换；

 业务规则用 Field (轻量约束)、 field_validator (单字段逻辑)、 model_validator (跨字段关系)层层表达；

 嵌套结构靠"模型嵌套模型"自动递归校验，整棵数据树都变成类型安全的对象；

 处理完用 model_dump / model_dump_json 序列化送出去，一进一出形成闭环；

 在 Agent 里，用模型给大模型的输出套护栏—— model_json_schema 生成指令、 model_validate_json 当关卡、 ValidationError 作为可控的失败分支。

 把这条链路走通，你会发现 Pydantic 不只是"FastAPI 的一个配件"，而是 Agent 工程里那道 **把不确定性挡在业务逻辑之外** 的关键防线。模型的输出再怎么天马行空，只要过不了这道关卡，就进不了你的系统。

| 知识点 | 一句话记忆 |
| :--- | :--- |
| BaseModel + 类型注解 | 声明数据的形状，校验免费附赠 |
| 实例化即校验 | 拿到对象 = 数据已可信，且智能转换类型 |
| Field / 校验器 | 约束、单字段逻辑、跨字段关系，分三层表达 |
| 嵌套模型 | 模型套模型，递归校验整棵数据树 |
| model_dump | 序列化送出去，与实例化形成一进一出闭环 |
| LLM 输出护栏 | schema 生成指令 + validate 当关卡 + 校验失败可重试 |
![图片](https://mmbiz.qpic.cn/sz_mmbiz_png/kSX2Q9RM8CTpfpHHsCWCx05L3rjn5EqykKRibwib6U5S9MeC6fF4n8KoEV8U3XxHKDCQqB443qdI43C5VPyKvMYVaCNXWaFpP3Ga2ooyJ97do/640?wx_fmt=png&from=appmsg&wxfrom=5&wx_lazy=1&tp=webp#imgIndex=0)

## 0x02. Agent 工程师需要了解的开发技术栈——Google ADK
> 发布日期：2026-05-28  
> 原文链接：[Agent 工程师需要了解的开发技术栈——Google ADK](https://mp.weixin.qq.com/s/AHXJaYs7ORxGrV4e3ysNEA)

这是一期新连载，记录Agent工程师需要了解的开发技术栈

 为什么讲ADK？因为最近手头一个项目在用这个(很新的框架，之前没听过hh)。

 注：本文基于截至 2026 年 5 月的公开资料整理。ADK 是一个快速演进的框架， **ADK Python 2.0 已于 2026 年 5 月 19 日正式** **GA**，本文会区分 1.x 的稳定基础与 2.0 的新能力。具体 API 请以官方文档为准。

### 写在前面：这篇文章想讲清楚什么
 前三篇我们攒齐了"零件"：FastAPI 把能力暴露成服务、异步让它高效处理等待、Pydantic 守住数据的可靠性。但把这些零件组装成一个真正能"自己思考、调用工具、多步骤完成任务"的 Agent，还需要一套 **编排框架**。Google ADK(Agent Development Kit)就是这样一套框架。

 ADK 和市面上很多 Agent 框架有个根本气质上的不同。LangChain、LangGraph 这类工具，骨子里是围绕"把一个强大的 Agent 武装到牙齿"来设计的。而 ADK 从第一天起就是 **为多智能体系统而生** ——它假设你最终要的不是一个全能选手，而是一支各有专长、能彼此委派任务的"智能体团队"。这也是 Google 自家 Agentspace 等产品背后用的同一套框架。

 这篇文章只围绕一条主线展开：

 **怎么从"一个会调用工具的单智能体"，一步步搭建到"一支能分工协作、流程可控的智能体团队"？** 顺着这条线，我们依次回答：

 ADK 是什么、解决什么问题？它和别的框架的取舍在哪？

 最小单元：一个能调用工具的智能体怎么搭？—— LlmAgent + Tools + Runner

 智能体怎么记住上下文？——Session 与 State

 怎么从单个智能体走向"团队"？——sub-agents 与智能体间委派

 团队协作怎么保证"按章办事"？——工作流智能体(Sequential / Parallel / Loop)

 ADK 2.0 带来了什么质变？——图工作流、Task API 与人在回路(HITL)

 写好了怎么调试和上线？—— adk web 、评估与部署

 读完你应该建立这样一个心智模型： **ADK** **把 Agent 应用拆成几个正交的关注点——"谁来思考"(Agent)、"能做什么"(Tools)、"记得什么"(Session/State)、"按什么流程协作"(Workflow)、"谁来跑"(Runner)。理解了这几块如何拼合，你就理解了 ADK。**

### 1. ADK 是什么：定位与取舍

 **要解决的问题**：用裸 LLM API 手写一个 Agent，很快会陷入"自己管理对话历史、自己解析工具调用、自己处理多步骤流程"的泥潭。能不能有个框架把这些通用骨架接管掉？

 ADK 是 Google 在 2025 年 Cloud NEXT 上开源的 Agent 开发框架，它的官方定位是" **代码优先(code-first)** 、可在企业级规模上构建、调试、部署可靠 AI 智能体"。到 2.0 时它已支持 Python、TypeScript、Go、Java、Kotlin 多语言，本文以 Python 为主。

 它想接管的，正是手写 Agent 时最烦人的那些通用骨架：管理会话状态、编排工具调用、协调多个智能体、对接底层 LLM。你只需要描述"智能体的逻辑、它能用的工具、它该如何处理信息"，剩下的结构由 ADK 提供。

#### 它的核心取舍
 每个框架都有自己的"性格"，选型时看清取舍比看功能列表更重要：

| 维度 | ADK 的选择 | 意味着什么 |
| :--- | :--- | :--- |
| 设计中心 | 多智能体协作优先 | 天生擅长"智能体团队"，单智能体场景可能显得重 |
| 编程风格 | 代码优先、Pythonic | 用熟悉的代码组织逻辑，而非大量配置或可视化拖拽 |
| 模型支持 | Gemini 原生最优，也支持 GPT、Claude、本地模型 | 在 Google Cloud 生态里体验最顺，但不锁死 |
| 部署 | 一键部署到 Google Cloud，也可自建容器 | 在 Vertex AI / Cloud Run 上能"零改代码"继承托管基础设施 |

 一句话概括它的适用边界： **如果你要构建的是定义清晰、需要多个角色协作的复杂智能体系统，ADK** **是有力的选择；如果只是一个轻量的单智能体小工具，它可能偏重。** **承上启下**：定位清楚了。无论多复杂的团队，都是由最小单元——单个智能体——搭起来的。先把这个最小单元拆开看。

### 2. 最小单元：会调用工具的智能体
 **要解决的问题**：一个 Agent 最基本的能力，是"理解你的话 + 决定调用哪个工具 + 给出回答"。这三件事在 ADK 里分别由谁负责？

 ADK 把这个最小单元拆成三个角色，记住它们的分工，就抓住了 ADK 的骨架：

 **LlmAgent (也常直接叫** **Agent)——大脑**：负责推理、理解语言、做决策、决定用哪个工具。它的行为由 LLM 驱动，因此是 **非确定性** 的。

 **Tools——能力**：让智能体能做 LLM 本身做不到的事，比如查实时数据、做计算、调用外部 API。

 **Runner ——引擎**：真正驱动整个交互跑起来的执行器，负责把用户输入送进智能体、管理事件循环。

#### 把工具定义成普通函数
 ADK 的一个优雅之处：在 Python 里， **一个带类型注解和文档字符串的普通函数，就能直接当工具用** ——框架会自动把它包装成 FunctionTool，并把函数签名和文档喂给模型，让模型知道这个工具是干什么的、需要什么参数(你会发现这又回到了上一篇 Pydantic 的思路：用结构化的声明给模型当说明书)。
```python
def get_weather(city: str) -> dict:
    """查询指定城市的当前天气。

    Args:
        city: 城市名称，比如 "上海"。
    Returns:
        包含天气状况的字典。
    """
    # 真实场景这里会调用天气 API；这里用假数据演示
    fake = {"上海": "晴，25°C", "北京": "多云，22°C"}
    if city in fake:
        return {"status": "success", "report": fake[city]}
    return {"status": "error", "message": f"没有 {city} 的天气数据"}
```
#### 把三个角色拼起来
```python
from google.adk.agents import LlmAgent
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner
from google.genai.types import Content, Part

### 1) 大脑：定义智能体，并把工具交给它
weather_agent = LlmAgent(
    name="weather_agent",
    model="gemini-flash-latest",          # 选用的底层模型
    instruction="你是一个天气助手，用户问天气时调用 get_weather 工具回答。",
    description="负责回答天气相关问题",     # 给"团队"里其他智能体看的自我介绍(第 4 节会用到)
    tools=[get_weather],                  # 普通函数直接作为工具传入
)

### 2) 引擎：准备会话服务和 Runner
session_service = InMemorySessionService()
runner = Runner(
    agent=weather_agent,
    app_name="weather_app",
    session_service=session_service,
)

### 3) 跑起来(ADK 的执行是异步的，呼应上一篇的异步主题)
async def ask(query: str):
    await session_service.create_session(
        app_name="weather_app", user_id="u1", session_id="s1")
    message = Content(role="user", parts=[Part(text=query)])
    async for event in runner.run_async(
        user_id="u1", session_id="s1", new_message=message):
        if event.is_final_response():
            print(event.content.parts[0].text)
```
注意 runner.run_async 返回的是一个 **异步事件流** ——你用 async for 逐个消费它产出的事件(呼应第二篇的异步生成器)。这些事件记录了智能体的每一步：思考、调用了哪个工具、工具返回了什么、最终回答是什么。这种"全过程可观测"的事件模型，是 ADK 调试能力的基础。

 **承上启下**：现在智能体能调工具、能回答了。但它每次都是"失忆"的——回答完这一句就忘了上一句。要让它在多轮对话里记住上下文，需要 Session 和 State。

#### 2.3 记住上下文：Session 与 State
 **要解决的问题**：对话是多轮的。智能体怎么记住"用户上一句问的是上海"，或者在多步骤任务里把中间结果传递下去？

 ADK 用两个概念管理记忆：

 **Session(会话)**：代表一次完整的对话，承载这次对话的所有事件历史。上面代码里的 session_id="s1" 就是在标识一次会话。

 **State(状态)**：挂在 Session 上的一个 **键值存储**，用来跨轮次、跨智能体共享数据。可以把它理解成这次对话的"共享便签本"。

 State 最常见的用法之一是 output_key ——让智能体 **自动把自己的回答存进 State**，供后续步骤读取：
```python
from google.adk.agents import LlmAgent

greeting_agent = LlmAgent(
    name="Greeter",
    model="gemini-flash-latest",
    instruction="生成一句简短友好的问候语。",
    output_key="last_greeting",     # 回答会被自动存进 state['last_greeting']
)
### 之后另一个智能体或流程，就能从 state 里读到这句问候，接着往下处理
```
这个 output_key 看似不起眼，却是多智能体协作的关键纽带： **上一个智能体把结果写进 State，下一个智能体从 State 读出来当输入** ——团队就是这样接力的。这一点在第 5 节的工作流里会反复出现。

 心智模型：Session 是"这场对话"，State 是这场对话里大家共用的"便签本"， output_key 是"把我的产出贴到便签本上"。

 **承上启下**：单个智能体能思考、能用工具、能记忆了。但 ADK 真正的主场是 **团队**。怎么让多个智能体各司其职、互相委派任务？

#### 2.4 走向团队：sub-agents 与智能体委派
 **要解决的问题**：一个智能体什么都管，提示词会越堆越臃肿、越来越不可靠。能不能像组建团队一样，让每个智能体只精通一件事，再让一个"主管"按需分派？

 这正是 ADK 的核心理念。做法是：定义多个 **各有专长的子智能体**，再用一个 **协调者智能体** 通过 sub_agents 把它们组织起来。协调者会根据对话内容， **智能地把任务委派** 给最合适的子智能体。
```python
from google.adk.agents import LlmAgent

### 专长一：问候
greeting_agent = LlmAgent(
    name="greeting_agent",
    model="gemini-flash-latest",
    instruction="你只负责热情地问候用户。",
    description="处理打招呼、问候类的对话",     # description 是委派的关键依据！
)

### 专长二：天气(复用第 2 节的 get_weather 工具)
weather_agent = LlmAgent(
    name="weather_agent",
    model="gemini-flash-latest",
    instruction="你只负责回答天气问题，调用 get_weather 工具。",
    description="处理天气查询",
    tools=[get_weather],
)

### 协调者：自己不干活，只负责把任务分派给合适的子智能体
coordinator = LlmAgent(
    name="coordinator",
    model="gemini-flash-latest",
    instruction=(
        "你是一个调度员。用户打招呼就交给 greeting_agent，"
        "问天气就交给 weather_agent。"),
    sub_agents=[greeting_agent, weather_agent],   # 把团队成员挂上来
)
```
这里有个 **容易被忽略但极其重要** 的细节：每个子智能体的 description 字段，是协调者决定"该派给谁"的主要依据。协调者读的不是子智能体的内部指令，而是这句"自我介绍"。所以 description 要写得准确、能清晰区分各成员的职责——它本质上是写给"调度逻辑"看的，而不是写给最终用户看的。

 这种"协调者 + 专长子智能体"的层级结构，就是 ADK 推荐的复杂应用组织方式： **用分工降低单个智能体的复杂度，用委派实现整体的灵活性。** **承上启下**：委派是"让模型自己决定派给谁"，灵活但不确定。可现实中很多流程必须 **严格按步骤来** ——先做 A，再做 B，最后做 C，一步都不能乱。这种确定性怎么保证？

#### 2.5 按章办事：工作流智能体
 **要解决的问题**：让 LLM 自由决定流程很灵活，但有些任务(比如"先写代码 → 再审查 → 再改写")必须按固定顺序、可预测地执行。怎么把"确定性的流程控制"和"非确定性的 LLM 思考"结合起来？

 ADK 的答案是 **工作流智能体(Workflow** **Agent)**。它们本身 **不由 LLM 驱动**，而是用确定性的代码逻辑来编排子智能体的执行顺序。1.x 里有三种经典模板：

 **SequentialAgent (顺序)**：让子智能体严格按列表顺序依次执行。适合"流水线"式任务。

 **ParallelAgent (并行)**：让多个子智能体同时执行。适合互不依赖、可并发的子任务(呼应第二篇的并发主题)。

 **LoopAgent (循环)**：反复执行子智能体，直到满足某个条件。适合"迭代改进"式任务。

 下面用 SequentialAgent 串一个"代码生成 → 代码审查"的流水线，顺便复习上一节的 State 接力：
```python
from google.adk.agents import LlmAgent, SequentialAgent

GEMINI = "gemini-flash-latest"

### 第一步：写代码，把结果存进 state['generated_code']
code_writer = LlmAgent(
    name="CodeWriter",
    model=GEMINI,
    instruction="你是 Python 代码生成器，根据需求写出代码。",
    output_key="generated_code",          # 产出存入 State
)

### 第二步：审查代码，从 state 里读出上一步的产出
code_reviewer = LlmAgent(
    name="CodeReviewer",
    model=GEMINI,
    instruction=(
        "你是资深代码审查员。请审查下面这段代码并给出改进建议：\n"
        "{generated_code}"                # 用 {} 直接引用 State 里的值),
)

### 用 SequentialAgent 把两步串成确定性流水线
pipeline = SequentialAgent(
    name="CodePipeline",
    sub_agents=[code_writer, code_reviewer],   # 严格按此顺序执行
)
```
注意审查员指令里的 {generated_code} ——它直接把上一步写进 State 的产出，注入到了自己的提示词里。 **写代码的智能体把成果贴到便签本，审查的智能体从便签本取来接着干**，这就是第 3 节那个 State 接力机制在工作流里的落地。

 到这里，ADK 给了你两种互补的协作范式：第 4 节的"LLM 智能委派"(灵活、自适应)和第 5 节的"工作流编排"(确定、可预测)。 **真实应用往往两者混用**：用工作流框定大流程，在某些节点里放入会自主决策的 LlmAgent。

 **承上启下**：顺序、并行、循环这三个模板覆盖了常见流程。但当流程出现复杂的条件分支、需要中途暂停等人工审批时，模板就不够用了。这正是 ADK 2.0 要解决的。

6. ADK 2.0 的质变：图工作流、Task API 与 **HITL** **要解决的问题**：真实业务流程常常是带条件分支的"如果……就……否则……"，还可能需要在高风险步骤(转账、删数据)暂停下来等人批准。模板化的顺序/并行/循环表达不了这些。怎么办？
 **ADK** **Python 2.0 于 2026 年 5 月 19 日正式** **GA**，它的核心就是把工作流从"几个固定模板"升级为"可以自由编排的图"。几个关键能力：

 **图工作流(Graph-based workflows)**：把整个流程定义成一张 **有向无环图(DAG)**。节点(Node)是具体动作——可以是 LLM 调用、工具执行、或一段纯 Python 函数；边(Edge)定义流转，可以是无条件的(A 总是到 B)，也可以是 **条件的** (如果 A 输出"错误"，就转到 C)。这样"分支、扇出/扇入、汇合"这些复杂结构都能精确表达，且执行是确定、可预测的。

 **动态工作流(Dynamic workflows)**：当连图都嫌不够灵活时(比如高度依赖运行时逻辑的循环和分支)，可以用代码优先的方式， **用装饰器定义节点、像调用函数一样调用它们**，直接用 Python 自己的循环和条件来组织流程。一句话区分：图工作流适合"结构相对固定的复杂流程"，动态工作流适合"逻辑路径高度依赖运行时的流程"。

 **Task** **API**：提供了结构化的 **智能体间委派** 机制，支持多轮任务、单轮受控输出、混合委派模式，并能把任务智能体当作工作流里的一个节点。这让第 4 节的"委派"从"靠提示词引导"升级为"有明确契约的结构化调用"。

 **人在回路(Human-in-the-Loop,** **HITL)**：这是 2.0 一个很实用的能力。对于高风险操作，工作流可以 **原生暂停**，通过 ADK 的 Web UI 等待人工审批，拿到反馈后再恢复执行。比如一个贷款审批流程，可以在"放款"这步暂停，等人确认后再继续。

 ⚠️ **一个 2.0 迁移的关键坑** (值得专门提醒)：2.0 引入了自动重试和可中断(HITL)机制，它们依赖异常能正常向上抛出。如果你在工具里写了宽泛的 except Exception: 把错误吞掉，会让框架看不到失败、 **永久禁用该步骤的自动重试**；而 except BaseException: 更危险，会误吞 NodeInterruptedError，直接 **破坏工作流暂停等待人工输入的能力**。迁移时的原则是： **让标准异常自然向上传播，交给框架按你配置的** **RetryConfig** **处理；除非要显式重新抛出，否则永远不要捕获** **BaseException。** 另外注意，2.0 包含对智能体 API、事件模型、会话结构的 **破坏性变更**：2.0 生成的会话能被 1.28+ 读取(多余字段会被忽略)，但与更老的 1.x 不兼容。如果你暂时不想升级，安装时记得 **锁定版本号**。

 **承上启下**：流程能力齐了。但一个 Agent 写出来不代表能用——你得能看清它每一步在干什么、能验证它靠不靠谱、能把它部署出去。这是最后一块。

#### 6.7 调试、评估与部署
 **要解决的问题**：智能体的行为是非确定性的，光看代码看不出它实际会怎么决策。怎么观察、验证、并最终上线？

 ADK 把"开发者体验"当作一等公民，这三件事都有专门支持：

 **本地调试用** **adk web**。一个 ADK 项目的最小结构非常简单——一个文件夹，里面 agent.py 定义一个 root_agent (这是唯一必需的元素)，加上.env 放密钥。然后在上级目录运行：
```text
adk web
```
它会启动一个本地可视化界面(默认 http://localhost:8000)，你能在聊天框里和智能体对话，并 **逐步检视每一个事件**：它调用了哪个工具、传了什么参数、State 如何变化、最终怎么回答。对于行为非确定的智能体，这种"把思考过程摊开看"的能力，是排查问题的命脉。除了 Web UI，ADK 也支持 CLI( adk run)和 API Server 等多种交互方式，而 **智能体的核心定义( agent.py)完全不变** ——变的只是你怎么发起交互。

 **评估(Evaluation)是** **ADK** **内置的一等能力**。因为智能体非确定，"跑通一次"不等于"可靠"。ADK 的评估框架能针对预定义的测试用例，同时评估两个维度： **最终回答的质量**，以及 **逐步执行的轨迹** (它是不是按预期的步骤、调用了预期的工具走到答案的)。把评估做成开发流程里的反馈闭环，才能构建出让人敢信任、敢部署的智能体。

 **部署"deploy anywhere"**。你可以把 ADK 智能体容器化后部署到自己的基础设施，也可以一键部署到 Google Cloud。部署到 Cloud(Agent Runtime / Cloud Run / GKE)时，智能体能 **不改一行代码** 就继承托管基础设施、内置鉴权、Cloud Trace 可观测性和企业级安全——这也回扣到了本系列第一篇：底层那个对外提供服务的 Web 层，正是 FastAPI 那类框架的活儿。本地开发，全球扩展。

### 收尾：回到那条主线
 回到开头那个问题—— **怎么从一个会调工具的单智能体，搭建到一支分工协作、流程可控的智能体团队？** 现在可以串成一条完整的路径：

 ADK 是一个代码优先、为多智能体而生的框架，接管了会话、工具编排、协作的通用骨架；

 最小单元是 LlmAgent (大脑)+ Tools(能力，普通函数即可)+ Runner (引擎)，交互是异步事件流；

 用 Session 装一场对话、用 State 当共享便签本、用 output_key 把产出贴上去，实现记忆与接力；

 用"协调者 + 专长子智能体"的 sub_agents 结构实现智能委派， description 是分派的依据；

 需要确定性流程时，用 Sequential / Parallel / Loop 工作流智能体编排执行顺序；

 ADK 2.0 把流程升级为图工作流与动态工作流，并带来 Task API 和原生的人在回路暂停；

 全程用 adk web 可视化调试、用内置评估验证可靠性、再 deploy anywhere 上线。

 把这条路径走通，再回看整个系列就清晰了： **FastAPI 搭服务、异步保证高效、Pydantic 守住数据、ADK** **负责编排** ——四块拼在一起，才是一个 Agent 工程师手里完整的技术栈。ADK 在最上层做的，是把前三篇打下的地基，组织成一个能思考、会协作、可信赖的智能体系统。

| 知识点 | 一句话记忆 |
| :--- | :--- |
| ADK 定位 | 代码优先、为多智能体协作而生的编排框架 |
| LlmAgent / Tools / Runner | 大脑 / 能力 / 引擎，最小三件套 |
| Session / State / output_key | 一场对话 / 共享便签本 / 把产出贴上去 |
| sub_agents 委派 | 协调者按 description 把任务派给专长子智能体 |
| 工作流智能体 | Sequential / Parallel / Loop，确定性编排 |
| ADK 2.0 | 图工作流 + 动态工作流 + Task API + 人在回路 |
| adk web / 评估 / 部署 | 可视化调试 / 验证轨迹 / deploy anywhere |
![图片](https://mmbiz.qpic.cn/sz_mmbiz_png/kSX2Q9RM8CTpfpHHsCWCx05L3rjn5EqykKRibwib6U5S9MeC6fF4n8KoEV8U3XxHKDCQqB443qdI43C5VPyKvMYVaCNXWaFpP3Ga2ooyJ97do/640?wx_fmt=png&from=appmsg&wxfrom=5&wx_lazy=1&tp=webp#imgIndex=0)
