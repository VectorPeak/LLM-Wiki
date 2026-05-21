---
title: "20个python基础问题，你会几个"
source: "https://mp.weixin.qq.com/s/OOVS-4iyuEsnwivJii5D4A"
author:
  - "[[乔木mq]]"
published:
created: 2026-05-19
description: "30个python基础问题，你会几个。11. 为什么在类中定义的普通方法必须包含self参数？Python解释器在调用obj.method()时如何自动传递实例对象？"
tags:
  - "clippings"
---
乔木mq *2026年4月6日 07:19*

1. 11\. 为什么在类中定义的普通方法必须包含 `self` 参数？Python解释器在调用 `obj.method()` 时如何自动传递实例对象？
2. 12\. `copy.copy()` 和 `copy.deepcopy()` 在处理嵌套可变对象（如列表中包含字典）时的行为差异是什么？请举例说明浅拷贝导致的意外副作用。
3. 13\. Python中的 `else` 子句在 `for` / `while` 循环和 `try` 语句中的触发条件有何不同？分别给出典型使用场景。
4. 14\. 为什么 `0.1 + 0.2 == 0.3` 在Python中返回 `False` ？如何使用 `decimal` 或 `fractions` 模块解决浮点数精度问题？
5. 15\. 描述生成器（generator）与普通列表在内存占用和执行时机上的核心区别，并说明 `yield` 关键字如何实现惰性求值。
6. 16\. 在多重继承中，Python如何通过MRO（Method Resolution Order）确定方法调用顺序？用 `C3线性化算法` 解释 `class D(B, C): pass` 的MRO结果。
7. 17\. 为什么 `[] is []` 返回 `False` 而 `"" is ""` 可能返回 `True` ？这与Python的对象缓存机制有何关联？
8. 18\. `@staticmethod` 、 `@classmethod` 和普通实例方法在参数传递、调用方式及使用场景上有何本质区别？
9. 19\. 解释 `with` 语句如何通过上下文管理器协议（ `__enter__` / `__exit__` ）确保资源正确释放，并手写一个文件锁的上下文管理器示例。
10. 20\. 为什么直接修改 `sys.path` 可以影响模块导入？这与 `PYTHONPATH` 环境变量的作用有何异同？
11. 21\. `dict.get(key)` 和 `dict[key]` 在访问不存在的键时行为有何不同？如何利用 `get` 的默认值参数避免 `KeyError` ？
12. 22\. 在正则表达式中， `re.match()` 和 `re.search()` 的匹配范围有何区别？何时必须使用 `re.fullmatch()` ？
13. 23\. 为什么 `a = 256; b = 256; a is b` 返回 `True` ，但 `a = 257; b = 257; a is b` 在交互式环境中可能返回 `False` ？
14. 24\. 描述 `f-string` 、 `str.format()` 和 `%` 格式化在性能、可读性和功能上的主要差异，并说明f-string为何成为现代Python首选。
15. 25\. 为什么在函数内部直接赋值全局变量会引发 `UnboundLocalError` ？如何通过 `global` 或 `nonlocal` 关键字正确修改作用域外的变量？
16. 26\. `os.path.join()` 和 `pathlib.Path` 在构建跨平台文件路径时的优劣对比？后者如何通过运算符重载简化路径操作？
17. 27\. 为什么 `json.loads('{"key": "value"}')` 返回字典，但 `json.load(file)` 需要文件对象？两者在数据源处理上有何设计哲学差异？
18. 28\. 在多线程环境中，对列表进行 `append` 操作是否线程安全？为什么CPython的GIL不能保证所有操作的原子性？
19. 29\. 为什么 `True + True` 等于 `2` ？这与Python中布尔类型作为 `int` 子类的设计有何关联？
20. 30\. 解释 `__name__ == "__main__"` 的作用，并说明当模块被直接执行与被导入时该表达式的不同取值如何控制代码执行流程。

算法工程师 · 目录

继续滑动看下一个

乔木mq

向上滑动看下一个