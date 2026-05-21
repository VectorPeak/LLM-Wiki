---
title: "算法专栏：10个pytorch常用法，不会就不要学AI了"
source: "https://mp.weixin.qq.com/s/-HqtP4ZGF5XJOAfT-eInlA"
author:
  - "[[乔木mq]]"
published:
created: 2026-05-19
description:
tags:
  - "clippings"
---
乔木mq *2026年4月9日 07:12*

1. 1\. 创建一个形状为 (2, 3) 的全1张量
	```
	import torch
	x = torch.ones(2, 3)
	```
2. 2\. 创建一个随机初始化的张量（服从标准正态分布）
	```
	x = torch.randn(2, 3)
	```
3. 3\. 将张量转换为 NumPy 数组
	```
	numpy_array = x.numpy()  # 要求 x 在 CPU 上
	```
4. 4\. 获取张量的数据类型
	```
	dtype = x.dtype
	```
5. 5\. 对张量进行就地（in-place）加法操作
	```
	x.add_(1)  # 所有元素加1，直接修改x
	```
6. 6\. 拼接两个张量（沿第0维）
	```
	a = torch.tensor([1, 2])
	b = torch.tensor([3, 4])
	c = torch.cat([a, b], dim=0)  # 结果: [1, 2, 3, 4]
	```
7. 7\. 计算张量的均值
	```
	mean_val = x.mean()
	```
8. 8\. 改变张量的形状（reshape）
	```
	x_reshaped = x.view(3, 2)  # 原x为(2,3)，总元素数需一致
	```
9. 9\. 判断是否启用梯度追踪
	```
	requires_grad = x.requires_grad
	```
10. 10\. 临时禁用梯度计算（常用于推理）
	```
	with torch.no_grad():
	y = x * 2  # 此操作不会记录梯度
	```

算法工程师 · 目录

继续滑动看下一个

乔木mq

向上滑动看下一个