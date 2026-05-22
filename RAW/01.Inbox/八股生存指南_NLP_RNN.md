章节附带手撕RNN / LSTM算法, 带你使用Pytorch框架去实现一个最简RNN / LSTM
相对偏向于面试, 如果有面试重点的话,
## NLP
自然语言处理（Nature language Processing, NLP）研究的是：**如何让计算机理解、处理和生成自然语言**。这里的“自然语言”，指的就是人日常使用的语言，比如中文、英文、法文等。和表格数据、图像数据相比，语言数据更难直接交给计算机处理。因为计算机本质上只能计算01二进制，而一句话里包含词义、语法、上下文、语气和隐含含义，不能像表格那样天然变成一组数值

**NLP发展历史**
- **规则时期（1950s-1980s）**：核心是符号主义。研究者试图用人工编写的语法和语义规则处理语言，代表系统有 ELIZA、SHRDLU。问题是规则难以覆盖真实语言的复杂性
- **统计学习时期（1980s-2010s）**：核心是概率与统计。模型不再手写规则，而是从大量数据中学习语言规律，代表方法有 HMM、最大熵模型、CRF，并推动了分词、语音识别、机器翻译等任务
- **神经网络时期（2013年起）**：Word2Vec 让词语有了向量表示，RNN、LSTM 开始用于文本序列建模，语言处理从离散规则转向连续表示学习
- **预训练模型时期（2018年起）**：Transformer 和 BERT、GPT 等预训练语言模型成为主流。模型先从大规模文本中学习通用语言规律，再针对具体任务微调
- **大模型时期（2020年至今）**：以 GPT、ChatGPT、DeepSeek 等大语言模型为代表，模型具备更强的通用任务处理、上下文学习和一定推理能力，研究重点转向多模态、复杂推理、可解释性、安全性与伦理

# Embedding 
词嵌入（Word Embedding）可以理解为：**把词语转换成一组能表达语义的数字向量**

计算机不能直接理解“苹果”“香蕉”“汽车”这些词，只能处理数字。最简单的 one-hot 编码只能表示“是不是这个词”，但看不出词语之间的语义关系。比如“苹果”和“香蕉”都属于水果，但 one-hot 本身不知道它们更相似。

Embedding 的做法是把每个词映射成一个低维稠密向量，例如：
```json
苹果 -> [0.12, -0.45, 0.88, ...]
香蕉 -> [0.10, -0.39, 0.81, ...]
汽车 -> [-0.63, 0.20, -0.14, ...]
```

如果两个词语义相近，它们的向量距离通常也更近。因此，“苹果”和“香蕉”会比“苹果”和“汽车”更接近。词向量不只表示词本身，还可能捕捉到性别、身份、类别等语义关系，一个经典例子是: 
$$king - man + woman ≈ queen$$
**如果两个词语含义相近，它们对应的向量距离通常也会更近**。比如“苹果”和“香蕉”的向量会比较接近，而“苹果”和“汽车”的向量会相对远一些。从直觉上看，Embedding 就像给每个词安排一个“**语义坐标**”。在这个**语义空间**里：人物关系类词语会聚在一起，交通工具类词语会聚在一起。这样模型就不只是看到一个词的编号，而是能利用词之间的语义关系


**Pytorch API: Embedding**
**jieba分词**
jieba 是一个经典中文分词工具，支持精确模式、全模式、搜索引擎模式；其核心流程是基于前缀词典构建 DAG，再通过动态规划计算最大概率路径，对于未登录词使用 HMM 和 Viterbi 算法识别；工程上常通过自定义词典提高领域文本分词效果
```python
import jieba
text = "我来到北京清华大学"

print("精确模式：", jieba.cut(text, cut_all=False))
print("全模式：", jieba.cut(text, cut_all=True))
print("搜索引擎模式：", jieba.cut_for_search(text))

# 大致输出会类似这样，不同版本或词典状态下可能略有差异
# 精确模式： ['我', '来到', '北京', '清华大学']
# 全模式： ['我', '来到', '北京', '清华', '清华大学', '华大', '大学']
# 搜索引擎模式： ['我', '来到', '北京', '清华', '华大', '大学', '清华大学']
```

**nn.Embedding**
`nn.Embedding` 是 PyTorch 中用于离散 ID 到连续向量映射的查表层，内部维护一个形状为 `[num_embeddings, embedding_dim]` 的可训练矩阵；输入是整数索引张量，输出会在原输入形状后追加一个 `embedding_dim` 维度；它等价于 one-hot 向量乘权重矩阵，但实现上直接按索引查表，更高效；在 NLP 中常用于词嵌入、字嵌入、token embedding
```bash
# Embedding 要点速记
# 1. API nn.Embedding(词表大小, 词向量的维度)
# 2. 获取词向量 embedding(tensor(index)) -> 要使用张量来获取
# index 必须为整数的索引值，且大小不能超过词表大小
# 3. 取词向量的时候，相当于只把索引值换成向量值，其他维度不发生改变
# 例如 [[1]] -> [[[2., 3., 5., 6.]]] 1 -> [2., 3., 5., 6.]
```
数学上，假设词表大小是 $V$，向量维度是 $D$，那么 Embedding 参数矩阵是：
$$E \in \mathbb{R}^{V \times D}$$
如果输入 token id 是 $i$，输出就是矩阵第 $i$ 行：$$\text{embedding}(i) = E_i$$也就是说，Embedding 本质上就是一次“查表”：
$$token\_id \rightarrow 查 Embedding 矩阵对应行 \rightarrow 得到 D 维向量$$
```python
import torch
import torch.nn as nn

embedding = nn.Embedding(
    num_embeddings=10,  # 词表大小：一共有 10 个 token，id 范围是 0~9
    embedding_dim=4     # 每个 token 映射成 4 维向量
)

input_ids = torch.tensor([1, 2, 4, 5])

output = embedding(input_ids)

print(output)
print(output.shape)

# 批量输入时的形状变化:
# input_ids = torch.tensor([
#    [1, 2, 3],
#    [4, 5, 6]
#])

#output = embedding(input_ids)
#print(output.shape)
## 输出则是 torch.Size([2, 3, 4])
```


# RNN
RNN，全称是 **Recurrent Neural Network，循环神经网络**。它是一类专门处理“序列数据”的神经网络，比如:
- 一句话：我 / 喜欢 / 学习 / NLP
- 一段时间序列：今天、明天、后天的气温

RNN 的核心特点是：**它会把前面看到的信息，通过隐藏状态传到后面:**
$$当前输入 + 过去记忆 \rightarrow 当前隐藏状态 \rightarrow 当前输出$$
用数学形式写就是：
$$h_t = f(x_t, h_{t-1})$$
- $x_t$：当前时刻的输入，比如当前这个词
- $h_{t-1}$：上一个时刻留下来的隐藏状态，也就是“历史记忆”
- $h_t$：当前时刻新的隐藏状态
- $f$：RNN 内部的计算函数
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260522133422234.png?imageSlim)

**举例说明**
文本数据是具有序列特性的, 例如: "我喜欢吃苹果", 这串文本就是具有序列关系的，"喜欢" 需要在 "我" 之后，"苹果" 需要在 "吃" 之后, 如果颠倒了顺序，那么可能就会表达不同的意思
```Bash
举例说明:
我 喜欢 吃 苹果
RNN,不是一次性
看到“我”      -> 形成记忆 h1
看到“喜欢”    -> 结合 h1，形成 h2
看到“吃”      -> 结合 h2，形成 h3
看到“苹果”    -> 结合 h3，形成 h4
```
RNN 的“循环”不是指程序真的无限循环，而是指：**同一个网络结构会在序列的每个位置重复使用，并且把隐藏状态一路传下去**
它适合处理有顺序依赖的数据。比如在句子里，“我喜欢吃”会影响模型判断后面更可能出现“苹果”“米饭”，而不是完全随机的词

**单层RNN的前向推理流程**
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260522140349949.png?imageSlim)


**多层RNN的前向推理流程**


**RNN的长期依赖问题**
但是,普通 RNN 有一个问题：如果序列太长，前面的信息传到后面时容易变弱，这叫 **长期依赖问题**。所以后来又出现了改进版本：
- **LSTM**：更擅长记住长期信息
- **GRU**：结构比 LSTM 简洁一些，也能缓解长期依赖问题

**Pytorch API: RNN**
```python
import torch

rnn = torch.nn.RNN(
    input_size,  # 输入特征维度。NLP 中通常等于词向量维度
    hidden_size, # 隐藏状态h的维度，也就是 RNN 每个时间步输出向量的维度
    num_layers=1 # RNN 堆叠层数，默认是 1
)
rnn = nn.RNN(input_size=128, hidden_size=256, num_layers=1)

# 输入格式
rnn(x, h0)#调用方式 x:输入序列  h0:初始隐藏状态
# x 的形状:[seq_len, batch_size, input_size] 
# [seq_len:序列长度,一句话有多少个Token,
#  batch_size:一次送入多少句子,
#  input_size:词向量的维度]

# h0 的形状:[num_layers, batch_size, hidden_size]
# [num_layers:RNN的隐藏层层数,
#  batch_size: batch_size大小,
#  hidden_size:隐藏层的维度]


#输出格式
output, hn = rnn(x, h0)# nn.RNN 会返回两个结果：output以及hn
# output 保存所有时间步的 hidden state -->整个序列每一步的输出记录
# hn 保存最后一个时间步的 hidden state -->序列处理结束后的最终记忆
# 输入x 与 输出output的形状格式是一致的,输入h0 与 输出hn的形状格式是一致的,方便进行循环计算

#例如:
output.shape = [5, 32, 256]
#表示: output输出 5 个时间步, 32 个句子每个时间步, 输出 256 维向量
```

# RNN实战---生成周杰伦歌词

# 参考资料

# 面试问题
**Q1:请介绍一下什么是RNN?**

