# 大模型系统化学习路线（19天打卡版·Markdown版）

总周期：19天 \| 前置要求：会Python基础、掌握基础PyTorch操作

核心原则：拒绝纯理论死磕，每日必敲代码，学完能落地、能理解大模型底层逻辑

# 一、阶段一：数学最低配置（3天，只抓大模型刚需）

## Day1：矩阵\&amp;向量核心直觉

- 核心知识点：向量=特征，矩阵=批量特征的线性变换

- 必懂重点：内积=计算特征相似度（Transformer注意力机制的核心）

- 实操任务：用numpy写3段极简代码（向量内积、简单矩阵乘法、矩阵与向量相乘）

- 打卡输出：手写1句笔记——用大白话解释矩阵乘法的本质

### Day1 实操代码模板（可直接复制运行）

```python
import numpy as np

# 1. 向量内积（注意力核心）
vec1 = np.array([1, 2, 3])
vec2 = np.array([4, 5, 6])
inner_product = np.dot(vec1, vec2)
print("向量内积结果：", inner_product)

# 2. 简单矩阵乘法
mat1 = np.array([[1, 2], [3, 4]])
mat2 = np.array([[5, 6], [7, 8]])
mat_mult = np.dot(mat1, mat2)
print("矩阵乘法结果：\n", mat_mult)

# 3. 矩阵与向量相乘
mat = np.array([[1, 2], [3, 4]])
vec = np.array([5, 6])
mat_vec_mult = np.dot(mat, vec)
print("矩阵与向量相乘结果：", mat_vec_mult)
```

## Day2：微积分\&amp;梯度下降直觉

- 核心知识点：放弃复杂求导证明，只记核心——梯度=loss（损失）减小的方向

- 必懂重点：学习率=梯度下降的“迈步大小”（步太大易震荡、步太小收敛慢）

- 实操任务：手动实现极简梯度下降算法，拟合一条简单直线（y=kx\+b）

- 打卡输出：用大白话解释“梯度下降在训练模型时到底在做什么”

### Day2 实操代码模板（可直接复制运行）

```python
import numpy as np
import matplotlib.pyplot as plt

# 1. 生成模拟数据（y = 2x + 3 + 微小噪声）
x = np.linspace(0, 10, 100)
y_true = 2 * x + 3 + np.random.normal(0, 0.5, 100)

# 2. 初始化参数（k=斜率，b=截距）
k = np.random.randn()  # 随机初始值
b = np.random.randn()
learning_rate = 0.01  # 学习率
epochs = 1000  # 迭代次数

# 3. 手动实现梯度下降
loss_history = []
for _ in range(epochs):
    # 前向计算预测值
    y_pred = k * x + b
    # 计算损失（均方误差）
    loss = np.mean((y_pred - y_true) ** 2)
    loss_history.append(loss)
    # 计算梯度（对k和b求导）
    grad_k = 2 * np.mean((y_pred - y_true) * x)
    grad_b = 2 * np.mean(y_pred - y_true)
    # 更新参数
    k -= learning_rate * grad_k
    b -= learning_rate * grad_b

# 4. 可视化结果
plt.plot(x, y_true, 'b.', label='真实数据')
plt.plot(x, k * x + b, 'r-', label=f'拟合直线: y={k:.2f}x + {b:.2f}')
plt.xlabel('x')
plt.ylabel('y')
plt.legend()
plt.show()

# 5. 打印最终参数和损失
print(f"最终参数：k={k:.2f}, b={b:.2f}")
print(f"最终损失：{loss:.4f}")
```

## Day3：概率\&amp;Softmax\&amp;噪声

- 核心知识点：Softmax函数的作用——将模型输出的分数，转换为概率分布（大模型选词、分类全靠它）

- 必懂重点：噪声的含义、采样的作用（为后续Diffusion生成模型打基础）

- 实操任务：手写Softmax函数代码，与PyTorch原生实现对比，观察输出差异

- 打卡输出：绘制Softmax输出的概率分布示意图（可手绘或用代码生成）

### Day3 实操代码模板（可直接复制运行）

```python
import numpy as np
import torch
import torch.nn.functional as F

# 1. 手写Softmax函数（避免数值溢出，加入数值稳定技巧）
def my_softmax(x):
    exp_x = np.exp(x - np.max(x))  # 数值稳定：减去最大值
    return exp_x / np.sum(exp_x)

# 2. 模拟模型输出分数（3个类别）
logits = np.array([2.0, 1.0, 0.1])

# 3. 手写实现与PyTorch原生实现对比
my_softmax_result = my_softmax(logits)
torch_softmax_result = F.softmax(torch.tensor(logits, dtype=torch.float32), dim=0).numpy()

print("手写Softmax结果：", my_softmax_result)
print("PyTorch Softmax结果：", torch_softmax_result)
print("两者差值（验证一致性）：", np.sum(np.abs(my_softmax_result - torch_softmax_result)))

# 4. 绘制概率分布示意图（可选）
import matplotlib.pyplot as plt
plt.bar([f"类别{i+1}" for i in range(3)], my_softmax_result, color='skyblue')
plt.ylabel('概率')
plt.title('Softmax输出概率分布')
plt.show()

# 5. 简单理解噪声（加入噪声后的Softmax输出）
noise = np.random.normal(0, 0.1, logits.shape)  # 加入微小噪声
logits_with_noise = logits + noise
softmax_with_noise = my_softmax(logits_with_noise)
print("加入噪声后的Softmax结果：", softmax_with_noise)
```

# 二、阶段二：深度学习基本盘（3天，筑牢训练基本功）

## Day4：MLP（多层感知机）实战（函数逼近器）

- 核心知识点：神经网络的本质=万能函数逼近器（用简单网络拟合复杂数据规律）

  ​	简单理解：神经网络（哪怕只有几层）可以模拟任意复杂的数学函数。比如，你给它一堆点（x, y），它能学会一个公式 y = f(x) 去拟合这些点。分类问题就是找到一个函数，把输入特征映射到类别标签。

- 实操任务：用PyTorch搭建2层MLP，对2维玩具数据（如 moons 数据集）做分类

- 对比实验：分别替换ReLU、Sigmoid、Tanh三种激活函数，观察模型收敛速度和最终分类效果

  ​	**ReLU**：f(x)=max(0,x)，计算快，能缓解梯度消失，常用
  ​	**Sigmoid**：f(x)=1/(1+e^{-x})，输出在(0,1)，易导致梯度饱和（两头平）。

  ​	**Tanh**：f(x)=tanh(x)，输出在(-1,1)，对称，但也存在饱和问题

- 必做任务：用matplotlib绘制训练过程中的loss曲线、准确率曲线

  ​	损失曲线下降表示模型预测与真实值的差距在减小。

  ​	准确率曲线上升表示模型分类正确率提高。

  ​	对比不同激活函数，可以直观看到 ReLU 通常收敛更快、效果更好

- 打卡输出：保存完整代码\+3种激活函数的对比效果图

### Day4 实操代码模板（可直接复制运行）

```python
import torch
import torch.nn as nn
import torch.optim as optim
from sklearn.datasets import make_moons
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt

# 1. 生成2维玩具数据（moons数据集）
X, y = make_moons(n_samples=1000, noise=0.1, random_state=42)
X = torch.tensor(X, dtype=torch.float32)
y = torch.tensor(y, dtype=torch.long)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# 2. 定义2层MLP模型（可切换激活函数）
class MLP(nn.Module):
    def __init__(self, activation):
        super(MLP, self).__init__()
        self.fc1 = nn.Linear(2, 10)  # 输入维度2，隐藏层10个神经元
        self.fc2 = nn.Linear(10, 2)  # 输出维度2（2个类别）
        self.activation = activation  # 传入激活函数

    def forward(self, x):
        x = self.activation(self.fc1(x))
        x = self.fc2(x)
        return x

# 3. 定义训练函数
def train_model(activation, epochs=100, lr=0.01):
    model = MLP(activation)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.SGD(model.parameters(), lr=lr)
    
    loss_history = []
    acc_history = []
    
    for epoch in range(epochs):
        # 训练模式
        model.train()
        optimizer.zero_grad()
        outputs = model(X_train)
        loss = criterion(outputs, y_train)
        loss.backward()
        optimizer.step()
        
        # 计算测试准确率
        model.eval()
        with torch.no_grad():
            test_outputs = model(X_test)
            _, predicted = torch.max(test_outputs, 1)
            acc = (predicted == y_test).sum().item() / len(y_test)
        
        loss_history.append(loss.item())
        acc_history.append(acc)
    
    return model, loss_history, acc_history

# 4. 对比三种激活函数
activations = {
    "ReLU": nn.ReLU(),
    "Sigmoid": nn.Sigmoid(),
    "Tanh": nn.Tanh()
}

results = {}
for name, act in activations.items():
    model, loss_hist, acc_hist = train_model(act)
    results[name] = (loss_hist, acc_hist)

# 5. 绘制loss和准确率曲线
plt.figure(figsize=(12, 5))

# 绘制loss曲线
plt.subplot(1, 2, 1)
for name, (loss_hist, _) in results.items():
    plt.plot(loss_hist, label=name)
plt.xlabel('Epoch')
plt.ylabel('Loss')
plt.title('不同激活函数的Loss曲线')
plt.legend()

# 绘制准确率曲线
plt.subplot(1, 2, 2)
for name, (_, acc_hist) in results.items():
    plt.plot(acc_hist, label=name)
plt.xlabel('Epoch')
plt.ylabel('Test Accuracy')
plt.title('不同激活函数的准确率曲线')
plt.legend()

plt.tight_layout()
plt.show()
```

## Day5：前向传播→损失→反向传播全链路

- 核心知识点：训练模型的完整链路——前向传播（算预测结果）→损失函数（算预测与真实值的差距）→反向传播（更新模型参数）

- 实操任务：拆解PyTorch中\`loss\.backward\(\)\`的底层逻辑，打印参数梯度更新过程

- 必懂重点：优化器的作用（简单认识SGD、Adam，知道它们是“帮模型更新参数”的工具）

- 打卡输出：手写整个训练流程的伪代码（清晰标注每一步的核心作用）

### Day5 实操代码模板（可直接复制运行）

```python
import torch
import torch.nn as nn
import torch.optim as optim

# 1. 定义一个极简模型（1层线性回归）
model = nn.Linear(1, 1)  # 输入1维，输出1维
print("初始参数：")
for name, param in model.named_parameters():
    print(f"{name}: {param.data.item()}")

# 2. 模拟数据（y = 3x + 2）
x = torch.tensor([[1.0], [2.0], [3.0], [4.0]], dtype=torch.float32)
y_true = torch.tensor([[5.0], [8.0], [11.0], [14.0]], dtype=torch.float32)

# 3. 定义损失函数和优化器
criterion = nn.MSELoss()  # 均方误差损失
optimizer = optim.SGD(model.parameters(), lr=0.01)  # SGD优化器

# 4. 拆解前向传播→损失→反向传播→参数更新全链路
print("\n全链路拆解：")

# 第一步：前向传播（算预测值）
y_pred = model(x)
print(f"前向传播 - 预测值：\n{y_pred.detach().numpy()}")

# 第二步：计算损失（算差距）
loss = criterion(y_pred, y_true)
print(f"损失值：{loss.item()}")

# 第三步：反向传播（计算梯度）
optimizer.zero_grad()  # 清空之前的梯度
loss.backward()  # 自动计算所有参数的梯度
print("\n反向传播 - 各参数梯度：")
for name, param in model.named_parameters():
    print(f"{name}的梯度：{param.grad.item()}")

# 第四步：参数更新（优化器更新参数）
optimizer.step()
print("\n参数更新后：")
for name, param in model.named_parameters():
    print(f"{name}: {param.data.item()}")

# 5. 对比SGD和Adam优化器（可选）
print("\n对比SGD和Adam优化器的更新效果：")
model_sgd = nn.Linear(1, 1)
model_adam = nn.Linear(1, 1)
optimizer_sgd = optim.SGD(model_sgd.parameters(), lr=0.01)
optimizer_adam = optim.Adam(model_adam.parameters(), lr=0.01)

# 一次更新对比
y_pred_sgd = model_sgd(x)
loss_sgd = criterion(y_pred_sgd, y_true)
optimizer_sgd.zero_grad()
loss_sgd.backward()
optimizer_sgd.step()

y_pred_adam = model_adam(x)
loss_adam = criterion(y_pred_adam, y_true)
optimizer_adam.zero_grad()
loss_adam.backward()
optimizer_adam.step()

print("SGD更新后参数：")
for name, param in model_sgd.named_parameters():
    print(f"{name}: {param.data.item()}")
print("Adam更新后参数：")
for name, param in model_adam.named_parameters():
    print(f"{name}: {param.data.item()}")
```

## Day6：CNN入门（建立空间特征思维）

- 核心知识点：CNN的核心作用——抓取图像的局部纹理、空间特征；池化的作用——降维度、保留关键特征

- 实操任务：用PyTorch搭建极简CNN，跑MNIST手写数字识别任务（不用追求高精度，懂流程即可）

- 必懂重点：图像任务离不开CNN的原因，以及CNN的特征层级（边缘特征→纹理特征→物体特征）

- 打卡输出：用3句话总结CNN的3个核心作用

### Day6 实操代码模板（可直接复制运行）

```python
import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms
from torch.utils.data import DataLoader
import matplotlib.pyplot as plt

# 1. 数据预处理（MNIST手写数字，灰度图，归一化）
transform = transforms.Compose([
    transforms.ToTensor(),  # 转为Tensor，维度为[C, H, W]
    transforms.Normalize((0.1307,), (0.3081,))  # MNIST数据集的均值和标准差
])

# 加载数据
train_dataset = datasets.MNIST('./data', train=True, download=True, transform=transform)
test_dataset = datasets.MNIST('./data', train=False, download=True, transform=transform)
train_loader = DataLoader(train_dataset, batch_size=32, shuffle=True)
test_loader = DataLoader(test_dataset, batch_size=32, shuffle=False)

# 2. 搭建极简CNN模型
class SimpleCNN(nn.Module):
    def __init__(self):
        super(SimpleCNN, self).__init__()
        # 卷积层1：抓取边缘特征（输入1通道，输出16通道，卷积核3x3）
        self.conv1 = nn.Conv2d(1, 16, kernel_size=3, padding=1)
        # 池化层1：降维，保留关键特征
        self.pool = nn.MaxPool2d(2, 2)  # 2x2池化核，步长2
        # 卷积层2：抓取更复杂的纹理特征
        self.conv2 = nn.Conv2d(16, 32, kernel_size=3, padding=1)
        # 全连接层：分类（输入维度32*7*7，输出10个类别）
        self.fc1 = nn.Linear(32 * 7 * 7, 10)

    def forward(self, x):
        # 前向传播：卷积→激活→池化
        x = self.pool(torch.relu(self.conv1(x)))
        x = self.pool(torch.relu(self.conv2(x)))
        # 展平特征图，输入全连接层
        x = x.view(-1, 32 * 7 * 7)
        x = self.fc1(x)
        return x

# 3. 初始化模型、损失函数、优化器
model = SimpleCNN()
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=0.001)

# 4. 简单训练（5个epoch，不用追求高精度）
epochs = 5
train_loss_history = []

for epoch in range(epochs):
    model.train()
    total_loss = 0.0
    for images, labels in train_loader:
        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()
        total_loss += loss.item() * images.size(0)
    
    avg_loss = total_loss / len(train_loader.dataset)
    train_loss_history.append(avg_loss)
    print(f"Epoch {epoch+1}/{epochs}, Loss: {avg_loss:.4f}")

# 5. 测试模型准确率
model.eval()
correct = 0
total = 0
with torch.no_grad():
    for images, labels in test_loader:
        outputs = model(images)
        _, predicted = torch.max(outputs.data, 1)
        total += labels.size(0)
        correct += (predicted == labels).sum().item()

print(f"测试准确率: {100 * correct / total:.2f}%")

# 6. 可视化训练loss曲线
plt.plot(range(1, epochs+1), train_loss_history)
plt.xlabel('Epoch')
plt.ylabel('Training Loss')
plt.title('CNN Training Loss Curve')
plt.show()

# 7. 查看卷积层输出的特征图（可选，理解CNN抓取特征的过程）
model.eval()
with torch.no_grad():
    sample_image, _ = next(iter(test_loader))
    conv1_output = torch.relu(model.conv1(sample_image[0:1]))  # 取第一张图，经过第一个卷积层
    # 可视化第一个卷积层的前4个特征图
    plt.figure(figsize=(8, 2))
    for i in range(4):
        plt.subplot(1, 4, i+1)
        plt.imshow(conv1_output[0, i].numpy(), cmap='gray')
        plt.axis('off')
    plt.title('Conv1 Output Features')
    plt.show()
```

# 三、阶段三：核心模型扫盲（7天，从传统模型到Transformer闭环）

## Day7：CNN深化\+残差连接基础

- 核心知识点：ResNet残差连接的核心原理（重点！Transformer也会用到残差连接）

- 必懂重点：残差连接的作用——解决深层神经网络的梯度消失问题，让模型能训练更深

- 实操任务：查看ResNet残差模块的代码结构，仿写一个极简的残差块（不用跑完整模型）

- 打卡输出：手写残差块的核心代码，标注每一步的作用

### Day7 实操代码模板（可直接复制运行）

```python
import torch
import torch.nn as nn

# 1. 仿写极简残差块（BasicBlock，适用于ResNet18/34）
class BasicBlock(nn.Module):
    def __init__(self, in_channels, out_channels, stride=1):
        super(BasicBlock, self).__init__()
        # 第一个卷积层：3x3卷积，激活函数ReLU
        self.conv1 = nn.Conv2d(in_channels, out_channels, kernel_size=3, stride=stride, padding=1, bias=False)
        self.bn1 = nn.BatchNorm2d(out_channels)  # 批归一化，加速训练
        self.relu = nn.ReLU(inplace=True)
        
        # 第二个卷积层：3x3卷积，不激活（最后统一激活）
        self.conv2 = nn.Conv2d(out_channels, out_channels, kernel_size=3, stride=1, padding=1, bias=False)
        self.bn2 = nn.BatchNorm2d(out_channels)
        
        #  shortcut（残差连接）：当输入输出通道/尺寸不一致时，用1x1卷积调整
        self.shortcut = nn.Sequential()
        if stride != 1 or in_channels != out_channels:
            self.shortcut = nn.Sequential(
                nn.Conv2d(in_channels, out_channels, kernel_size=1, stride=stride, bias=False),
                nn.BatchNorm2d(out_channels)
            )

    def forward(self, x):
        # 主路径：conv1 → bn1 → relu → conv2 → bn2
        residual = x  # 保存输入，作为残差
        out = self.conv1(x)
        out = self.bn1(out)
        out = self.relu(out)
        
        out = self.conv2(out)
        out = self.bn2(out)
        
        # 残差连接：主路径输出 + 残差（shortcut调整后的输入）
        out += self.shortcut(residual)
        out = self.relu(out)  # 最后统一激活
        return out

# 2. 测试残差块的输入输出维度
# 模拟输入：[batch_size=2, channels=3, height=32, width=32]
x = torch.randn(2, 3, 32, 32)
# 定义残差块：输入3通道，输出64通道，步长1
residual_block = BasicBlock(in_channels=3, out_channels=64, stride=1)
output = residual_block(x)

print(f"输入维度：{x.shape}")  # 输出：torch.Size([2, 3, 32, 32])
print(f"输出维度：{output.shape}")  # 输出：torch.Size([2, 64, 32, 32])

# 3. 测试步长为2的情况（下采样，尺寸减半）
residual_block_downsample = BasicBlock(in_channels=64, out_channels=128, stride=2)
output_downsample = residual_block_downsample(output)
print(f"下采样后输出维度：{output_downsample.shape}")  # 输出：torch.Size([2, 128, 16, 16])

# 4. 简单理解残差连接解决梯度消失：查看梯度传播（可选）
x.requires_grad = True
output = residual_block(x)
# 对输出求导，模拟反向传播
output.sum().backward()
# 查看输入x的梯度（若没有残差连接，深层网络此处梯度会接近0）
print(f"输入x的梯度 norm：{x.grad.norm().item()}")  # 梯度不为0，说明梯度传播正常
```

## Day8：RNN/LSTM 时序模型（铺垫Transformer的必要性）

- 核心知识点：RNN的作用——存储时序信息，处理文本、时序等序列数据

- 必懂痛点：RNN/LSTM的局限性——长距离依赖能力差、并行计算效率低

- 核心思考：为什么Transformer能取代RNN/LSTM，成为大模型的核心架构

- 打卡输出：总结RNN的2个核心痛点，以及Transformer的对应优势

### Day8 实操代码模板（可直接复制运行）

```python
import torch
import torch.nn as nn
import matplotlib.pyplot as plt

# 1. 极简RNN实现（理解时序信息存储）
class SimpleRNN(nn.Module):
    def __init__(self, input_size, hidden_size, output_size):
        super(SimpleRNN, self).__init__()
        self.hidden_size = hidden_size
        # RNN层：输入维度input_size，隐藏层维度hidden_size
        self.rnn = nn.RNN(input_size, hidden_size, batch_first=True)
        # 全连接层：输出分类结果
        self.fc = nn.Linear(hidden_size, output_size)

    def forward(self, x):
        # 初始化隐藏状态（batch_size=1，hidden_size=16）
        h0 = torch.zeros(1, x.size(0), self.hidden_size)
        # 前向传播：output是所有时间步的输出，hn是最后一个时间步的隐藏状态
        output, hn = self.rnn(x, h0)
        # 用最后一个时间步的隐藏状态做分类
        out = self.fc(hn.squeeze(0))
        return out, output, hn

# 2. 模拟时序数据（比如：序列长度为5，每个时间步输入维度为3，batch_size=2）
input_size = 3
```

通过上述极简RNN的实操，能直观感受到时序模型的核心逻辑——靠隐藏状态传递时序信息，但也能隐约发现其局限：当序列长度增加时，早期的时序信息会不断衰减，这就是长距离依赖问题。后续我们将学习Transformer，它通过注意力机制打破了RNN的串行计算瓶颈，完美解决这一痛点，为大模型的高效训练和长文本理解奠定基础。

结合Day8的实操和思考，我们已经明确了传统时序模型的短板，这也正是Transformer诞生的核心契机。接下来的几天，我们将逐步拆解Transformer的核心组件，从基础的自注意力机制入手，一步步掌握大模型的底层架构，把之前学到的残差连接、Softmax等知识点融会贯通，实现从传统模型到大模型核心架构的平稳过渡。

## Day9：自注意力机制（Transformer核心）

- 核心知识点：自注意力=序列内部元素两两计算关联度（相似度），让模型关注“重要信息”

- 必懂重点：自注意力三要素Q（查询）、K（键）、V（值），核心公式=Softmax\(\(Q×Kᵀ\)/√dₖ\) × V

- 实操任务：手写极简自注意力代码，不依赖PyTorch原生层，理解每一步计算逻辑

- 打卡输出：标注自注意力计算的3个核心步骤（QK相似度计算、归一化、与V加权）

### Day9 实操代码模板（可直接复制运行）

```python
import torch
import numpy as np

# 1. 手写极简自注意力（无PyTorch原生注意力层，逐步骤实现）
def self_attention(q, k, v, mask=None):
    # q, k, v维度：[batch_size, seq_len, d_model]
    d_k = q.size(-1)  # 每个Q/K/V的维度
    # 步骤1：计算Q和K的相似度（内积），除以√d_k避免数值过大
    scores = torch.matmul(q, k.transpose(-2, -1)) / np.sqrt(d_k)
    # 步骤2：mask（可选），屏蔽不需要关注的位置（如padding）
    if mask is not None:
        scores = scores.masked_fill(mask == 0, -1e9)
    # 步骤3：Softmax归一化，得到注意力权重（每个元素的关联度占比）
    attn_weights = torch.softmax(scores, dim=-1)
    # 步骤4：注意力权重与V加权求和，得到自注意力输出
    output = torch.matmul(attn_weights, v)
    return output, attn_weights

# 2. 模拟输入（batch_size=2，seq_len=5，d_model=64）
batch_size = 2
seq_len = 5
d_model = 64
q = torch.randn(batch_size, seq_len, d_model)
k = torch.randn(batch_size, seq_len, d_model)
v = torch.randn(batch_size, seq_len, d_model)

# 3. 测试自注意力
output, attn_weights = self_attention(q, k, v)

# 打印维度，验证逻辑
print(f"Q/K/V输入维度：{q.shape}")
print(f"自注意力输出维度：{output.shape}")  # 与输入维度一致
print(f"注意力权重维度：{attn_weights.shape}")  # [batch, seq_len, seq_len]，元素间的关联度
print(f"第一个样本的注意力权重矩阵：\n{attn_weights[0].detach().numpy().round(3)}")
# 权重矩阵每行和为1（Softmax归一化效果）
print(f"注意力权重每行和：{attn_weights[0].sum(dim=-1).detach().numpy().round(3)}")
```

## Day10：位置编码（Transformer时序补充）

- 核心知识点：Transformer无天然时序感知，位置编码=给序列元素“加位置标签”，注入时序信息

- 必懂重点：位置编码的实现逻辑（正弦/余弦函数），保证不同位置有唯一编码，且位置差距越大，编码差异越明显

- 实操任务：实现正弦位置编码，可视化不同位置的编码特征，观察时序规律

- 打卡输出：绘制位置编码的热力图，简单说明位置编码的作用

### Day10 实操代码模板（可直接复制运行）

```python
import torch
import numpy as np
import matplotlib.pyplot as plt

# 1. 实现正弦位置编码（Transformer标准实现）
class PositionalEncoding(torch.nn.Module):
    def __init__(self, d_model, max_len=5000):
        super().__init__()
        # 初始化位置编码矩阵：[max_len, d_model]
        pe = torch.zeros(max_len, d_model)
        # 生成位置序列：[max_len, 1]
        position = torch.arange(0, max_len, dtype=torch.float).unsqueeze(1)
        # 计算频率因子，避免数值过大
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * (-np.log(10000.0) / d_model))
        # 偶数维度用正弦，奇数维度用余弦（保证位置唯一性）
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        # 增加batch维度，方便后续拼接：[1, max_len, d_model]
        pe = pe.unsqueeze(0)
        # 注册为缓冲区（不参与训练，固定不变）
        self.register_buffer('pe', pe)

    def forward(self, x):
        # x: [batch_size, seq_len, d_model]，拼接位置编码
        x = x + self.pe[:, :x.size(1), :]
        return x

# 2. 测试位置编码
d_model = 64
max_len = 20  # 最大序列长度
pe = PositionalEncoding(d_model, max_len)
# 模拟输入（batch_size=1，seq_len=10，d_model=64）
x = torch.zeros(1, 10, d_model)
x_with_pe = pe(x)

# 3. 可视化位置编码（热力图）
plt.figure(figsize=(10, 6))
# 取第一个样本的位置编码：[seq_len, d_model]
pe_matrix = x_with_pe[0].detach().numpy()
plt.imshow(pe_matrix, cmap='viridis')
plt.xlabel('模型维度（d_model）')
plt.ylabel('序列位置（seq_len）')
plt.title('位置编码热力图（不同位置的编码特征）')
plt.colorbar()
plt.show()

# 4. 验证：不同位置的编码差异
pos1 = 0  # 第一个位置
pos2 = 5  # 第六个位置
pos3 = 10 # 第十一个位置
diff1 = np.abs(pe_matrix[pos1] - pe_matrix[pos2]).sum()
diff2 = np.abs(pe_matrix[pos1] - pe_matrix[pos3]).sum()
print(f"位置0与位置5的编码差异：{diff1:.2f}")
print(f"位置0与位置10的编码差异：{diff2:.2f}")
# 结论：位置差距越大，编码差异越明显，模型能区分时序
```

## Day11：多头注意力（Transformer核心升级）

- 核心知识点：多头注意力=把单组自注意力拆成多组，并行捕捉不同类型的关联（语义关联、语序关联等）

- 必懂重点：Transformer没有天生的时序感知，必须靠位置编码注入语序；多头注意力能提升特征提取能力，让模型理解更丰富的语义

- 实操任务：手写极简多头注意力代码，结合位置编码，测试输入输出，理解多头拆分与融合逻辑

- 打卡输出：标注多头注意力的拆分、拼接步骤，解释位置编码的作用

### Day11 实操代码模板（可直接复制运行）

```python
import torch
import torch.nn as nn
import numpy as np
import matplotlib.pyplot as plt

# 1. 位置编码（复用Day10，巩固理解）
class PositionalEncoding(nn.Module):
    def __init__(self, d_model, max_len=5000):
        super().__init__()
        pe = torch.zeros(max_len, d_model)
        position = torch.arange(0, max_len, dtype=torch.float).unsqueeze(1)
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * (-np.log(10000.0) / d_model))
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        pe = pe.unsqueeze(0)
        self.register_buffer('pe', pe)

    def forward(self, x):
        # x: [batch_size, seq_len, d_model]
        x = x + self.pe[:, :x.size(1), :]
        return x

# 2. 手写极简多头注意力（核心）
class MultiHeadAttention(nn.Module):
    def __init__(self, d_model, nhead):
        super().__init__()
        self.d_model = d_model  # 模型总维度
        self.nhead = nhead      # 头数
        self.d_k = d_model // nhead  # 每个头的维度，必须整除
        
        # 定义Q、K、V的线性层
        self.w_q = nn.Linear(d_model, d_model)
        self.w_k = nn.Linear(d_model, d_model)
        self.w_v = nn.Linear(d_model, d_model)
        # 输出融合层
        self.w_o = nn.Linear(d_model, d_model)
        
    def forward(self, q, k, v, mask=None):
        batch_size = q.size(0)
        
        # 步骤1：线性变换，得到Q、K、V
        q = self.w_q(q)  # [batch, seq_len, d_model]
        k = self.w_k(k)
        v = self.w_v(v)
        
        # 步骤2：拆分成多头
        # [batch, seq_len, nhead, d_k] → [batch, nhead, seq_len, d_k]
        q = q.view(batch_size, -1, self.nhead, self.d_k).transpose(1, 2)
        k = k.view(batch_size, -1, self.nhead, self.d_k).transpose(1, 2)
        v = v.view(batch_size, -1, self.nhead, self.d_k).transpose(1, 2)
        
        # 步骤3：单头自注意力计算（缩放点积）
        scores = torch.matmul(q, k.transpose(-2, -1)) / np.sqrt(self.d_k)
        if mask is not None:
            scores = scores.masked_fill(mask == 0, -1e9)
        attn_weights = torch.softmax(scores, dim=-1)
        out = torch.matmul(attn_weights, v)
        
        # 步骤4：拼接多头
        out = out.transpose(1, 2).contiguous().view(batch_size, -1, self.d_model)
        # 步骤5：输出线性层
        out = self.w_o(out)
        return out, attn_weights

# 3. 测试代码
if __name__ == '__main__':
    # 参数设置
    d_model = 128   # 模型维度
    nhead = 4       # 4头注意力
    batch_size = 2
    seq_len = 10    # 序列长度
    
    # 模拟输入（词嵌入）
    x = torch.randn(batch_size, seq_len, d_model)
    # 加入位置编码
    pe = PositionalEncoding(d_model)
    x_with_pe = pe(x)
    
    # 初始化多头注意力
    mha = MultiHeadAttention(d_model, nhead)
    # 自注意力：Q=K=V
    out, attn_weights = mha(x_with_pe, x_with_pe, x_with_pe)
    
    # 打印维度，验证流程
    print(f"输入维度：{x.shape}")
    print(f"加入位置编码后维度：{x_with_pe.shape}")
    print(f"多头注意力输出维度：{out.shape}")
    print(f"注意力权重维度：{attn_weights.shape} [batch, nhead, seq_len, seq_len]")
    
    # 可视化第一个头的注意力权重
    plt.figure(figsize=(8, 6))
    plt.imshow(attn_weights[0, 0].detach().numpy(), cmap='viridis')
    plt.title('多头注意力-第一个头权重矩阵')
    plt.colorbar()
    plt.show()
```

## Day12：Transformer Encoder（编码器完整结构）

- 核心知识点：Encoder结构=多头注意力层 \+ 残差连接 \+ LayerNorm \+ FeedForward（前馈网络），多层堆叠形成编码器

- 必懂重点：残差连接\+LayerNorm的作用（稳定训练，避免梯度消失）；FeedForward的作用（对注意力输出做非线性变换，增强模型表达能力）

- 实操任务：搭建1层极简Transformer Encoder，结合前文的多头注意力和位置编码，测试完整流程

- 打卡输出：绘制Encoder的结构示意图（可手绘），标注每个组件的作用

### Day12 实操代码模板（可直接复制运行）

```python
import torch
import torch.nn as nn
import numpy as np

# 1. 复用前文的位置编码和多头注意力
class PositionalEncoding(nn.Module):
    def __init__(self, d_model, max_len=5000):
        super().__init__()
        pe = torch.zeros(max_len, d_model)
        position = torch.arange(0, max_len, dtype=torch.float).unsqueeze(1)
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * (-np.log(10000.0) / d_model))
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        pe = pe.unsqueeze(0)
        self.register_buffer('pe', pe)

    def forward(self, x):
        x = x + self.pe[:, :x.size(1), :]
        return x

class MultiHeadAttention(nn.Module):
    def __init__(self, d_model, nhead):
        super().__init__()
        self.d_model = d_model
        self.nhead = nhead
        self.d_k = d_model // nhead
        self.w_q = nn.Linear(d_model, d_model)
        self.w_k = nn.Linear(d_model, d_model)
        self.w_v = nn.Linear(d_model, d_model)
        self.w_o = nn.Linear(d_model, d_model)
        
    def forward(self, q, k, v, mask=None):
        batch_size = q.size(0)
        q = self.w_q(q).view(batch_size, -1, self.nhead, self.d_k).transpose(1, 2)
        k = self.w_k(k).view(batch_size, -1, self.nhead, self.d_k).transpose(1, 2)
        v = self.w_v(v).view(batch_size, -1, self.nhead, self.d_k).transpose(1, 2)
        
        scores = torch.matmul(q, k.transpose(-2, -1)) / np.sqrt(self.d_k)
        if mask is not None:
            scores = scores.masked_fill(mask == 0, -1e9)
        attn_weights = torch.softmax(scores, dim=-1)
        out = torch.matmul(attn_weights, v)
        
        out = out.transpose(1, 2).contiguous().view(batch_size, -1, self.d_model)
        return self.w_o(out), attn_weights

# 2. 定义FeedForward前馈网络（Encoder核心组件）
class FeedForward(nn.Module):
    def __init__(self, d_model, hidden_dim=2048):
        super().__init__()
        # 两层线性变换 + ReLU激活，核心是非线性变换
        self.fc1 = nn.Linear(d_model, hidden_dim)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(hidden_dim, d_model)
        
    def forward(self, x):
        return self.fc2(self.relu(self.fc1(x)))

# 3. 定义1层Transformer Encoder
class TransformerEncoderLayer(nn.Module):
    def __init__(self, d_model, nhead):
        super().__init__()
        # 组件1：多头注意力层
        self.self_attn = MultiHeadAttention(d_model, nhead)
        # 组件2：残差连接 + LayerNorm（注意力层后）
        self.norm1 = nn.LayerNorm(d_model)
        # 组件3：前馈网络
        self.feed_forward = FeedForward(d_model)
        # 组件4：残差连接 + LayerNorm（前馈网络后）
        self.norm2 = nn.LayerNorm(d_model)
        
    def forward(self, x, mask=None):
        # 流程：输入 → 多头注意力 → 残差+归一化 → 前馈网络 → 残差+归一化
        attn_output, _ = self.self_attn(x, x, x, mask)
        x = self.norm1(x + attn_output)  # 残差连接：输入 + 注意力输出
        ff_output = self.feed_forward(x)
        x = self.norm2(x + ff_output)    # 残差连接：上一步输出 + 前馈输出
        return x

# 4. 测试Encoder
if __name__ == '__main__':
    d_model = 128
    nhead = 4
    batch_size = 2
    seq_len = 10
    
    # 模拟词嵌入输入
    x = torch.randn(batch_size, seq_len, d_model)
    # 加入位置编码
    pe = PositionalEncoding(d_model)
    x_with_pe = pe(x)
    
    # 初始化1层Encoder
    encoder_layer = TransformerEncoderLayer(d_model, nhead)
    encoder_output = encoder_layer(x_with_pe)
    
    # 验证维度（输入输出维度一致）
    print(f"输入维度（带位置编码）：{x_with_pe.shape}")
    print(f"Encoder输出维度：{encoder_output.shape}")
    # 验证LayerNorm效果（均值接近0，方差接近1）
    print(f"Encoder输出均值：{encoder_output.mean().item():.4f}")
    print(f"Encoder输出方差：{encoder_output.var().item():.4f}")
```

## Day13：Transformer Decoder（解码器完整结构）

- 核心知识点：Decoder结构=掩码多头注意力（Masked Multi\-Head Attention）\+ 编码器\-解码器注意力 \+ 残差连接 \+ LayerNorm \+ FeedForward

- 必懂重点：掩码注意力的作用（防止模型“偷看”未来的序列元素，保证时序合理性）；编码器\-解码器注意力（让解码器关注编码器的关键特征）

- 实操任务：搭建1层极简Transformer Decoder，结合Encoder输出，测试编码\-解码流程

- 打卡输出：对比Encoder和Decoder的结构差异，说明掩码注意力的核心作用

### Day13 实操代码模板（可直接复制运行）

```python
import torch
import torch.nn as nn
import numpy as np

# 1. 复用前文核心组件（位置编码、多头注意力、前馈网络）
class PositionalEncoding(nn.Module):
    def __init__(self, d_model, max_len=5000):
        super().__init__()
        pe = torch.zeros(max_len, d_model)
        position = torch.arange(0, max_len, dtype=torch.float).unsqueeze(1)
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * (-np.log(10000.0) / d_model))
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        pe = pe.unsqueeze(0)
        self.register_buffer('pe', pe)

    def forward(self, x):
        x = x + self.pe[:, :x.size(1), :]
        return x

class MultiHeadAttention(nn.Module):
    def __init__(self, d_model, nhead):
        super().__init__()
        self.d_model = d_model
        self.nhead = nhead
        self.d_k = d_model // nhead
        self.w_q = nn.Linear(d_model, d_model)
        self.w_k = nn.Linear(d_model, d_model)
        self.w_v = nn.Linear(d_model, d_model)
        self.w_o = nn.Linear(d_model, d_model)
        
    def forward(self, q, k, v, mask=None):
        batch_size = q.size(0)
        q = self.w_q(q).view(batch_size, -1, self.nhead, self.d_k).transpose(1, 2)
        k = self.w_k(k).view(batch_size, -1, self.nhead, self.d_k).transpose(1, 2)
        v = self.w_v(v).view(batch_size, -1, self.nhead, self.d_k).transpose(1, 2)
        
        scores = torch.matmul(q, k.transpose(-2, -1)) / np.sqrt(self.d_k)
        if mask is not None:
            scores = scores.masked_fill(mask == 0, -1e9)
        attn_weights = torch.softmax(scores, dim=-1)
        out = torch.matmul(attn_weights, v)
        
        out = out.transpose(1, 2).contiguous().view(batch_size, -1, self.d_model)
        return self.w_o(out), attn_weights

class FeedForward(nn.Module):
    def __init__(self, d_model, hidden_dim=2048):
        super().__init__()
        self.fc1 = nn.Linear(d_model, hidden_dim)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(hidden_dim, d_model)
        
    def forward(self, x):
        return self.fc2(self.relu(self.fc1(x)))

# 2. 定义1层Transformer Decoder
class TransformerDecoderLayer(nn.Module):
    def __init__(self, d_model, nhead):
        super().__init__()
        # 组件1：掩码多头注意力（防止偷看未来序列）
        self.masked_self_attn = MultiHeadAttention(d_model, nhead)
        # 组件2：残差+LayerNorm（掩码注意力后）
        self.norm1 = nn.LayerNorm(d_model)
        # 组件3：编码器-解码器注意力（关注Encoder输出）
        self.enc_dec_attn = MultiHeadAttention(d_model, nhead)
        # 组件4：残差+LayerNorm（编码-解码注意力后）
        self.norm2 = nn.LayerNorm(d_model)
        # 组件5：前馈网络
        self.feed_forward = FeedForward(d_model)
        # 组件6：残差+LayerNorm（前馈网络后）
        self.norm3 = nn.LayerNorm(d_model)
        
    def forward(self, tgt, memory, tgt_mask=None, memory_mask=None):
        # tgt：解码器输入，memory：编码器输出
        # 流程1：掩码自注意力 → 残差+归一化
        attn1, _ = self.masked_self_attn(tgt, tgt, tgt, tgt_mask)
        tgt = self.norm1(tgt + attn1)
        # 流程2：编码-解码注意力 → 残差+归一化
        attn2, _ = self.enc_dec_attn(tgt, memory, memory, memory_mask)
        tgt = self.norm2(tgt + attn2)
        # 流程3：前馈网络 → 残差+归一化
        ff_output = self.feed_forward(tgt)
        tgt = self.norm3(tgt + ff_output)
        return tgt

# 3. 测试编码-解码流程
if __name__ == '__main__':
    d_model = 128
    nhead = 4
    batch_size = 2
    src_seq_len = 10  # 编码器输入序列长度
    tgt_seq_len = 8   # 解码器输入序列长度
    
    # 1. 模拟编码器输入+位置编码
    src = torch.randn(batch_size, src_seq_len, d_model)
    pe = PositionalEncoding(d_model)
    src_with_pe = pe(src)
    
    # 2. 初始化编码器（1层），得到编码器输出（memory）
    encoder_layer = nn.TransformerEncoderLayer(d_model=d_model, nhead=nhead)
    memory = encoder_layer(src_with_pe)
    
    # 3. 模拟解码器输入+位置编码
    tgt = torch.randn(batch_size, tgt_seq_len, d_model)
    tgt_with_pe = pe(tgt)
    
    # 4. 生成掩码（防止偷看未来序列）
    tgt_mask = nn.Transformer.generate_square_subsequent_mask(tgt_seq_len)
    
    # 5. 初始化解码器（1层），测试解码流程
    decoder_layer = TransformerDecoderLayer(d_model, nhead)
    decoder_output = decoder_layer(tgt_with_pe, memory, tgt_mask)
    
    # 验证维度
    print(f"编码器输出（memory）维度：{memory.shape}")
    print(f"解码器输入维度：{tgt_with_pe.shape}")
    print(f"解码器输出维度：{decoder_output.shape}")
    # 查看掩码效果（下三角为1，上三角为0，防止偷看未来）
    print(f"解码器掩码矩阵：\n{tgt_mask}")
```

## Day14：完整Transformer模型搭建（Encoder\+Decoder）

- 核心知识点：完整Transformer=嵌入层（Embedding）\+ 位置编码 \+ 多层Encoder堆叠 \+ 多层Decoder堆叠 \+ 输出层（Linear\+Softmax）

- 必懂重点：嵌入层的作用（将离散的token转换为连续的向量）；输出层的作用（将Decoder输出转换为类别概率，用于预测）

- 实操任务：搭建完整的极简Transformer模型，模拟文本翻译场景（不用训练，重点理解完整流程）

- 打卡输出：梳理完整Transformer的前向传播流程，标注每个组件的先后顺序

### Day14 实操代码模板（可直接复制运行）

```python
import torch
import torch.nn as nn
import numpy as np

# 1. 复用前文核心组件
class PositionalEncoding(nn.Module):
    def __init__(self, d_model, max_len=5000):
        super().__init__()
        pe = torch.zeros(max_len, d_model)
        position = torch.arange(0, max_len, dtype=torch.float).unsqueeze(1)
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * (-np.log(10000.0) / d_model))
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        pe = pe.unsqueeze(0)
        self.register_buffer('pe', pe)

    def forward(self, x):
        x = x + self.pe[:, :x.size(1), :]
        return x

class MultiHeadAttention(nn.Module):
    def __init__(self, d_model, nhead):
        super().__init__()
        self.d_model = d_model
        self.nhead = nhead
        self.d_k = d_model // nhead
        self.w_q = nn.Linear(d_model, d_model)
        self.w_k = nn.Linear(d_model, d_model)
        self.w_v = nn.Linear(d_model, d_model)
        self.w_o = nn.Linear(d_model, d_model)
        
    def forward(self, q, k, v, mask=None):
        batch_size = q.size(0)
        q = self.w_q(q).view(batch_size, -1, self.nhead, self.d_k).transpose(1, 2)
        k = self.w_k(k).view(batch_size, -1, self.nhead, self.d_k).transpose(1, 2)
        v = self.w_v(v).view(batch_size, -1, self.nhead, self.d_k).transpose(1, 2)
        
        scores = torch.matmul(q, k.transpose(-2, -1)) / np.sqrt(self.d_k)
        if mask is not None:
            scores = scores.masked_fill(mask == 0, -1e9)
        attn_weights = torch.softmax(scores, dim=-1)
        out = torch.matmul(attn_weights, v)
        
        out = out.transpose(1, 2).contiguous().view(batch_size, -1, self.d_model)
        return self.w_o(out), attn_weights

class FeedForward(nn.Module):
    def __init__(self, d_model, hidden_dim=2048):
        super().__init__()
        self.fc1 = nn.Linear(d_model, hidden_dim)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(hidden_dim, d_model)
        
    def forward(self, x):
        return self.fc2(self.relu(self.fc1(x)))

# 2. 定义Encoder层和Decoder层
class TransformerEncoderLayer(nn.Module):
    def __init__(self, d_model, nhead):
        super().__init__()
        self.self_attn = MultiHeadAttention(d_model, nhead)
        self.norm1 = nn.LayerNorm(d_model)
        self.feed_forward = FeedForward(d_model)
        self.norm2 = nn.LayerNorm(d_model)
        
    def forward(self, x, mask=None):
        attn_output, _ = self.self_attn(x, x, x, mask)
        x = self.norm1(x + attn_output)
        ff_output = self.feed_forward(x)
        x = self.norm2(x + ff_output)
        return x

class TransformerDecoderLayer(nn.Module):
    def __init__(self, d_model, nhead):
        super().__init__()
        self.masked_self_attn = MultiHeadAttention(d_model, nhead)
        self.norm1 = nn.LayerNorm(d_model)
        self.enc_dec_attn = MultiHeadAttention(d_model, nhead)
        self.norm2 = nn.LayerNorm(d_model)
        self.feed_forward = FeedForward(d_model)
        self.norm3 = nn.LayerNorm(d_model)
        
    def forward(self, tgt, memory, tgt_mask=None, memory_mask=None):
        attn1, _ = self.masked_self_attn(tgt, tgt, tgt, tgt_mask)
        tgt = self.norm1(tgt + attn1)
        attn2, _ = self.enc_dec_attn(tgt, memory, memory, memory_mask)
        tgt = self.norm2(tgt + attn2)
        ff_output = self.feed_forward(tgt)
        tgt = self.norm3(tgt + ff_output)
        return tgt

# 3. 搭建完整Transformer模型
class Transformer(nn.Module):
    def __init__(self, d_model=128, nhead=4, num_encoder_layers=2, num_decoder_layers=2, vocab_size=1000):
        super().__init__()
        # 嵌入层：将token转换为向量（vocab_size=词典大小）
        self.embedding = nn.Embedding(vocab_size, d_model)
        # 位置编码
        self.pos_encoding = PositionalEncoding(d_model)
        # 编码器堆叠（num_encoder_layers层）
        self.encoder = nn.TransformerEncoder(
            encoder_layer=TransformerEncoderLayer(d_model, nhead),
            num_layers=num_encoder_layers
        )
        # 解码器堆叠（num_decoder_layers层）
        self.decoder = nn.TransformerDecoder(
            decoder_layer=TransformerDecoderLayer(d_model, nhead),
            num_layers=num_decoder_layers
        )
        # 输出层：将Decoder输出转换为词典中每个token的概率
        self.fc_out = nn.Linear(d_model, vocab_size)
        self.softmax = nn.Softmax(dim=-1)
        
    def forward(self, src, tgt):
        # src：编码器输入 [batch_size, src_seq_len]（token索引）
        # tgt：解码器输入 [batch_size, tgt_seq_len]（token索引）
        batch_size = src.size(0)
        src_seq_len = src.size(1)
        tgt_seq_len = tgt.size(1)
        
        # 1. 嵌入层 + 位置编码
        src_emb = self.embedding(src)  # [batch, src_seq_len, d_model]
        tgt_emb = self.embedding(tgt)  # [batch, tgt_seq_len, d_model]
        src_emb = self.pos_encoding(src_emb)
        tgt_emb = self.pos_encoding(tgt_emb)
        
        # 2. 生成掩码（可选，简化版可省略）
        tgt_mask = nn.Transformer.generate_square_subsequent_mask(tgt_seq_len)
        
        # 3. 编码器前向传播
        memory = self.encoder(src_emb, mask=None)
        
        # 4. 解码器前向传播
        decoder_output = self.decoder(tgt_emb, memory, tgt_mask=tgt_mask)
        
        # 5. 输出层：预测token概率
        output = self.fc_out(decoder_output)
        output = self.softmax(output)
        
        return output

# 4. 测试完整Transformer
if __name__ == '__main__':
    # 参数设置
    d_model = 128
    nhead = 4
    vocab_size = 1000
    batch_size = 2
    src_seq_len = 10
    tgt_seq_len = 8
    
    # 模拟输入（token索引，范围0~vocab_size-1）
    src = torch.randint(0, vocab_size, (batch_size, src_seq_len))
    tgt = torch.randint(0, vocab_size, (batch_size, tgt_seq_len))
    
    # 初始化模型
    transformer = Transformer(d_model, nhead, vocab_size=vocab_size)
    # 前向传播
    output = transformer(src, tgt)
    
    # 验证维度
    print(f"编码器输入（token索引）维度：{src.shape}")
    print(f"解码器输入（token索引）维度：{tgt.shape}")
    print(f"模型输出（token概率）维度：{output.shape}")  # [batch, tgt_seq_len, vocab_size]
    # 验证输出概率和为1（Softmax效果）
    print(f"第一个token的概率和：{output[0, 0].sum().item():.4f}")
```

## Day15：大模型训练基础（预训练\+微调流程）

- 核心知识点：大模型训练两阶段=预训练（Pre\-training）\+ 微调（Fine\-tuning）；预训练学通用知识，微调适配具体任务

- 必懂重点：预训练任务（如掩码语言模型MLM）、微调的核心逻辑（冻结部分参数，只训练顶层，节省算力）

- 实操任务：用PyTorch模拟大模型微调流程，冻结底层参数，只训练输出层和顶层注意力层

- 打卡输出：总结预训练和微调的核心区别，以及微调的关键技巧（如参数冻结）

### Day15 实操代码模板（可直接复制运行）

```python
import torch
import torch.nn as nn
import torch.optim as optim

# 1. 复用前文完整Transformer模型（简化版，用于模拟微调）
class PositionalEncoding(nn.Module):
    def __init__(self, d_model, max_len=5000):
        super().__init__()
        pe = torch.zeros(max_len, d_model)
        position = torch.arange(0, max_len, dtype=torch.float).unsqueeze(1)
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * (-np.log(10000.0) / d_model))
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        pe = pe.unsqueeze(0)
        self.register_buffer('pe', pe)

    def forward(self, x):
        x = x + self.pe[:, :x.size(1), :]
        return x

class Transformer(nn.Module):
    def __init__(self, d_model=128, nhead=4, num_encoder_layers=2, num_decoder_layers=2, vocab_size=1000):
        super().__init__()
        self.embedding = nn.Embedding(vocab_size, d_model)
        self.pos_encoding = PositionalEncoding(d_model)
        self.encoder = nn.TransformerEncoder(
            encoder_layer=nn.TransformerEncoderLayer(d_model, nhead),
            num_layers=num_encoder_layers
        )
        self.decoder = nn.TransformerDecoder(
            decoder_layer=nn.TransformerDecoderLayer(d_model, nhead),
            num_layers=num_decoder_layers
        )
        self.fc_out = nn.Linear(d_model, vocab_size)
        self.softmax = nn.Softmax(dim=-1)
        
    def forward(self, src, tgt):
        src_emb = self.embedding(src)
        tgt_emb = self.embedding(tgt)
        src_emb = self.pos_encoding(src_emb)
        tgt_emb = self.pos_encoding(tgt_emb)
        tgt_mask = nn.Transformer.generate_square_subsequent_mask(tgt.size(1))
        memory = self.encoder(src_emb)
        decoder_output = self.decoder(tgt_emb, memory, tgt_mask=tgt_mask)
        return self.softmax(self.fc_out(decoder_output))

# 2. 模拟大模型微调流程（核心：参数冻结）
if __name__ == '__main__':
    # 1. 初始化模型（模拟“预训练好的大模型”）
    model = Transformer(d_model=128, nhead=4, vocab_size=1000)
    print("模型初始化完成（模拟预训练模型）")
    
    # 2. 参数冻结：冻结底层（嵌入层、编码器底层、解码器底层），只训练顶层
    # 冻结嵌入层
    for param in model.embedding.parameters():
        param.requires_grad = False
    # 冻结编码器前1层（共2层，只训练最后1层）
    for layer in model.encoder.layers[:-1]:
        for param in layer.parameters():
            param.requires_grad = False
    # 冻结解码器前1层（共2层，只训练最后1层）
    for layer in model.decoder.layers[:-1]:
        for param in layer.parameters():
            param.requires_grad = False
    # 输出层和顶层注意力层不冻结（重点训练）
    
    # 3. 查看可训练参数（验证冻结效果）
    trainable_params = [param for param in model.parameters() if param.requires_grad]
    print(f"\n可训练参数数量：{len(trainable_params)}")
    print("可训练参数列表：")
    for param in trainable_params:
        print(f"- {param.shape}")
    
    # 4. 模拟微调数据（简单文本翻译场景，token索引）
    batch_size = 2
    src_seq_len = 10
    tgt_seq_len = 8
    vocab_size = 1000
    src = torch.randint(0, vocab_size, (batch_size, src_seq_len))
    tgt = torch.randint(0, vocab_size, (batch_size, tgt_seq_len))
    # 目标标签（与解码器输入错开一位，模拟预测下一个token）
    tgt_label = torch.roll(tgt, shifts=-1, dims=1)
    tgt_label[:, -1] = 0  # 最后一位补0（padding）
    
    # 5. 定义损失函数和优化器（只优化可训练参数）
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(trainable_params, lr=1e-4)  # 微调学习率要小
    
    # 6. 模拟微调训练（10个epoch，不用追求收敛）
    epochs = 10
    for epoch in range(epochs):
        model.train()
        optimizer.zero_grad()
        output = model(src, tgt)
        # 调整维度，适配CrossEntropyLoss（[batch*seq_len, vocab_size] vs [batch*seq_len]）
        loss = criterion(output.reshape(-1, vocab_size), tgt_label.reshape(-1))
        loss.backward()
        optimizer.step()
        
        if (epoch + 1) % 2 == 0:
            print(f"Epoch {epoch+1}/{epochs}, Loss: {loss.item():.4f}")
    
    print("\n微调模拟完成！核心：冻结底层参数，只训练顶层，节省算力且避免过拟合")
```

## Day16：大模型推理优化（基础技巧）

- 核心知识点：大模型推理的核心痛点=速度慢、显存占用高；基础优化技巧=批量推理、量化、注意力优化

- 必懂重点：量化的作用（将FP32精度转为FP16/INT8，减少显存占用，提升推理速度）；批量推理的原理（并行计算，提高GPU利用率）

- 实操任务：用PyTorch实现模型量化（FP32→FP16），对比量化前后的推理速度和显存占用

- 打卡输出：记录量化前后的速度、显存差异，总结量化的优缺点

### Day16 实操代码模板（可直接复制运行）

```python
import torch
import torch.nn as nn
import time

# 1. 复用简化版Transformer模型（用于推理优化测试）
class Transformer(nn.Module):
    def __init__(self, d_model=128, nhead=4, num_encoder_layers=2, num_decoder_layers=2, vocab_size=1000):
        super().__init__()
        self.embedding = nn.Embedding(vocab_size, d_model)
        self.pos_encoding = nn.Embedding(5000, d_model)  # 简化位置编码
        self.encoder = nn.TransformerEncoder(
            encoder_layer=nn.TransformerEncoderLayer(d_model, nhead),
            num_layers=num_encoder_layers
        )
        self.decoder = nn.TransformerDecoder(
            decoder_layer=nn.TransformerDecoderLayer(d_model, nhead),
            num_layers=num_decoder_layers
        )
        self.fc_out = nn.Linear(d_model, vocab_size)
        self.softmax = nn.Softmax(dim=-1)
        
    def forward(self, src, tgt):
        # 简化位置编码（用嵌入层替代，方便测试）
        src_pos = torch.arange(src.size(1), device=src.device).repeat(src.size(0), 1)
        tgt_pos = torch.arange(tgt.size(1), device=tgt.device).repeat(tgt.size(0), 1)
        src_emb = self.embedding(src) + self.pos_encoding(src_pos)
        tgt_emb = self.embedding(tgt) + self.pos_encoding(tgt_pos)
        
        tgt_mask = nn.Transformer.generate_square_subsequent_mask(tgt.size(1), device=tgt.device)
        memory = self.encoder(src_emb)
        decoder_output = self.decoder(tgt_emb, memory, tgt_mask=tgt_mask)
        return self.softmax(self.fc_out(decoder_output))

# 2. 测试推理优化：FP32 vs FP16量化
if __name__ == '__main__':
    # 设备设置（优先用GPU，没有则用CPU）
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"使用设备：{device}")
    
    # 模型和输入参数
    model = Transformer(d_model=128, nhead=4, vocab_size=1000).to(device)
    batch_size = 8
    src_seq_len = 20
    tgt_seq_len = 15
    vocab_size = 1000
    src = torch.randint(0, vocab_size, (batch_size, src_seq_len)).to(device)
    tgt = torch.randint(0, vocab_size, (batch_size, tgt_seq_len)).to(device)
    
    # 3. FP32精度推理（原始精度）
    model.eval()
    with torch.no_grad():
        # 预热（避免第一次推理速度不准）
        for _ in range(10):
            model(src, tgt)
        # 测试推理速度
        start_time = time.time()
        for _ in range(100):
            output_fp32 = model(src, tgt)
        end_time = time.time()
        fp32_time = (end_time - start_time) / 100  # 平均每轮推理时间
        # 计算显存占用（GPU专属）
        if device.type == 'cuda':
            fp32_memory = torch.cuda.memory_allocated() / (1024 ** 2)  # 转为MB
        else:
            fp32_memory = 0
    
    # 4. FP16量化推理（优化精度）
    model_fp16 = model.half()  # 模型转为FP16
    src_fp16 = src.half()
    tgt_fp16 = tgt.half()
    with torch.no_grad():
        # 预热
        for _ in range(10):
            model_fp16(src_fp16, tgt_fp16)
        # 测试推理速度
        start_time = time.time()
        for _ in range(100):
            output_fp16 = model_fp16(src_fp16, tgt_fp16)
        end_time = time.time()
        fp16_time = (end_time - start_time) / 100
        # 计算显存占用
        if device.type == 'cuda':
            fp16_memory = torch.cuda.memory_allocated() / (1024 ** 2)
        else:
            fp16_memory = 0
    
    # 5. 对比结果
    print("\n推理速度对比：")
    print(f"FP32精度：平均每轮 {fp32_time:.4f} 秒")
    print(f"FP16精度：平均每轮 {fp16_time:.4f} 秒")
    print(f"速度提升：{(fp32_time - fp16_time) / fp32_time * 100:.2f}%")
    
    if device.type == 'cuda':
        print("\n显存占用对比：")
        print(f"FP32精度：{fp32_memory:.2f} MB")
        print(f"FP16精度：{fp16_memory:.2f} MB")
        print(f"显存节省：{(fp32_memory - fp16_memory) / fp32_memory * 100:.2f}%")
    
    # 6. 验证量化前后输出差异（确保精度损失可接受）
    output_fp32_argmax = torch.argmax(output_fp32, dim=-1)
    output_fp16_argmax = torch.argmax(output_fp16.float(), dim=-1)
    accuracy = (output_fp32_argmax == output_fp16_argmax).sum().item() / (batch_size * tgt_seq_len)
    print(f"\n量化前后输出一致性：{accuracy:.4f}")
    print("结论：FP16量化可大幅提升速度、节省显存，精度损失较小，适合推理场景")
```

## Day17：大模型框架实操（Hugging Face Transformers）

- 核心知识点：Hugging Face Transformers框架=大模型开发神器，提供预训练模型、tokenizer、训练/推理API，开箱即用

- 必懂重点：Tokenizer的作用（文本→token→token索引）；Pipeline的作用（简化推理流程，一行代码实现文本生成、分类等任务）

实操任务：安装Hugging Face Transformers库，使用Tokenizer处理文本、通过Pipeline实现简单文本生成，调用预训练模型（如DistilBERT、GPT\-2）完成基础任务，快速上手框架核心用法。打卡输出：完整代码\+运行结果截图，标注Tokenizer和Pipeline的核心作用，理解框架如何简化大模型开发流程。

### Day17 实操代码模板（可直接复制运行）

```python
# 1. 安装依赖库（首次运行需执行）
# pip install transformers torch datasets

import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification, pipeline, AutoModelForCausalLM

# 2. Tokenizer实操：文本转token，核心步骤演示
# 选择预训练模型（DistilBERT，轻量高效，适合入门）
model_name = "distilbert-base-uncased"
tokenizer = AutoTokenizer.from_pretrained(model_name)

# 测试文本
text = "Hugging Face Transformers框架让大模型开发变得简单"

# Tokenizer核心操作：编码（文本→token索引）、解码（token索引→文本）
encoded_text = tokenizer(text, return_tensors="pt", padding=True, truncation=True)
print("编码结果（token索引）：")
print(encoded_text)
print("解码结果（token索引→文本）：")
print(tokenizer.decode(encoded_text["input_ids"][0]))

# 3. Pipeline实操：一行代码实现文本分类（情感分析）
classifier = pipeline("sentiment-analysis", model=model_name)
sentiment_result = classifier(text)
print("\n文本分类（情感分析）结果：")
print(sentiment_result)

# 4. 文本生成实操（使用GPT-2轻量版）
generator_model = "distilgpt2"
generator_tokenizer = AutoTokenizer.from_pretrained(generator_model)
generator = pipeline("text-generation", model=generator_model, tokenizer=generator_tokenizer)

# 生成文本（控制长度，避免冗余）
generated_text = generator(
    "大模型开发的核心步骤是",
    max_length=50,
    num_return_sequences=1,
    pad_token_id=generator_tokenizer.eos_token_id
)
print("\n文本生成结果：")
print(generated_text[0]["generated_text"])

# 5. 调用预训练模型完成简单任务（文本嵌入）
model = AutoModelForSequenceClassification.from_pretrained(model_name)
with torch.no_grad():
    outputs = model(**encoded_text)
    logits = outputs.logits
    print("\n模型输出logits（未归一化概率）：")
    print(logits)
```

Day17核心总结：Hugging Face Transformers的核心价值的是“复用”——复用预训练模型、复用成熟工具（Tokenizer、Pipeline），无需从零搭建模型，大幅降低大模型开发门槛。打卡时重点标注Tokenizer的“编码\-解码”核心逻辑，以及Pipeline如何简化推理流程。

## Day18：大模型工程化基础（部署入门）

- 核心知识点：大模型部署的核心流程=模型导出→服务封装→接口调用；入门级部署方式=FastAPI封装模型，提供HTTP接口

- 必懂重点：模型导出的作用（将训练好的模型转为可部署格式，如TorchScript）；接口封装的意义（让模型能被外部系统调用）

- 实操任务：用FastAPI封装Day17的预训练模型，实现文本分类、文本生成的HTTP接口，测试接口调用效果

- 打卡输出：完整代码（FastAPI服务\+接口调用）\+ 接口测试截图，理解大模型从开发到部署的极简流程

### Day18 实操代码模板（可直接复制运行）

```python
# 1. 安装依赖库（首次运行需执行）
# pip install transformers torch fastapi uvicorn requests

# 代码分为两部分：FastAPI服务端 + 接口调用客户端

# ---------------------- 服务端代码（保存为model_server.py）----------------------
from fastapi import FastAPI
from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForSequenceClassification, pipeline, AutoModelForCausalLM

# 初始化FastAPI应用
app = FastAPI(title="大模型部署入门 - Hugging Face模型接口")

# 定义请求体格式（文本输入）
class TextInput(BaseModel):
    text: str
    max_length: int = 50  # 文本生成时的最大长度，可选参数

# 加载预训练模型和Tokenizer（启动服务时加载，避免重复加载）
# 文本分类模型
classifier_tokenizer = AutoTokenizer.from_pretrained("distilbert-base-uncased")
classifier_model = AutoModelForSequenceClassification.from_pretrained("distilbert-base-uncased")
classifier = pipeline("sentiment-analysis", model=classifier_model, tokenizer=classifier_tokenizer)

# 文本生成模型
generator_tokenizer = AutoTokenizer.from_pretrained("distilgpt2")
generator_model = AutoModelForCausalLM.from_pretrained("distilgpt2")
generator = pipeline("text-generation", model=generator_model, tokenizer=generator_tokenizer)

# 接口1：文本分类（情感分析）
@app.post("/classify")
def text_classify(input: TextInput):
    result = classifier(input.text)
    return {"status": "success", "result": result}

# 接口2：文本生成
@app.post("/generate")
def text_generate(input: TextInput):
    result = generator(
        input.text,
        max_length=input.max_length,
        num_return_sequences=1,
        pad_token_id=generator_tokenizer.eos_token_id
    )
    return {"status": "success", "result": result[0]["generated_text"]}

# 启动服务（终端执行：uvicorn model_server:app --host 0.0.0.0 --port 8000）
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

# ---------------------- 客户端代码（测试接口，保存为client.py）----------------------
import requests

# 服务端地址
base_url = "http://127.0.0.1:8000"

# 测试文本分类接口
classify_data = {"text": "I love using Hugging Face and FastAPI to deploy models!"}
classify_response = requests.post(f"{base_url}/classify", json=classify_data)
print("文本分类接口响应：")
print(classify_response.json())

# 测试文本生成接口
generate_data = {"text": "大模型部署的关键步骤是", "max_length": 60}
generate_response = requests.post(f"{base_url}/generate", json=generate_data)
print("\n文本生成接口响应：")
print(generate_response.json())
```

Day18核心总结：大模型部署的入门关键是“接口化”——将模型封装为HTTP接口，让外部系统（如前端、其他服务）能通过请求调用模型。打卡时需完成服务启动、接口测试，重点理解“模型加载→请求接收→模型推理→响应返回”的完整流程。

## Day19：19天学习复盘\+实战综合任务

- 核心知识点：复盘19天核心内容，串联数学基础→深度学习→Transformer→大模型训练/推理/部署的完整链路

- 必懂重点：大模型学习的核心逻辑=“底层原理\+实操落地”，拒绝死记硬背，重点掌握“参数作用、流程逻辑、问题排查”

- 综合实操任务：整合19天所学，完成一个完整小项目——用Hugging Face加载预训练模型，实现“文本分类\+文本生成”一体化功能，封装为简单接口，完成端到端落地

- 打卡输出：完整项目代码（含模型调用、接口封装）\+ 运行/测试截图 \+ 19天学习复盘笔记（总结核心收获、遇到的问题及解决方法）

### Day19 综合实战代码模板（可直接复制运行）

```python
# 19天综合实战：大模型端到端落地（文本分类+文本生成+接口封装）
# 整合Day17（Hugging Face）和Day18（FastAPI部署）知识点

# 安装依赖库（首次运行需执行）
# pip install transformers torch fastapi uvicorn requests

from fastapi import FastAPI
from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForSequenceClassification, AutoModelForCausalLM, pipeline
import torch

# 初始化FastAPI应用
app = FastAPI(title="19天大模型学习综合实战")

# 定义请求体
class TextInput(BaseModel):
    text: str
    generate_max_length: int = 50  # 文本生成最大长度

# 加载模型和Tokenizer（整合文本分类+文本生成）
# 1. 文本分类模型（情感分析）
classify_model_name = "distilbert-base-uncased"
classify_tokenizer = AutoTokenizer.from_pretrained(classify_model_name)
classify_model = AutoModelForSequenceClassification.from_pretrained(classify_model_name)
classifier = pipeline("sentiment-analysis", model=classify_model, tokenizer=classify_tokenizer)

# 2. 文本生成模型
generate_model_name = "distilgpt2"
generate_tokenizer = AutoTokenizer.from_pretrained(generate_model_name)
generate_model = AutoModelForCausalLM.from_pretrained(generate_model_name)
generator = pipeline("text-generation", model=generate_model, tokenizer=generate_tokenizer)

# 综合接口：同时返回文本分类结果和文本生成结果
@app.post("/text-process")
def text_process(input: TextInput):
    # 文本分类
    classify_result = classifier(input.text)
    # 文本生成（基于输入文本续写）
    generate_result = generator(
        input.text,
        max_length=input.generate_max_length,
        num_return_sequences=1,
        pad_token_id=generate_tokenizer.eos_token_id
    )
    return {
        "status": "success",
        "text": input.text,
        "sentiment_classify": classify_result[0],
        "text_generation": generate_result[0]["generated_text"]
    }

# 复盘辅助：打印19天核心知识点串联
def review_19_days():
    review = """
    19天大模型学习核心复盘：
    1. 阶段一（3天）：数学刚需——矩阵/向量（注意力基础）、梯度下降（训练核心）、Softmax（概率输出）
    2. 阶段二（3天）：深度学习基础——MLP（函数逼近）、训练全链路、CNN（空间特征）
    3. 阶段三（7天）：核心模型——ResNet（残差连接）、RNN（时序短板）、Transformer（自注意力+位置编码+编解码器）
    4. 阶段四（6天）：大模型落地——训练（预训练+微调）、推理优化（量化）、框架实操（Hugging Face）、部署（FastAPI）
    核心收获：大模型不是“黑盒”，掌握底层核心组件，就能实现从开发到部署的端到端落地。
    """
    print(review)

# 启动服务+打印复盘
if __name__ == "__main__":
    # 打印19天复盘
    review_19_days()
    # 启动服务
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

# 测试代码（终端运行服务后，执行以下代码）
# import requests
# url = "http://127.0.0.1:8000/text-process"
# data = {"text": "大模型学习19天，收获满满，终于能独立开发部署小项目了", "generate_max_length": 80}
# response = requests.post(url, json=data)
# print(response.json())
```

Day19核心总结：19天学习闭环完成！核心是掌握“从底层原理到工程落地”的完整链路，重点不在于记住所有代码，而在于理解“为什么这么做”——比如注意力机制的作用、微调的逻辑、部署的流程。复盘时重点梳理自己的薄弱点，为后续深入学习（如大模型微调优化、复杂部署）打下基础。

19天打卡圆满结束！恭喜你完成大模型系统化学习，实现从入门到落地的突破，后续可重点深入某一方向（如微调优化、部署进阶），持续提升实战能力。



> （注：文档部分内容可能由 AI 生成）
