# 【基础篇】TF-IDF 和 BM25

> 好的，我们来详细解释一下 TF-IDF 和 BM25，并通过例子进行对比。
>
> 这两种都是信息检索领域中用于衡量一个词语对于一个文档（或一个查询）重要性的算法，常用于搜索引擎的排序。

## 1. TF-IDF (Term Frequency-Inverse Document Frequency)

### 1.1 概念

TF-IDF 是一种统计方法，用以评估一个词语对于一个文件集或一个语料库中的其中一份文件的重要程度。它的核心思想是：

- 如果一个词语在一篇文章中出现的频率（TF）高，并且在其他文章中很少出现（IDF 低），则认为此词语具有很好的类别区分能力，对这篇文章很重要。

**TF-IDF 由两部分组成：**

- **TF (Term Frequency - 词频)：**
  - 衡量一个词语在**当前文档**中出现的频繁程度。
  - 计算方法：

$$
TF(t,d)=\frac{\text{词 }t\text{ 在文档 }d\text{ 中出现的次数}}{\text{文档 }d\text{ 的总词数}}
$$

  - 有时也会使用其他变体，比如取对数 $\log(1+\text{词 }t\text{ 在文档 }d\text{ 中出现的次数})$ 来平滑词频的影响。

- **IDF (Inverse Document Frequency - 逆文档频率)：**
  - 衡量一个词语在**整个文档集合**中的普遍程度。如果一个词在很多文档中都出现，那么它的 IDF 值会低，说明这个词区分度不高（比如“的”、“是”）。
  - 计算方法：

$$
IDF(t,D)=\log\left(\frac{\text{文档总数 }N}{\text{包含词 }t\text{ 的文档数 }n(t)+1}\right)
$$

  - $+1$ 是为了避免分母为 0（如果一个词在所有文档中都没出现）。$\log$ 通常是以 10 或 e 为底。

1. **TF-IDF Score：**

$$
TF\text{-}IDF(t,d,D)=TF(t,d)\times IDF(t,D)
$$

简单来说：一个词在一个文档中出现次数越多，它对该文档可能越重要（TF高）。但如果这个词在所有文档中都频繁出现，那它就没那么特殊了（IDF低）。TF-IDF就是要把这两方面结合起来。

### 1.2 TF-IDF 例子

假设我们有以下 3 个文档：

- **D1：** "苹果 香蕉 苹果"（共3个词）
- **D2：** "香蕉 柠檬 橙子"（共3个词）
- **D3：** "苹果 苹果 苹果 柠檬"（共4个词）

我们要计算查询 **Q: "苹果 香蕉"** 与这三个文档的相关性。

#### 1. 计算每个词的 IDF 值（文档总数 N = 3）

- "苹果"：出现在 D1, D3（共2个文档）

我们简化，使用：

$$
IDF(t)=\log_{10}\left(\frac{N}{n(t)}\right)
$$

$$
IDF(\text{苹果}): n(\text{苹果})=2 \Rightarrow \log_{10}\left(\frac{3}{2}\right)=\log_{10}(1.5)\approx0.176
$$

$$
IDF(\text{香蕉}): n(\text{香蕉})=2 \Rightarrow \log_{10}\left(\frac{3}{2}\right)=\log_{10}(1.5)\approx0.176
$$

$$
IDF(\text{柠檬}): n(\text{柠檬})=2 \Rightarrow \log_{10}\left(\frac{3}{2}\right)=\log_{10}(1.5)\approx0.176
$$

$$
IDF(\text{橙子}): n(\text{橙子})=1 \Rightarrow \log_{10}\left(\frac{3}{1}\right)=\log_{10}(3)\approx0.477
$$

#### 2. 计算查询词在每个文档中的 TF-IDF 值

对于查询 Q: **"苹果 香蕉"**

- **文档 D1: "苹果 香蕉 苹果"（总词数 3）**

$$
TF(\text{苹果},D1)=\frac{2}{3}
$$

$$
TF(\text{香蕉},D1)=\frac{1}{3}
$$

$$
TF\text{-}IDF(\text{苹果},D1)=\frac{2}{3}\times0.176\approx0.117
$$

$$
TF\text{-}IDF(\text{香蕉},D1)=\frac{1}{3}\times0.176\approx0.059
$$

$$
Score(D1,Q)=TF\text{-}IDF(\text{苹果},D1)+TF\text{-}IDF(\text{香蕉},D1)\approx0.117+0.059=0.176
$$

- **文档 D2: "香蕉 柠檬 橙子"（总词数 3）**

$$
TF(\text{苹果},D2)=\frac{0}{3}=0
$$

$$
TF(\text{香蕉},D2)=\frac{1}{3}
$$

$$
TF\text{-}IDF(\text{苹果},D2)=0\times0.176=0
$$

$$
TF\text{-}IDF(\text{香蕉},D2)=\frac{1}{3}\times0.176\approx0.059
$$

$$
Score(D2,Q)=TF\text{-}IDF(\text{苹果},D2)+TF\text{-}IDF(\text{香蕉},D2)\approx0+0.059=0.059
$$

- **文档 D3: "苹果 苹果 苹果 柠檬"（总词数 4）**

$$
TF(\text{苹果},D3)=\frac{3}{4}
$$

$$
TF(\text{香蕉},D3)=\frac{0}{4}=0
$$

$$
TF\text{-}IDF(\text{苹果},D3)=\frac{3}{4}\times0.176\approx0.132
$$

$$
TF\text{-}IDF(\text{香蕉},D3)=0\times0.176=0
$$

$$
Score(D3,Q)=TF\text{-}IDF(\text{苹果},D3)+TF\text{-}IDF(\text{香蕉},D3)\approx0.132+0=0.132
$$

**排序结果（TF-IDF）：** D1 (0.176) > D3 (0.132) > D2 (0.059)

## 2. BM25 (Best Match 25)

### 2.1 概念

BM25 是在 TF-IDF 基础上发展起来的一种更先进、更有效的排序算法，它源于概率相关性模型。BM25 考虑了 TF-IDF 中一些未充分解决的问题：

1. **词频饱和度 (Term Frequency Saturation)：** TF-IDF 中，词频 TF 的值是线性增长的。但实际上，一个词在一个文档中从出现1次到出现3次，相关性的提升可能很明显；但从出现30次到出现33次，相关性的提升就没那么大了。BM25 引入了一个饱和函数，使得词频的贡献会随着词频增加而趋于饱和。

2. **文档长度归一化 (Document Length Normalization)：** 长文档天然更容易包含更多的查询词，TF-IDF 的简单归一化可能不够。BM25 对文档长度进行了更精细的归一化，会惩罚那些仅仅因为长而匹配上更多词的文档，但惩罚程度可以调节。

**BM25 公式（对于查询 Q 中的每个词 $t_i$）：**

$$
Score(D,Q)=\sum_{t_i\in Q}\left[
IDF(t_i)\times
\frac{f(t_i,D)\times(k_1+1)}
{f(t_i,D)+k_1\times\left(1-b+b\times\frac{\lvert D\rvert}{avgdl}\right)}
\right]
$$

其中：

- $IDF(t_i)$：查询词 $t_i$ 的逆文档频率。计算方法与 TF-IDF 略有不同，常用的是 Robertson-Spärck Jones IDF：

$$
IDF(t_i)=\ln\left(\frac{N-n(t_i)+0.5}{n(t_i)+0.5}+1\right)
$$

  - $N$：文档总数
  - $n(t_i)$：包含词 $t_i$ 的文档数

- $f(t_i,D)$：词 $t_i$ 在文档 $D$ 中的原始词频（raw count）。
- $\lvert D\rvert$：文档 $D$ 的长度（总词数）。
- $avgdl$：文档集中的平均文档长度。
- $k_1$：可调参数（通常取 1.2 到 2.0），用于控制词频饱和度。值越小，饱和越快。
- $b$：可调参数（通常取 0.75），用于控制文档长度归一化的程度。$b=0$ 表示不进行长度归一化，$b=1$ 表示完全根据文档长度进行归一化。

简单来说：BM25 也是基于词频和逆文档频率，但它对词频的影响做了非线性处理（会饱和），并且对文档长度的惩罚更智能（考虑平均长度）。

### 2.2 BM25 例子

使用与 TF-IDF 相同的文档和查询。

- **D1:** "苹果 香蕉 苹果"（$\lvert D_1\rvert=3$）
- **D2:** "香蕉 柠檬 橙子"（$\lvert D_2\rvert=3$）
- **D3:** "苹果 苹果 苹果 柠檬"（$\lvert D_3\rvert=4$）
- 查询 **Q: "苹果 香蕉"**
- 文档总数 $N=3$
- 平均文档长度：

$$
avgdl=\frac{(3+3+4)}{3}=\frac{10}{3}\approx3.33
$$

- 假设参数 $k_1=1.5$，$b=0.75$

#### 1. 计算每个查询词的 IDF 值（使用 BM25 的 IDF 公式，使用自然对数 ln）

- "苹果": $n(\text{苹果})=2$

$$
IDF(\text{苹果})=\ln\left(\frac{3-2+0.5}{2+0.5}+1\right)
=\ln\left(\frac{1.5}{2.5}+1\right)
=\ln(0.6+1)
=\ln(1.6)\approx0.470
$$

修正：之前用 $\log(1.6)\approx0.204$ 是基于 $\log10$ 或 $\log e$ 但数值错了，$\ln(1.6)\approx0.470$。

为了与之前 TF-IDF 的 IDF 值大小可比性及常见实践，BM25 IDF 通常使用自然对数。如果使用 $log10$，值会不同。我们这里统一使用自然对数 $\ln$。

$$
IDF(\text{苹果})=\ln(1.6)\approx0.470
$$

- "香蕉": $n(\text{香蕉})=2$

$$
IDF(\text{香蕉})=\ln(1.6)\approx0.470
$$

#### 2. 计算查询词在每个文档中的 BM25 得分项并求和

对于词 **"苹果"**：

- **D1：** 苹果词频为 2，文档长度为 3。

$$
\text{分子}=f(\text{苹果},D1)\times(k_1+1)=2\times(1.5+1)=2\times2.5=5
$$

$$
\text{分母部分长度项}=1-b+b\times\frac{\lvert D_1\rvert}{avgdl}
=1-0.75+0.75\times\frac{3}{3.33}
\approx0.25+0.75\times0.9009
\approx0.25+0.6757=0.9257
$$

$$
\text{分母}=f(\text{苹果},D1)+k_1\times(\text{分母部分长度项})
=2+1.5\times0.9257
\approx2+1.38855\approx3.38855
$$

$$
TermScore(\text{苹果},D1)=IDF(\text{苹果})\times\frac{5}{3.38855}
\approx0.470\times1.4755\approx0.6935
$$

- **D2:** $f(\text{苹果},D2)=0$

$$
TermScore(\text{苹果},D2)=0
$$

- **D3：** 苹果词频为 3，文档长度为 4。

$$
\text{分子}=f(\text{苹果},D3)\times(k_1+1)=3\times(1.5+1)=3\times2.5=7.5
$$

$$
\text{分母部分长度项}=1-b+b\times\frac{\lvert D_3\rvert}{avgdl}
=1-0.75+0.75\times\frac{4}{3.33}
\approx0.25+0.75\times1.2012
\approx0.25+0.9009=1.1509
$$

$$
\text{分母}=f(\text{苹果},D3)+k_1\times(\text{分母部分长度项})
=3+1.5\times1.1509
\approx3+1.72635\approx4.72635
$$

$$
TermScore(\text{苹果},D3)=IDF(\text{苹果})\times\frac{7.5}{4.72635}
\approx0.470\times1.5868\approx0.7458
$$

对于词 **"香蕉"**：

- **D1：** 香蕉词频为 1，文档长度为 3。

$$
\begin{aligned}
\text{分子}
&=f(\text{香蕉},D_1)\times(k_1+1) \\
&=1\times(1.5+1)=2.5
\end{aligned}
$$

$$
\text{分母部分长度项（与苹果在 }D_1\text{ 中相同）}\approx0.9257
$$

$$
\begin{aligned}
\text{分母}
&=f(\text{香蕉},D_1)+k_1\times(\text{分母部分长度项}) \\
&=1+1.5\times0.9257 \\
&\approx1+1.38855\approx2.38855
\end{aligned}
$$

$$
\begin{aligned}
TermScore(\text{香蕉},D_1)
&=IDF(\text{香蕉})\times\frac{2.5}{2.38855} \\
&\approx0.470\times1.0467\approx0.4919
\end{aligned}
$$

- **D2：** 香蕉词频为 1，文档长度为 3。

计算过程与香蕉在 D1 中完全相同，因为 $f$、$\lvert D\rvert$、$IDF$ 都相同。

$$
TermScore(\text{香蕉},D_2)\approx0.4919
$$

- **D3：** 香蕉词频为 0。

$$
TermScore(\text{香蕉},D_3)=0
$$

#### 3. 计算每个文档的总分（BM25 Score）

$$
\begin{aligned}
Score(D_1,Q)
&=TermScore(\text{苹果},D_1)+TermScore(\text{香蕉},D_1) \\
&\approx0.6935+0.4919=1.1854
\end{aligned}
$$

$$
\begin{aligned}
Score(D_2,Q)
&=TermScore(\text{苹果},D_2)+TermScore(\text{香蕉},D_2) \\
&\approx0+0.4919=0.4919
\end{aligned}
$$

$$
\begin{aligned}
Score(D_3,Q)
&=TermScore(\text{苹果},D_3)+TermScore(\text{香蕉},D_3) \\
&\approx0.7458+0=0.7458
\end{aligned}
$$

**排序结果（BM25）：** D1 (1.1854) > D3 (0.7458) > D2 (0.4919)

注意：BM25例子中的IDF计算及后续得分与之前版本有所调整，因为统一使用了自然对数ln并修正了计算，这使得IDF值变大，进而影响了最终的BM25分数。排序结果本身未改变。

在这个特定例子中，排序结果与 TF-IDF 相同，但得分的分布和计算方式有显著差异。

值得注意的是，D3 的“苹果”词频更高（3次 vs D1的2次），但在BM25中，D3的“苹果”项得分（约0.7458）确实高于 D1 的“苹果”项得分（约0.6935）。词频饱和度依然起作用，但因为IDF值变大了，词频的贡献也更明显。D3长度略长（4 vs 3）带来的一点惩罚（因为 $\lvert D_3\rvert/avgdl\approx1.2012$ 大于 $\lvert D_1\rvert/avgdl\approx0.9009$）也体现在分母的计算中。

## 3. TF-IDF vs BM25 对比

| 特性 | TF-IDF | BM25 |
| --- | --- | --- |
| 理论基础 | 启发式，向量空间模型 | 概率相关性模型（Probabilistic Relevance Model） |
| 词频（TF）处理 | 线性增长。词出现越多，TF值越大，无上限。 | 非线性增长，有饱和效应。词频达到一定程度后，其贡献增长放缓（通过 $k_1$ 参数调节）。 |
| 文档长度归一化 | 简单归一化（通常是除以文档总词数）。对长文档可能不够公平。 | 更复杂的归一化机制，考虑平均文档长度（$avgdl$），惩罚程度可通过 $b$ 参数调节。 |
| IDF 计算 | 有多种变体，基础形式 $\log(N/n(t))$ | 通常使用 Robertson-Spärck Jones IDF，考虑了 $N-n(t)$，更平滑。 |
| 参数 | 通常无参数（或TF/IDF有不同计算变体可选） | 有可调参数 $k_1$ 和 $b$，可以根据数据集特性进行优化。 |
| 性能/效果 | 作为基准效果不错，简单易懂。 | 通常在各种评测中表现优于 TF-IDF，是现代搜索引擎中更常用的基准算法。 |
| 计算复杂度 | 相对简单。 | 略复杂，但仍在可接受范围内。 |
| 对常见词的处理 | IDF会降低常见词权重，但极端常见词可能仍有影响。 | IDF处理类似，但饱和效应和长度归一化使其对各种词的分布更鲁棒。 |
| 适用场景 | 文本分类、关键词提取、简单搜索任务。 | 搜索引擎排序、信息检索任务，尤其是需要较高召回率和准确率的场景。 |

## 4. RAG中的稀疏向量

### 段落/句子级向量

- 一段话或一句话会生成一个稀疏向量，维度与词表大小相同，但非零位置包含所有在这段话中出现的词的权重（如 TF-IDF 分数）。
- 用途：全文索引、稀疏检索器（BM25/SPLADE）。
- 特点：比词级向量更能直接表示整个文本的内容，便于快速相似度检索。

在 **RAG（Retrieval-Augmented Generation）** 里，检索阶段一般是 **“一段话/一个文档块 → 一个稀疏向量”**，因为：

- 检索需要匹配查询向量与文档向量。
- 如果用词级向量，会丢失段落的整体语义关系，并且需要逐词匹配，效率低。
- 常见实现：BM25、SPLADE，把一段话编码成一个稀疏向量存入索引。

## 5. 总结

- **TF-IDF** 是一个经典且直观的算法，它抓住了“文档中重要且在其他地方不常见的词更重要”这一核心思想。它实现简单，效果尚可，是很多文本处理任务的良好起点。
- **BM25** 是对 TF-IDF 的重要改进。它通过引入词频饱和度和更精细的文档长度归一化，解决了 TF-IDF 的一些理论缺陷，从而在实际应用中（尤其是在大规模文档集合的搜索排序任务中）通常能取得更好的效果。BM25 的参数 $k_1$ 和 $b$ 提供了根据特定数据集调优的空间。
