最后是给大家透个老底, 主要是讲讲我们在 **做项目的思路**
确定输入 + 确定输出 + 模型选型(比较重要) + 效果优化(也许没那么重要)

## 数据集选型---为什么选这个数据集?
我们是在Kaggle上寻找的数据集, 为啥是Kaggle?

**时间比较紧**：项目周期只有一天，Kaggle 已经把 train、test 和 submission 文件都准备好了，我们可以少花一些时间在数据清洗和格式整理上，把重点放在模型训练和结果对比上

**数据规模刚好**：这个数据集大约有 59 万行、20 个特征和 1 个二分类标签，数据量足够支撑深度学习模型训练，但又不会大到实验成本太高

**方便对比**：Kaggle 提供统一的 ROC-AUC 指标和排行榜，所以我们可以把本地验证结果和线上提交结果进行对照，也方便和 LightGBM 这类表格模型做比较

**场景也比较好讲**：这个任务是预测客户是否流失，比较贴近真实业务，比如运营团队可能会根据模型结果找出高风险客户，再考虑是否做挽留，所以这个题目也比较适合包装和展示

Kaggle这个数据集预览的功能很不错, 连EDA的时间也省了不少(当然这个是初级的EDA, 高级的EDA还有分析特征之间的相关性什么的)
https://www.kaggle.com/competitions/playground-series-s6e3/data?select=train.csv
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260524142615989.png?imageSlim)

## 评估效果---为什么选用AUC值进行评估?
思路是:我们要做一个什么样的任务? 现在考虑模型最后输出的结果是什么? 好在Kaggle也直接给我们定死了, 要求我们输出的是AUC值, 也就是ROC曲线的线下面积
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260524145152779.png?imageSlim)
**为什么Kaggle要求选用AUC值进行评估?而不是什么ACC这种准确率?**
AUC 适合这个 Churn(流失概率) 二分类任务，核心原因是：**它评估的是模型对正负样本的排序能力，而不是某一个固定阈值下的硬分类结果** 结合这个场景就是, 随机抽一个流失用户和一个不流失用户, 模型是否给流失用户更高的分数

**ACC 不一定合理**: 普通 accuracy 需要先定一个阈值：`
```
pred = prob >= 0.5
```
但 0.5 不一定合理。比如 Churn(流失概率)任务里，可能只要流失概率超过 0.35 就值得运营团队干预，也可能预算有限，只能干预概率最高的前 5% 用户

## 优化方案---模型怎么选型?(非常重要)
**思路是:先问问GPT, 看看在Kaggle打竞赛的大佬们一般都选用什么模型?**
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260524150136008.png?imageSlim)

**你甚至可以问问GPT, 对于不同类型的数据集, 一般选用什么模型好一点**
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260524150653917.png?imageSlim)

**这个时候就可以结合个人的需求进行追问**
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260524151131997.png?imageSlim)
**最终我们敲定了使用LightGBM以及FT-Transformer这两个模型**

**LightGBM**就直接调 lightgbm 的API就行了
**FT-Transforme**r需要对***Revisiting Deep Learning Models for Tabular Data(NeurIPS 2021)*** 这篇论文做论文复现
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260524151503700.png?imageSlim)

***Revisiting Deep Learning Models for Tabular Data(NeurIPS 2021)*** 所给出的结论:
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260524152102793.png?imageSlim)

## 优化方案---在哪里寻找优化得更好的方案?
**还有多少优化提升的空间?** 要优化模型的效果, 首先应该去看一下还有多少优化提升的空间?
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260524143050304.png?imageSlim)思路是: Kaggle/Predict Customer Churn/Leaderboard 直接到Kaggle竞赛的排行榜里面, 看看各个大佬们的分数都是多少?
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260524144307617.png?imageSlim)

**如何寻找到更好的优化方案?**
思路是: Kaggle/Predict Customer Churn/Discussion 讨论区,可以看到各位大佬的优化方案
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260524133341912.png?imageSlim)
**Kaggle竞赛第一名优化方案:**
https://www.kaggle.com/competitions/playground-series-s6e3/writeups/1st-place-gpt5-4-gemini3-1-claudeopus4-6-kgm
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260524133140353.png?imageSlim)
**Kaggle竞赛第三名优化方案:**
https://www.kaggle.com/competitions/playground-series-s6e3/writeups/3rd-place-solution-an-ensemble-of-100-oofs
![image.png](https://img.vectorpeak.cn/obsidian/2026/05-06/20260524133657942.png?imageSlim)

**这个时候,聪明的人都会选择不优化了**