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
    embedding_dim=4     # 词向量的维度: 每个 token 映射成 4 维向量
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
```bash
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
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260522143629114.png?imageSlim)


**RNN的长期依赖问题**
但是,普通 RNN 有一个问题：如果序列太长，前面的信息传到后面时容易变弱，这叫 **长期依赖问题**。所以后来又出现了改进版本：
- **LSTM**：更擅长记住长期信息
- **GRU**：结构比 LSTM 简洁一些，也能缓解长期依赖问题

**Pytorch_API:RNN**
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

# LSTM
LSTM(Long Short-Term Memory / 长短期记忆网络)是一种特殊的循环神经网络(RNN), 它最大的特点是: 能“记住长期信息”, LSTM 通过给网络加了“记忆单元(Cell State), 解决了普通 RNN 容易遗忘的问题


**LSTM 有两个状态,三个门**
**Hidden State**: $h_t​$  -->短期工作记忆
**Cell State**: $C_t$       -->长期记忆

**ForgetGate** 
	遗忘门:             $ft=σ(Wf[ht−1,xt]+bf)$ 

**InputGate**
	生成候选记忆:  $\tilde{C}_t=tanh(W_c​[h_{t−1}​,x_t​]+b_c​)$
	输入门:             $i_t=σ(W_i[h_{t−1},x_t]+b_i)$ 
	更新记忆:         $C_t=ft⊙C_{t−1}+i_t⊙\tilde{C}_t$
	
**OutputGate**
	输出门:            $o_t​=σ(W_o​[h_t−1​,x_t​]+b_o​)$
	最终隐藏状态: $h_t=o_t⊙tanh⁡(Ct)$
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260523093228125.png?imageSlim)

**为什么LSTM能够解决RNN的长期依赖性问题?**
关键在于Cell State 的“直通结构” 这一项：$C_{t−1} \rightarrow C_t$ 几乎是线性传播
这意味着：梯度不会像普通 RNN 那样疯狂连乘衰减

**Pytorch_API:LSTM**
```python
import torch
import torch.nn as nn

lstm = torch.nn.LSTM(
    input_size,   # 输入特征维度。NLP 中通常等于词向量维度
    hidden_size,  # 隐藏状态 h 的维度，也是 LSTM 每个时间步输出向量的维度
    num_layers=1  # LSTM 堆叠层数，默认是 1
)

lstm = nn.LSTM(input_size=128, hidden_size=256, num_layers=1)

# 输入格式
lstm(x, (h0, c0))  # 调用方式 x: 输入序列  h0: 初始隐藏状态  c0: 初始细胞状态

# x 的形状: [seq_len, batch_size, input_size]
# [seq_len: 序列长度，一句话有多少个 Token,
#  batch_size: 一次送入多少个句子,
#  input_size: 词向量的维度]

# h0 的形状: [num_layers, batch_size, hidden_size]
# [num_layers: LSTM 的隐藏层层数,
#  batch_size: batch_size 大小,
#  hidden_size: 隐藏状态 h 的维度]

# c0 的形状: [num_layers, batch_size, hidden_size]
# [num_layers: LSTM 的隐藏层层数,
#  batch_size: batch_size 大小,
#  hidden_size: 细胞状态 C 的维度]

# 输出格式
output, (hn, cn) = lstm(x, (h0, c0))  # nn.LSTM 会返回 output、hn、cn

# output 保存所有时间步最后一层的 hidden state --> 整个序列每一步的输出记录
# hn 保存最后一个时间步的 hidden state --> 序列处理结束后的最终短期记忆
# cn 保存最后一个时间步的 cell state   --> 序列处理结束后的最终长期记忆

# 输入 x 与 输出 output 的形状格式是一致的
# 输入 h0 与 输出 hn 的形状格式是一致的
# 输入 c0 与 输出 cn 的形状格式是一致的
# 这样方便把当前序列处理后的状态继续传给下一段序列

# 例如:
output.shape = [5, 32, 256]
hn.shape = [1, 32, 256]
cn.shape = [1, 32, 256]

# 表示:
# output 输出 5 个时间步, 32 个句子每个时间步输出 256 维向量
# hn 表示 1 层 LSTM, 32 个句子, 每个句子的最终隐藏状态是 256 维
# cn 表示 1 层 LSTM, 32 个句子, 每个句子的最终细胞状态是 256 维
```
# GRU
GRU（Gated Recurrent Unit / 门控循环单元）是一种特殊的循环神经网络（RNN），可以看作是 LSTM 的简化版本。它最大的特点是：**没有单独的 Cell State，只用 Hidden State 来同时保存记忆和输出结果**。相比 LSTM，GRU 的结构更简单，参数更少，训练速度通常更快

**GRU 有一个状态，两个门**
**Hidden State**: $h_t$  --> 表示当前隐藏状态，既表示当前输出，也表示传给下一时间步的记忆。GRU 没有单独的Cell State: $C_t$ 也就是说，GRU 把 LSTM 里的“长期记忆”和“短期输出”合并到了一个状态$h_t$

**ResetGate**
	重置门:决定在生成候选记忆时，要看多少过去的信息$$r_t = \sigma(W_r [h_{t-1}, x_t] + b_r$$ $r_t$越接近 0：越少参考过去的隐藏状态  $r_t$ 越接近 1：越多保留过去的隐藏状态

**UpdateGate**
	更新门:决定最终状态中，旧记忆和新候选记忆各占多少$$z_t = \sigma(W_z [h_{t-1}, x_t] + b_z)$$可以理解为：$z_t$ 控制当前时间步要“更新多少”

**Candidate Hidden State**
	候选隐藏状态：先用重置门过滤旧记忆，再结合当前输入生成新的候选状态$$\tilde{h}_t = tanh(W_h [r_t \odot h_{t-1}, x_t] + b_h$$$r_t \odot h_{t-1}$表示：让重置门先筛选上一时刻的隐藏状态，再参与新候选状态的生成

**Final Hidden State**
	最终隐藏状态：用更新门把旧状态和候选状态融合起来$$h_t = (1 - z_t) \odot h_{t-1} + z_t \odot \tilde{h}_t$$也就是：旧状态保留一部分，新候选状态写入一部分

	
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260523095100187.png?imageSlim)

**Pytorch_API:GRU**
```python
import torch
import torch.nn as nn

gru = torch.nn.GRU(
    input_size,   # 输入特征维度。NLP 中通常等于词向量维度
    hidden_size,  # 隐藏状态 h 的维度，也是 GRU 每个时间步输出向量的维度
    num_layers=1  # GRU 堆叠层数，默认是 1
)

gru = nn.GRU(input_size=128, hidden_size=256, num_layers=1)

# 输入格式
gru(x, h0)  # 调用方式 x: 输入序列  h0: 初始隐藏状态

# x 的形状: [seq_len, batch_size, input_size]
# [seq_len: 序列长度，一句话有多少个 Token,
#  batch_size: 一次送入多少个句子,
#  input_size: 词向量的维度]

# h0 的形状: [num_layers, batch_size, hidden_size]
# [num_layers: GRU 的隐藏层层数,
#  batch_size: batch_size 大小,
#  hidden_size: 隐藏状态 h 的维度]

# 输出格式
output, hn = gru(x, h0)  # nn.GRU 会返回两个结果：output 以及 hn

# output 保存所有时间步最后一层的 hidden state --> 整个序列每一步的输出记录
# hn 保存最后一个时间步的 hidden state --> 序列处理结束后的最终记忆

# 输入 x 与 输出 output 的形状格式是一致的
# 输入 h0 与 输出 hn 的形状格式是一致的
# GRU 没有 c0 和 cn，因为它没有单独的 Cell State

# 例如:
output.shape = [5, 32, 256]
hn.shape = [1, 32, 256]

# 表示:
# output 输出 5 个时间步, 32 个句子每个时间步输出 256 维向量
# hn 表示 1 层 GRU, 32 个句子, 每个句子的最终隐藏状态是 256 维
```

# RNN实战---生成JayChou歌词
文本生成任务是一种常见的自然语言处理任务，输入一个开始词能够预测出后面的词序列。本案例将会使用循环神经网络来实现周杰伦歌词生成任务

### 导入依赖包
```python
import torch 
import re 
import jieba 
from torch.utils.data import DataLoader 
import torch.nn as nn 
import torch.nn.functional as F 
import torch.optim as optim 
import time
```

### 获取数据
[jaychou_lyrics.txt.zip:周杰伦歌词数据集](https://gitea.cncfstack.com/learning/d2l-zh/src/commit/c419d5fac9a2540e1dd5397b5676016b85d3c0c1/data/jaychou_lyrics.txt.zip)
我们收集了周杰伦从第一张专辑《Jay》到第十张专辑《跨时代》中的歌词，来训练神经网络模型，当模型训练好后，我们就可以用这个模型来创作歌词。该数据集共有5819 行文本,数据集如下:
```text
想要有直升机  
想要和你飞到宇宙去  
想要和你融化在一起  
融化在宇宙里  
我每天每天每天在想想想想着你  
这样的甜蜜  
让我开始相信命运  
感谢地心引力  
让我碰到你  
漂亮的让我面红的可爱女人
```

### 获取数据集并构建词表
在进行自然语言处理任务之前，首要做的就是就是构建词表
所谓的词表就是将数据进行分词，然后给每一个词分配一个唯一的编号，便于我们送入词嵌入层获取每个词的词向量. 整体流程是: 1.获取文本数据 2.分词，并进行去重 3.构建词表

|  序号 | 单词    |
| --: | ----- |
|   1 | who   |
|   2 | when  |
|   3 | where |
|   4 | what  |
|   5 | why   |
|   6 | whose |
|   7 | which |
```python
path=r"data/jaychou_lyrics.txt"
def bulid_vocab():
	unique_words,all_words,corpus_idx=[],[],[]#注意不要使用[]*3,否则三者共用一个地址
	
	with open(path,'r',encoding='utf-8') as f:
		for line in f:
			words = jieba.lcut(line)
			all_words.append(words)
				
			for word in words:
				if word not in unique_words:
					unique_words.append(word)
					
		vocab_size = len(uniquewords)
					
	word_to_idx = {word:idx for idx,word in emumerate(unique_words)}
	
	for words in all_words:
		temp=[]
		for word in words:
			temp.append(word_to_index[word])
		temp.append(word_to_index[" "])
		corpus_idx.extend(temp) 
	
	return unique_words,vocab_size,word_to_idx,corpus_idx
	 
if __name__ = "__main__":
	unique_words, word_to_index, word_count, corpus_idx = build_vocab() 
	print("词的数量：\n", word_count) 
	print("去重后的词:\n", unique_words) 
	print("每个词的索引：\n", word_to_index) 
	print("当前文档中每个词对应的索引：\n", corpus_idx)
```

### 构建数据集对象
在训练的时候，为了便于读取语料，我们会构建一个 Dataset 对象，如下所示：
```python
class LyricsDataset(torch.utils.data.Dataset):
    def __init__(self, corpus_idx, num_chars):
        # 文档数据中词的索引
        self.corpus_idx = corpus_idx
        # 每个句子中词的个数
        self.num_chars = num_chars
        # 词的数量
        self.word_count = len(self.corpus_idx)
        # 句子数量
        self.number = self.word_count // self.num_chars

    def __len__(self):
        # 返回句子数量
        return self.number

    def __getitem__(self, idx):
        # idx指词的索引，并将其修正索引值到文档的范围里面
        start = min(max(idx, 0), self.word_count - self.num_chars - 2)
        # 输入值
        x = self.corpus_idx[start: start + self.num_chars]
        # 网络预测结果（目标值）
        y = self.corpus_idx[start + 1: start + 1 + self.num_chars]
        # 返回结果
        return torch.tensor(x), torch.tensor(y)

if __name__ == "__main__":
	# 数据获取实例化
	dataset = LyricsDataset(corpus_idx, 5)
	x, y = dataset.__getitem__(0)
	print("网络输入值：", x)
	print("目标值：", y)
	# 网络输入值: tensor([ 0,  1,  2,  3, 40])
	# 目标值:    tensor([ 1,  2,  3, 40,  0])
```

### 模型构建
我们用于实现《歌词生成》的网络模型，主要包含了三个层:
- 词嵌入层: 用于将语料转换为词向量
- 循环网络层: 提取句子语义
- 全连接层: 输出对词典中每个词的预测概率
```python
class TextGenerator(nn.Module):
	def __init__(self, word_count):
		super(TextGenerator, self).__init__() 
		self.embedding = nn.Embedding(vocab_size, 128)# 初始化词嵌入层: 词向量的维度为128
		self.rnn = nn.RNN(128,128,2)# 循环网络层: 词嵌入向量维度 128, 隐藏层向量维度 128, 隐藏层层数2
		self.out = nn.Linear(128,vocab_size)# 全连接层/输出层: 特征向量维度128与隐藏向量维度相同
	
	def forward(self,inputs,hidden):
		embedding = self.embedding(inputs)
		output,hidden = self.rnn(embedding.transpose(0,1),hidden)
		# 输出维度: [batch,seq_len,embedding维度:128]
		# 修改后的维度:[seq_len,batch,embedding维度:128]
		output = self.out(output.reshape((-1, output.shape[-1])))
		# 输入维度:[seq_len * batch,embedding维度:128]
		# 输出维度:[seq_len * batch,embedding维度:128)
		return output,hidden
		
	def init_hidden(self,batch_size):
		return torch.zeros(2,batch_size,128)

```

### 模型训练
从磁盘加载训练好的模型，进行预测。预测函数，输入第一个指定的词，我们将该词输入网路，预测出下一个词，再将预测的出的词再次送入网络，预测出下一个词，以此类推，知道预测出我们指定长度的内容
```python
def train():
    index_to_word, word_to_index, word_count, corpus_idx = build_vocab()# 构建词典
    lyrics = LyricsDataset(corpus_idx, 32) # 数据集
    model = TextGenerator(word_count) # 初始化模型
    criterion = nn.CrossEntropyLoss() # 损失函数
    optimizer = optim.Adam(model.parameters(), lr=1e-3) # 优化方法

    epochs = 10 # 训练轮数
    for epoch_idx in range(epochs):
        lyrics_dataloader = DataLoader(
            lyrics,shuffle=True,batch_size=1)# 数据加载器
        start = time.time()# 训练开始时间
        iter_num = 0 # 迭代次数
        total_loss = 0.0 # 训练损失

        # 遍历数据集
        for x, y in lyrics_dataloader:
            hidden = model.init_hidden(bs=1)# 隐藏状态初始化
            output, hidden = model(x, hidden)# 模型前向计算
            
            # 计算损失
            # y: [batch, seq_len] -> [seq_len, batch] -> [seq_len * batch]
            y = torch.transpose(y, 0, 1).contiguous().view(-1)
            
            loss = criterion(output, y)
            optimizer.zero_grad() # 梯度清零
            loss.backward() # 反向传播
            optimizer.step() # 参数更新

            iter_num += 1# 统计信息
            total_loss += loss.item()# 统计信息

        # 打印每轮训练信息
        print('epoch %3s loss: %.5f time %.2f'
            % (epoch_idx + 1, total_loss / iter_num, time.time() - start)
        )
    torch.save(model.state_dict(), 'data/lyrics_model_%d.pth' % epochs) # 模型存储

if __name__ == "__main__":
    unique_words, word_to_index, word_count, corpus_idx = build_vocab() # 获取数据
    dataset = LyricsDataset(corpus_idx, 5) # 数据集实例化，用于测试数据读取
    train() # 模型训练
```

### 模型预测
```python
def predict(start_word, sentence_length):
    index_to_word, word_to_index, word_count, _ = build_vocab() # 构建词典
    model = TextGenerator(word_count)# 构建模型
    model.load_state_dict(torch.load("data/lyrics_model_10.pth"))# 加载模型参数
    model.eval()# 设置为预测模式

    hidden = model.init_hidden(bs=1) # 初始化隐藏状态
    word_idx = word_to_index[start_word]# 将起始词转换为索引
    generate_sentence = [word_idx]# 存放生成词的索引


    for _ in range(sentence_length):# 逐词生成
        output, hidden = model(torch.tensor([[word_idx]]), hidden)# 模型预测

        word_idx = torch.argmax(output).item()# 获取预测结果

        generate_sentence.append(word_idx)# 保存预测出的词索引

    for idx in generate_sentence:# 根据索引还原成文字并打印
        print(index_to_word[idx], end="")


if __name__ == "__main__":
    predict("分手", 100)# 模型预测
```
# 参考资料

# 面试问题
**Q1:请介绍一下什么是RNN?**


