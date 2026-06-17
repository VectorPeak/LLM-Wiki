

面试问答
>有一些面试的时候如果让别人觉得你很牛掰?
>1.提到具体的数字,诸如年份
>2.多说一些诸如 原始论文xx  原始论文是怎么做的
>3.最好能够手推公式,去记忆去背公式,哪怕你不理解,但是面试的时候如果能手写出来也很不错
>4.在讲的时候,可以多加入一些 API 以及 具体的代码/函数 专业的名词/专业的术语

1.请你谈一下你对BERT的理解
BERT是谷歌在2018年推出的预训练模型, 它主要有三层架构,Embedding层,Encoder层以及 Pooler层
[Embedding层]BERT主要使用了三种Embedding方式,Token Embeddding, Segment Embedding, Position Embedding. 
[Encoder层]BERT使用的是Encoder-Only的架构, 相对来说更适合语义理解和意图识别, Encoder层数是12, 多头注意力的头数是12, 隐藏层维度是768. 当然在BERT的原始论文里有两种Encoder堆叠方式, 分别是BERT-base(12层)以及BERT-large(24层)
[Pooler层]可以拿来做迁移学习,在后面接一个分类层来做5分类,10分类